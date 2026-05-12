//
//  syncFlight_reBuiltApp.swift
//  syncFlight_reBuilt
//
//  Created by Merak Weng on 12/5/2026.
//

import SwiftUI
import AppIntents

@main
struct SyncFlightApp: App {
    var body: some Scene {
        // 主窗口
        WindowGroup("SyncFlight", id: "main") {
            ContentView()
                .frame(minWidth: 600, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizabilityContentSize()
        
        // 菜单栏命令
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 SyncFlight") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "一个智能航班日历转换应用",
                                attributes: [
                                    .font: NSFont.systemFont(ofSize: 11)
                                ]
                            )
                        ]
                    )
                }
            }
            
            CommandGroup(replacing: .help) {
                Button("SyncFlight 帮助") {
                    if let helpURL = URL(string: "https://github.com/merak-weng/syncflight") {
                        NSWorkspace.shared.open(helpURL)
                    }
                }
                
                Divider()
                
                Button("系统偏好设置 - 日历") {
                    PlatformBridge.openPrivacySettings()
                }
                
                Button("发送反馈") {
                    PlatformBridge.sendFeedbackEmail()
                }
            }
        }
        
        // Settings 窗口
        Settings {
            PreferencesView(manager: CalendarManager.shared)
        }
    }
}

// MARK: - Window Resizability Extension
extension Scene {
    func windowResizabilityContentSize() -> some Scene {
        #if os(macOS)
        return self
        #else
        return self
        #endif
    }
}
