import SwiftUI

struct PreferencesView: View {
    @ObservedObject var manager: CalendarManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section {
                Text("偏好设置")
                    .font(.system(.title, design: .default))
                    .bold()
            }

            Section("处理模式") {
                Picker("模式选择", selection: $manager.useSeparateCalendars) {
                    Text("单日历模式（读写同一个日历）").tag(false)
                    Text("分离模式（读写不同日历）").tag(true)
                }
                .pickerStyle(.segmented)

                if manager.useSeparateCalendars {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("分离模式会保持源日历不变，并将格式化结果写入目标日历。")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }

            Section(manager.useSeparateCalendars ? "日历选择（分离模式）" : "日历选择（单日历模式）") {
                if manager.useSeparateCalendars {
                    Picker("源日历（读取）", selection: $manager.sourceCalendarIdentifier) {
                        Text("-- 请选择 --").tag(nil as String?)

                        ForEach(manager.availableCalendars, id: \.id) { calendar in
                            Text(calendar.title)
                                .tag(calendar.id as String?)
                        }
                    }

                    Picker("目标日历（写入）", selection: $manager.targetCalendarIdentifier) {
                        Text("-- 请选择 --").tag(nil as String?)

                        ForEach(manager.availableCalendars, id: \.id) { calendar in
                            Text(calendar.title)
                                .tag(calendar.id as String?)
                        }
                    }

                    if manager.sourceCalendarIdentifier == manager.targetCalendarIdentifier,
                       manager.sourceCalendarIdentifier != nil {
                        Text("源日历和目标日历不能相同")
                            .foregroundColor(.orange)
                    }

                    Toggle("复制告警到新事件", isOn: $manager.copyAlarmsToNewEvents)
                } else {
                    Picker("日历", selection: $manager.selectedCalendarIdentifier) {
                        Text("-- 请选择 --").tag(nil as String?)

                        ForEach(manager.availableCalendars, id: \.id) { calendar in
                            Text(calendar.title)
                                .tag(calendar.id as String?)
                        }
                    }

                    Text("选择的日历将用于读取和修改航班事件")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.secondary)
                }
            }

            Section("权限设置") {
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

                    Button("打开设置") {
                        PlatformBridge.openPrivacySettings()
                    }
                    .help("打开系统隐私设置")
                }
            }

            Section("关于应用") {
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

            Section {
                HStack(spacing: 12) {
                    Button("发送反馈") {
                        PlatformBridge.sendFeedbackEmail()
                    }
                    .buttonStyle(.bordered)
                    .help("通过邮件发送反馈")

                    Button("关闭") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(minWidth: 720, minHeight: 760)
    }
}

#Preview {
    PreferencesView(manager: CalendarManager.shared)
}
