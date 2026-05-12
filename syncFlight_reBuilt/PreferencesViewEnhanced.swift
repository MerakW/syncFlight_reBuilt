import SwiftUI

struct PreferencesViewEnhanced: View {
    @ObservedObject var manager: CalendarManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("偏好设置")
                .font(.system(.title, design: .default))
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 处理模式选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📋 处理模式")
                            .font(.system(.headline, design: .default))
                            .foregroundColor(.primary)
                        
                        Picker("模式选择", selection: $manager.useSeparateCalendars) {
                            Text("单日历模式（读写同一个日历）").tag(false)
                            Text("分离模式（读写不同日历）").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: .infinity)
                        
                        if manager.useSeparateCalendars {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("分离模式优势", systemImage: "checkmark.circle")
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("✓ 原始事件保持不变")
                                        .font(.system(.caption2, design: .default))
                                    Text("✓ 易于回滚和撤销")
                                        .font(.system(.caption2, design: .default))
                                    Text("✓ 支持多源汇聚")
                                        .font(.system(.caption2, design: .default))
                                }
                                .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 日历选择部分
                    if manager.useSeparateCalendars {
                        // 分离模式下的日历选择
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📅 日历选择（分离模式）")
                                .font(.system(.headline, design: .default))
                                .foregroundColor(.primary)
                            
                            // 源日历选择
                            VStack(alignment: .leading, spacing: 8) {
                                Label("源日历（读取航班事件）", systemImage: "book.fill")
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
                                .frame(maxWidth: .infinity)
                                
                                if let sourceId = manager.sourceCalendarIdentifier,
                                   let calendar = manager.availableCalendars.first(where: { $0.id == sourceId }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(.caption2, design: .default))
                                            .foregroundColor(.green)
                                        
                                        Text("已选择: \(calendar.title)")
                                            .font(.system(.caption, design: .default))
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(6)
                            
                            // 目标日历选择
                            VStack(alignment: .leading, spacing: 8) {
                                Label("目标日历（写入格式化事件）", systemImage: "book.badge.checkmark")
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
                                .frame(maxWidth: .infinity)
                                
                                if let targetId = manager.targetCalendarIdentifier,
                                   let calendar = manager.availableCalendars.first(where: { $0.id == targetId }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(.caption2, design: .default))
                                            .foregroundColor(.green)
                                        
                                        Text("已选择: \(calendar.title)")
                                            .font(.system(.caption, design: .default))
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(6)
                            
                            // 警告：源和目标不能相同
                            if manager.sourceCalendarIdentifier == manager.targetCalendarIdentifier && 
                               manager.sourceCalendarIdentifier != nil {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(.caption, design: .default))
                                        .foregroundColor(.orange)
                                    
                                    Text("源日历和目标日历不能相同")
                                        .font(.system(.caption, design: .default))
                                        .foregroundColor(.orange)
                                }
                                .padding(10)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(6)
                            }
                            
                            // 分离模式选项
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $manager.copyAlarmsToNewEvents) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "bell.badge.fill")
                                            .font(.system(.caption, design: .default))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("复制告警到新事件")
                                                .font(.system(.caption, design: .default))
                                            
                                            Text("将原始事件的提醒复制到格式化后的新事件")
                                                .font(.system(.caption2, design: .default))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .toggleStyle(.checkbox)
                            }
                            .padding(10)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                        }
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    } else {
                        // 单日历模式下的日历选择
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📅 日历选择（单日历模式）")
                                .font(.system(.headline, design: .default))
                                .foregroundColor(.primary)
                            
                            Picker("日历", selection: $manager.selectedCalendarIdentifier) {
                                Text("-- 请选择 --").tag(nil as String?)
                                
                                ForEach(manager.availableCalendars, id: \.id) { calendar in
                                    Text(calendar.title)
                                        .tag(calendar.id as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            
                            Text("选择的日历将用于读取和修改航班事件")
                                .font(.system(.caption, design: .default))
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    // 权限部分
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔐 权限设置")
                            .font(.system(.headline, design: .default))
                            .foregroundColor(.primary)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle()
                                        .fill(manager.hasCalendarAccess ? Color.green : Color.red)
                                        .frame(width: 8, height: 8)
                                    
                                    Text("日历访问权限")
                                        .font(.system(.body, design: .default))
                                }
                                
                                Text(manager.hasCalendarAccess ? "已授予" : "未授予")
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                PlatformBridge.openPrivacySettings()
                            }) {
                                Text("打开设置")
                                    .font(.system(.caption, design: .default))
                            }
                            .buttonStyle(.bordered)
                            .help("打开系统隐私设置")
                        }
                    }
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 信息部分
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ℹ️ 关于应用")
                            .font(.system(.headline, design: .default))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("版本:")
                                    .frame(minWidth: 80, alignment: .leading)
                                    .foregroundColor(.secondary)
                                
                                Text(PlatformBridge.getAppVersion())
                                    .font(.system(.body, design: .monospaced))
                            }
                            
                            HStack {
                                Text("Bundle ID:")
                                    .frame(minWidth: 80, alignment: .leading)
                                    .foregroundColor(.secondary)
                                
                                Text(PlatformBridge.getBundleIdentifier())
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            HStack {
                                Text("模式:")
                                    .frame(minWidth: 80, alignment: .leading)
                                    .foregroundColor(.secondary)
                                
                                Text(manager.useSeparateCalendars ? "分离模式" : "单日历模式")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding(12)
            }
            
            Divider()
            
            // 底部按钮
            HStack(spacing: 12) {
                Button(action: {
                    PlatformBridge.sendFeedbackEmail()
                }) {
                    Label("发送反馈", systemImage: "envelope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .help("通过邮件发送反馈")
                
                Button(action: {
                    dismiss()
                }) {
                    Text("关闭")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(minWidth: 450, minHeight: 600)
    }
}

#Preview {
    PreferencesViewEnhanced(manager: CalendarManager.shared)
}
