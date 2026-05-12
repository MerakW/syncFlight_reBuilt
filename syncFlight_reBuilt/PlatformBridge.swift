import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// 平台相关工具
struct PlatformBridge {
    #if os(macOS)
    static let isMacOS = true
    static let isIOS = false
    #else
    static let isMacOS = false
    static let isIOS = true
    #endif
    
    /// 打开系统设置中的隐私设置
    static func openPrivacySettings() {
        #if os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
        #else
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
    
    /// 发送邮件反馈
    static func sendFeedbackEmail() {
        let recipient = "merak.weng@example.com"
        let subject = "SyncFlight 反馈"
        let body = "请在此处输入您的反馈...\n\n--\nSyncFlight macOS\n"
        
        #if os(macOS)
        let mailURL = "mailto:\(recipient)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: mailURL) {
            NSWorkspace.shared.open(url)
        }
        #else
        if let mailURL = URL(string: mailURL),
           UIApplication.shared.canOpenURL(mailURL) {
            UIApplication.shared.open(mailURL)
        }
        #endif
    }
    
    /// 获取应用版本信息
    static func getAppVersion() -> String {
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "v\(version) (Build \(build))"
    }
    
    /// 获取应用 Bundle ID
    static func getBundleIdentifier() -> String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }
}
