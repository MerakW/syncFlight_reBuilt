import Foundation
import EventKit
import Combine

/// 可选日历选项
struct CalendarOption: Identifiable {
    let id: String
    let title: String
}

/// 日历管理器 - 负责所有日历相关操作
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
    @Published var selectedCalendarIdentifier: String? {
        didSet {
            UserDefaults.standard.set(selectedCalendarIdentifier, forKey: "selectedCalendarIdentifier")
        }
    }
    @Published var hasCalendarAccess: Bool = false
    
    override init() {
        super.init()
        selectedCalendarIdentifier = UserDefaults.standard.string(forKey: "selectedCalendarIdentifier")
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
                let granted = try await eventStore.requestAccess(to: .event)
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
        
        // 如果之前选择的日历不存在，清除选择
        if let selected = selectedCalendarIdentifier,
           !calendars.contains(where: { $0.calendarIdentifier == selected }) {
            selectedCalendarIdentifier = nil
        }
        
        appendLog("🔄 刷新日历列表: 找到 \(calendars.count) 个可写日历")
    }
    
    // MARK: - 事件处理
    
    /// 格式化即将到来的航班事件
    func formatUpcomingFlightEvents() -> (formatted: Int, total: Int) {
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
        appendLog("📅 开始扫描日历...")
        
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
