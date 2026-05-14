//
//  ContentView.swift
//  syncFlight_reBuilt
//
//  Created by Merak Weng on 12/5/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = CalendarManager.shared
    @State private var showPreferences = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark
                        ? Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0))
                        : Color(nsColor: NSColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)),
                    colorScheme == .dark
                        ? Color(nsColor: NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0))
                        : Color(nsColor: NSColor(red: 0.93, green: 0.93, blue: 0.94, alpha: 1.0))
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 标题区
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "airplane")
                                    .font(.system(.title, design: .default))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("SyncFlight")
                                        .font(.system(.title2, design: .rounded))
                                        .bold()
                                    
                                    Text("航班日历事件转换工具")
                                        .font(.system(.caption, design: .default))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            Text("自动扫描并转换 航旅纵横 的航班事件为 Flighty 兼容格式")
                                .font(.system(.caption, design: .default))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                        
                        // 权限请求部分
                        if !manager.hasCalendarAccess {
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(.title3, design: .default))
                                        .foregroundColor(.orange)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("需要日历权限")
                                            .font(.system(.headline, design: .default))
                                        
                                        Text("请授予日历访问权限以正常使用本应用")
                                            .font(.system(.caption, design: .default))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                
                                Button(action: {
                                    Task {
                                        _ = await manager.ensureCalendarAccess()
                                    }
                                }) {
                                    Text("授予权限")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(16)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // 日历选择部分
                        if manager.hasCalendarAccess {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(manager.useSeparateCalendars ? "📅 日历选择（分离模式）" : "📅 选择目标日历")
                                    .font(.system(.headline, design: .default))
                                
                                if manager.useSeparateCalendars {
                                    VStack(alignment: .leading, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("源日历（读取）")
                                                .font(.system(.caption, design: .default))
                                                .foregroundColor(.blue)
                                            
                                            Picker("源日历", selection: $manager.sourceCalendarIdentifier) {
                                                Text("-- 请选择 --").tag(nil as String?)
                                                
                                                ForEach(manager.availableCalendars, id: \.id) { calendar in
                                                    Text(calendar.title)
                                                        .tag(calendar.id as String?)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("目标日历（写入）")
                                                .font(.system(.caption, design: .default))
                                                .foregroundColor(.green)
                                            
                                            Picker("目标日历", selection: $manager.targetCalendarIdentifier) {
                                                Text("-- 请选择 --").tag(nil as String?)
                                                
                                                ForEach(manager.availableCalendars, id: \.id) { calendar in
                                                    Text(calendar.title)
                                                        .tag(calendar.id as String?)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                        }
                                        
                                        if manager.sourceCalendarIdentifier == manager.targetCalendarIdentifier && manager.sourceCalendarIdentifier != nil {
                                            Text("源日历和目标日历不能相同")
                                                .font(.system(.caption, design: .default))
                                                .foregroundColor(.orange)
                                        }
                                    }
                                } else {
                                    Picker("日历", selection: $manager.selectedCalendarIdentifier) {
                                        Text("-- 请选择 --").tag(nil as String?)
                                        
                                        ForEach(manager.availableCalendars, id: \.id) { calendar in
                                            Text(calendar.title)
                                                .tag(calendar.id as String?)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(16)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(12)
                            
                            // 操作按钮
                            Button(action: {
                                let _ = manager.formatUpcomingFlightEvents()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "wand.and.stars")
                                    Text("转换航班事件")
                                }
                                .frame(maxWidth: .infinity)
                                .font(.system(.body, design: .default))
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!manager.canFormatUpcomingFlightEvents)
                            .help(manager.useSeparateCalendars ? "扫描源日历并写入目标日历中的航班事件" : "扫描并转换选定日历中的航班事件")
                            
                            // 日志面板
                            LogsPanelView(manager: manager)
                            
                            // 状态显示
                            if !manager.statusMessage.isEmpty || manager.updatedEventCount > 0 {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: manager.updatedEventCount > 0 ? "checkmark.circle.fill" : "info.circle.fill")
                                            .foregroundColor(manager.updatedEventCount > 0 ? .green : .blue)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(manager.statusMessage)
                                                .font(.system(.body, design: .default))
                                            
                                            if manager.updatedEventCount > 0 {
                                                Text("已格式化 \(manager.updatedEventCount) 个事件，共扫描 \(manager.lastScannedEventCount) 个航班事件")
                                                    .font(.system(.caption, design: .default))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .padding(16)
                                .background(manager.updatedEventCount > 0 ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(manager.updatedEventCount > 0 ? Color.green.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(24)
                }
                
                // 底部信息栏
                Divider()
                
                HStack(spacing: 16) {
                    Text("v\(PlatformBridge.getAppVersion()) • macOS")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { showPreferences = true }) {
                        Label("偏好设置", systemImage: "gearshape")
                            .font(.system(.caption, design: .default))
                    }
                    .buttonStyle(.bordered)
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            }
        }
        .sheet(isPresented: $showPreferences) {
            PreferencesView(manager: manager)
        }
        .onAppear {
            manager.checkCalendarAccess()
        }
    }
}

#Preview {
    ContentView()
        .frame(minWidth: 600, minHeight: 800)
}
