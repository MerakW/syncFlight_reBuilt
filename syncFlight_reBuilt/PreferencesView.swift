import SwiftUI

struct PreferencesView: View {
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
            
            // 日历选择部分
            VStack(alignment: .leading, spacing: 12) {
                Text("日历设置")
                    .font(.system(.headline, design: .default))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Text("目标日历:")
                        .frame(minWidth: 80, alignment: .leading)
                    
                    Picker("日历", selection: $manager.selectedCalendarIdentifier) {
                        Text("-- 未选择 --").tag(nil as String?)
                        
                        ForEach(manager.availableCalendars, id: \.id) { calendar in
                            Text(calendar.title)
                                .tag(calendar.id as String?)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            
            // 权限部分
            VStack(alignment: .leading, spacing: 12) {
                Text("权限设置")
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
                Text("关于应用")
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
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
            
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
        .frame(minWidth: 400, minHeight: 500)
    }
}

#Preview {
    PreferencesView(manager: CalendarManager.shared)
}
