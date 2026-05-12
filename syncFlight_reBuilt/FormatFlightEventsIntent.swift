import AppIntents
import Foundation

@available(macOS 13.0, *)
struct FormatFlightEventsIntent: AppIntent {
    static let title: LocalizedStringResource = "Format Flight Events"
    static let description: LocalizedStringResource = "Format upcoming flight events from 航旅纵横 for Flighty compatibility"
    static let openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let manager = CalendarManager.shared
        
        // 检查权限
        let hasAccess = await manager.ensureCalendarAccess()
        guard hasAccess else {
            let result = "日历权限被拒绝，请在系统偏好设置中启用"
            return .result(value: result)
        }
        
        // 检查日历选择
        guard manager.selectedCalendarIdentifier != nil else {
            let result = "未选择日历，请先在应用中选择目标日历"
            return .result(value: result)
        }
        
        // 格式化事件
        let (statusMessage, updatedEventCount) = manager.formatUpcomingFlightEventsForIntent()
        
        let result = "✅ \(statusMessage)\n已格式化 \(updatedEventCount) 个事件"
        return .result(value: result)
    }
}

@available(macOS 13.0, *)
struct SyncFlightAppShortcutsProvider: AppShortcutsProvider {
    static let appShortcuts: [AppShortcut] = [
        AppShortcut(
            intent: FormatFlightEventsIntent(),
            phrases: [
                "Format flight events in \(.applicationName)",
                "Update flight calendar events using \(.applicationName)"
            ]
        )
    ]
}
