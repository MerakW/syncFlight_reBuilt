import Foundation
import EventKit
import Combine

/// 可选日历选项
struct CalendarOption: Identifiable {
    let id: String
    let title: String
}

/// 日历管理器 - 负责所有日历相关操作（支持读写分离）
@MainActor
class CalendarManager: NSObject, ObservableObject {
    static let shared = CalendarManager()
    
    private let eventStore = EKEventStore()
    private let logCapacity = 100
    
    @Published var statusMessage: String = "就绪"
    @Published var updatedEventCount: Int = 0
    @Published var lastScannedEventCount: Int = 0
    @Published var availableCalendars: [CalendarOption] = []
    @Published var processingLogs: [String] = []
    
    // MARK: - 读写分离模式相关属性
    
    /// 是否启用分离模式（读和写使用不同日历）
    @Published var useSeparateCalendars: Bool = false {
        didSet {
            UserDefaults.standard.set(useSeparateCalendars, forKey: "useSeparateCalendars")
        }
    }
    
    /// 源日历标识符（读取航班事件）
    @Published var sourceCalendarIdentifier: String? {
        didSet {
            UserDefaults.standard.set(sourceCalendarIdentifier, forKey: "sourceCalendarIdentifier")
        }
    }
    
    /// 目标日历标识符（写入格式化后的事件）
    @Published var targetCalendarIdentifier: String? {
        didSet {
            UserDefaults.standard.set(targetCalendarIdentifier, forKey: "targetCalendarIdentifier")
        }
    }
    
    /// 是否复制告警到新事件（仅在分离模式下）
    @Published var copyAlarmsToNewEvents: Bool = true {
        didSet {
            UserDefaults.standard.set(copyAlarmsToNewEvents, forKey: "copyAlarmsToNewEvents")
        }
    }
    
    // MARK: - 单日历模式相关属性（向后兼容）
    
    /// 统一日历选择（仅在非分离模式下使用）
    @Published var selectedCalendarIdentifier: String? {
        didSet {
            UserDefaults.standard.set(selectedCalendarIdentifier, forKey: "selectedCalendarIdentifier")
        }
    }
    
    @Published var hasCalendarAccess: Bool = false

    /// 当前模式下用于读取/写入的目标日历
    var activeCalendarIdentifier: String? {
        useSeparateCalendars ? targetCalendarIdentifier : selectedCalendarIdentifier
    }

    /// 当前配置是否足以开始同步
    var canFormatUpcomingFlightEvents: Bool {
        if useSeparateCalendars {
            guard let source = sourceCalendarIdentifier,
                  let target = targetCalendarIdentifier else { return false }
            return source != target
        }

        return selectedCalendarIdentifier != nil
    }
    
    override init() {
        super.init()
        // 恢复用户偏好
        selectedCalendarIdentifier = UserDefaults.standard.string(forKey: "selectedCalendarIdentifier")
        useSeparateCalendars = UserDefaults.standard.bool(forKey: "useSeparateCalendars")
        sourceCalendarIdentifier = UserDefaults.standard.string(forKey: "sourceCalendarIdentifier")
        targetCalendarIdentifier = UserDefaults.standard.string(forKey: "targetCalendarIdentifier")
        copyAlarmsToNewEvents = UserDefaults.standard.object(forKey: "copyAlarmsToNewEvents") as? Bool ?? true
        checkCalendarAccess()
    }
    
    // MARK: - 权限管理
    
    /// 检查日历访问权限
    func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        hasCalendarAccess = (status == .authorized || status == .fullAccess)
        
        if hasCalendarAccess {
            refreshAvailableCalendars()
        }
    }
    
    /// 请求日历访问权限
    func ensureCalendarAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized, .fullAccess:
            hasCalendarAccess = true
            refreshAvailableCalendars()
            return true
        case .denied, .restricted:
            statusMessage = "日历权限被拒绝，请在系统偏好设置中启用"
            appendLog("❌ 日历权限被拒绝")
            return false
        case .notDetermined:
            do {
                let granted: Bool
                if #available(macOS 14.0, *) {
                    granted = try await eventStore.requestFullAccessToEvents()
                } else {
                    granted = try await eventStore.requestAccess(to: .event)
                }
                hasCalendarAccess = granted
                if granted {
                    refreshAvailableCalendars()
                    statusMessage = "权限已授予"
                    appendLog("✅ 日历权限已授予")
                } else {
                    statusMessage = "用户拒绝了日历权限"
                    appendLog("❌ 用户拒绝了日历权限")
                }
                return granted
            } catch {
                statusMessage = "请求权限时出错: \(error.localizedDescription)"
                appendLog("❌ 权限请求错误: \(error.localizedDescription)")
                return false
            }
        @unknown default:
            return false
        }
    }
    
    // MARK: - 日历管理
    
    /// 刷新可用日历列表
    func refreshAvailableCalendars() {
        let calendars = eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .sorted { $0.title < $1.title }
        
        availableCalendars = calendars.map { calendar in
            CalendarOption(id: calendar.calendarIdentifier, title: calendar.title)
        }
        
        // 检查之前的选择是否仍然有效
        if let selected = selectedCalendarIdentifier,
           !calendars.contains(where: { $0.calendarIdentifier == selected }) {
            selectedCalendarIdentifier = nil
        }
        
        if let source = sourceCalendarIdentifier,
           !calendars.contains(where: { $0.calendarIdentifier == source }) {
            sourceCalendarIdentifier = nil
        }
        
        if let target = targetCalendarIdentifier,
           !calendars.contains(where: { $0.calendarIdentifier == target }) {
            targetCalendarIdentifier = nil
        }
        
        appendLog("🔄 刷新日历列表: 找到 \(calendars.count) 个可写日历")
    }
    
    // MARK: - 事件处理
    
    /// 格式化即将到来的航班事件（主入口）
    func formatUpcomingFlightEvents() -> (formatted: Int, total: Int) {
        if useSeparateCalendars {
            return formatFlightEventsWithSeparateCalendars()
        } else {
            return formatFlightEventsWithSingleCalendar()
        }
    }
    
    /// 单日历模式：读和写同一个日历
    private func formatFlightEventsWithSingleCalendar() -> (formatted: Int, total: Int) {
        guard let calendarId = selectedCalendarIdentifier else {
            statusMessage = "请先选择日历"
            appendLog("⚠️ 未选择日历")
            return (0, 0)
        }
        
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            statusMessage = "找不到选定的日历"
            appendLog("❌ 找不到选定的日历")
            return (0, 0)
        }
        
        statusMessage = "正在扫描日历..."
        appendLog("📅 开始扫描日历（单日历模式）...")
        
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: today) ?? today
        let predicate = eventStore.predicateForEvents(withStart: today, end: endDate, calendars: [calendar])
        
        let events = eventStore.events(matching: predicate)
        let flightEvents = events.filter { $0.title.contains("航旅纵横") }
        
        appendLog("📊 扫描结果: 总事件 \(events.count)，航班事件 \(flightEvents.count)")
        
        var formattedCount = 0
        
        for event in flightEvents {
            // 跳过已经格式化的事件
            if event.title.contains("[FLIGHT]") {
                appendLog("⏭️ 跳过已格式化事件: \(event.title)")
                continue
            }
            
            if let flightDetails = FlightParser.parseFlightEvent(event.title) {
                let newTitle = FlightParser.formatFlightTitle(from: flightDetails)
                event.title = newTitle
                
                do {
                    try eventStore.save(event, span: .thisEvent)
                    formattedCount += 1
                    appendLog("✅ 已格式化: \(newTitle)")
                } catch {
                    appendLog("❌ 保存失败: \(error.localizedDescription)")
                }
            } else {
                appendLog("⚠️ 解析失败: \(event.title)")
            }
        }
        
        updatedEventCount = formattedCount
        lastScannedEventCount = flightEvents.count
        
        let message = "已格式化 \(formattedCount) 个航班事件"
        statusMessage = message
        appendLog("🎉 \(message)")
        
        return (formattedCount, flightEvents.count)
    }
    
    /// 分离日历模式：从源日历读取，写入到目标日历
    private func formatFlightEventsWithSeparateCalendars() -> (formatted: Int, total: Int) {
        guard let sourceId = sourceCalendarIdentifier else {
            statusMessage = "请先选择源日历（读取）"
            appendLog("⚠️ 未选择源日历")
            return (0, 0)
        }
        
        guard let targetId = targetCalendarIdentifier else {
            statusMessage = "请先选择目标日历（写入）"
            appendLog("⚠️ 未选择目标日历")
            return (0, 0)
        }
        
        guard sourceId != targetId else {
            statusMessage = "源日历和目标日历不能相同，请使用单日历模式"
            appendLog("⚠️ 源日历和目标日历相同")
            return (0, 0)
        }
        
        guard let sourceCalendar = eventStore.calendar(withIdentifier: sourceId) else {
            statusMessage = "找不到源日历"
            appendLog("❌ 找不到源日历")
            return (0, 0)
        }
        
        guard let targetCalendar = eventStore.calendar(withIdentifier: targetId) else {
            statusMessage = "找不到目标日历"
            appendLog("❌ 找不到目标日历")
            return (0, 0)
        }
        
        statusMessage = "正在处理..."
        appendLog("📅 从 '\(sourceCalendar.title)' 读取，写入到 '\(targetCalendar.title)'...")
        
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: today) ?? today
        let predicate = eventStore.predicateForEvents(withStart: today, end: endDate, calendars: [sourceCalendar])
        
        let events = eventStore.events(matching: predicate)
        let flightEvents = events.filter { $0.title.contains("航旅纵横") }
        
        appendLog("📊 源日历扫描结果: 总事件 \(events.count)，航班事件 \(flightEvents.count)")
        
        var formattedCount = 0
        var skippedCount = 0
        
        for sourceEvent in flightEvents {
            if let flightDetails = FlightParser.parseFlightEvent(sourceEvent.title) {
                let newTitle = FlightParser.formatFlightTitle(from: flightDetails)
                
                // 检查是否已经在目标日历中存在相同的事件
                if doesEventExistInTargetCalendar(withTitle: newTitle, calendar: targetCalendar) {
                    skippedCount += 1
                    appendLog("⏭️ 跳过重复事件: \(newTitle)")
                    continue
                }
                
                // 创建新事件到目标日历（必须使用 eventStore 初始化）
                let newEvent = EKEvent(eventStore: eventStore)
                newEvent.title = newTitle
                newEvent.startDate = sourceEvent.startDate
                newEvent.endDate = sourceEvent.endDate
                newEvent.calendar = targetCalendar
                
                // 添加备注（保留原始信息）
                let notes = "📌 原始标题: \(sourceEvent.title)\n📅 来源日历: \(sourceCalendar.title)"
                newEvent.notes = notes
                
                // 复制告警（如果启用）
                if copyAlarmsToNewEvents, let alarms = sourceEvent.alarms, !alarms.isEmpty {
                    var sanitizedAlarms: [EKAlarm] = []
                    for alarm in alarms {
                        if let abs = alarm.absoluteDate {
                            sanitizedAlarms.append(EKAlarm(absoluteDate: abs))
                        } else {
                            // 使用相对偏移创建告警，避免携带不可用的 URL 或其他受限字段
                            sanitizedAlarms.append(EKAlarm(relativeOffset: alarm.relativeOffset))
                        }
                    }
                    newEvent.alarms = sanitizedAlarms
                    appendLog("🔔 已复制并清洗 \(sanitizedAlarms.count) 个告警（已移除受限字段）")
                }
                
                do {
                    try eventStore.save(newEvent, span: .thisEvent)
                    formattedCount += 1
                    appendLog("✅ 已创建新事件: \(newTitle)")
                } catch {
                    appendLog("❌ 创建事件失败: \(error.localizedDescription)")
                }
            } else {
                appendLog("⚠️ 解析失败: \(sourceEvent.title)")
            }
        }
        
        updatedEventCount = formattedCount
        lastScannedEventCount = flightEvents.count
        
        let message = "已创建 \(formattedCount) 个新事件到目标日历"
        + (skippedCount > 0 ? "（跳过 \(skippedCount) 个重复）" : "")
        statusMessage = message
        appendLog("🎉 \(message)")
        
        return (formattedCount, flightEvents.count)
    }
    
    /// 检查目标日历中是否已存在相同标题的事件
    private func doesEventExistInTargetCalendar(withTitle title: String, calendar: EKCalendar) -> Bool {
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: today) ?? today
        let predicate = eventStore.predicateForEvents(withStart: today, end: endDate, calendars: [calendar])
        
        let events = eventStore.events(matching: predicate)
        return events.contains { $0.title == title }
    }
    
    // MARK: - 快捷指令支持
    
    /// 用于快捷指令的格式化方法
    func formatUpcomingFlightEventsForIntent() -> (statusMessage: String, updatedEventCount: Int) {
        let (formatted, _) = formatUpcomingFlightEvents()
        return (statusMessage, formatted)
    }
    
    // MARK: - 日志管理
    
    /// 添加日志条目
    func appendLog(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        let logEntry = "\(timestamp) - \(message)"
        
        processingLogs.insert(logEntry, at: 0)
        if processingLogs.count > logCapacity {
            processingLogs.removeLast()
        }
    }
    
    /// 清空日志
    func clearLogs() {
        processingLogs.removeAll()
        appendLog("📋 日志已清空")
    }
}
