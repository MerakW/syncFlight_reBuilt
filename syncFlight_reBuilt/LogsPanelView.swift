import SwiftUI

struct LogsPanelView: View {
    @ObservedObject var manager: CalendarManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("📋 处理日志")
                    .font(.system(.headline, design: .default))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    manager.clearLogs()
                }) {
                    Label("清空", systemImage: "trash")
                        .font(.system(.caption, design: .default))
                }
                .buttonStyle(.bordered)
                .help("清空所有日志条目")
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if manager.processingLogs.isEmpty {
                        Text("暂无日志")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical, 40)
                    } else {
                        ForEach(manager.processingLogs.indices, id: \.self) { index in
                            Text(manager.processingLogs[index])
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .frame(height: 220)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
        }
    }
}

#Preview {
    LogsPanelView(manager: CalendarManager.shared)
        .padding()
}
