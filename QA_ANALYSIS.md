# Q&A 分析与解决方案

## Q1: 航班号格式支持

### 当前支持情况 ✅
**已完全支持** MU5147、9C1234 等所有格式！

#### 技术原理
当前正则表达式中的航班号匹配模式：
```
[A-Z0-9]+
```

这个模式支持：
- ✅ 两字母 + 数字：CA123、MU1234、CA5678
- ✅ 两字母 + 多位数字：MU5147（4位）、CA12345（5位）
- ✅ 数字 + 字母 + 数字：9C1234、3U8765
- ✅ 纯字母：BA、CZ、FM
- ✅ 纯数字：123、5678（极少见，但支持）
- ✅ 任意长度的字母数字组合

### 实际测试示例
```
✅ 乘坐CA123 北京-上海 T1 当地时间10:30-13:45 【航旅纵横】
✅ 乘坐MU5147 北京-上海 T1 当地时间10:30-13:45 【航旅纵横】
✅ 乘坐9C1234 北京-上海 T1 当地时间10:30-13:45 【航旅纵横】
✅ 乘坐3U8765 北京-成都 T2 当地时间14:00-16:30 【航旅纵横】
✅ 乘坐FM9001 上海-广州 T3 当地时间11:00-14:15 【航旅纵横】
```

### 可能的增强方向
如果需要进一步优化，可以：

1. **添加航班号验证**：检查航班号长度（通常 2-6 位）
```swift
// 在 FlightParser 中添加验证
let flightNumber = flight
if flightNumber.count < 2 || flightNumber.count > 6 {
    appendLog("⚠️ 航班号长度异常: \(flightNumber)")
}
```

2. **支持特殊格式**（如果需要）：
- 包含连字符：BJ-123 → BJ123
- 包含空格：BA 123 → BA123

---

## Q2: 读写日历分离

### 当前实现
目前采用的是**单日历模式**：
- 从选定的日历读取事件
- 修改后保存回同一日历

### 改进方案：多日历模式 ✨

#### 方案描述
- **读取日历**（Source Calendar）：选择要扫描的日历（通常是航旅纵横创建的）
- **写入日历**（Target Calendar）：选择要保存格式化事件的日历（通常是 Flighty 专用日历）

#### 优势
1. **安全隔离**：原始事件保持不变
2. **灵活选择**：可从任何日历读取，写入到任何日历
3. **多源场景**：从多个日历读取，汇聚到一个日历
4. **易于回滚**：只需删除目标日历中的事件
5. **重复检测**：自动检测目标日历中的重复事件，避免重复创建

---

## 完整实现方案 ✅

### 文件清单

#### 核心模块
- `CalendarManager-Enhanced.swift` - 支持读写分离的增强版本
  - 两种模式：**单日历模式**（向后兼容）和**分离模式**（新增）
  - 自动持久化用户偏好
  - 完整的错误处理和验证

#### UI 组件
- `PreferencesViewEnhanced.swift` - 支持分离模式的偏好设置面板
  - 模式选择切换（Segmented Picker）
  - 源日历和目标日历分别选择
  - 告警复制选项
  - 实时验证和警告提示

### 核心特性

#### 1. 两种处理模式

**单日历模式**（默认）
```swift
useSeparateCalendars = false

// 行为：修改原始日历中的事件
📅 选择一个日历 → 读取 + 修改 → 保存回原日历
```

**分离模式**（新增）
```swift
useSeparateCalendars = true

// 行为：从源日历读取，创建新事件到目标日历
📅 源日历 → 读取 ➜ 解析 ➜ 创建新事件 ➜ 目标日历
```

#### 2. 灵活的日历选择

```swift
// 单日历模式
@Published var selectedCalendarIdentifier: String?

// 分离模式
@Published var sourceCalendarIdentifier: String?     // 读取源
@Published var targetCalendarIdentifier: String?     // 写入目标
```

#### 3. 事件关联信息保留

分离模式下，每个新事件都包含备注：
```
📌 原始标题: 乘坐CA123 北京-上海 T1 当地时间10:30-13:45 【航旅纵横】
📅 来源日历: [源日历名称]
```

#### 4. 告警复制支持

```swift
@Published var copyAlarmsToNewEvents: Bool = true

// 自动将原始事件的告警复制到新事件
if copyAlarmsToNewEvents && !sourceEvent.alarms.isEmpty {
    newEvent.alarms = sourceEvent.alarms
}
```

#### 5. 重复检测机制

```swift
// 检查目标日历中是否已存在相同标题的事件
if doesEventExistInTargetCalendar(withTitle: newTitle, calendar: targetCalendar) {
    appendLog("⏭️ 跳过重复事件: \(newTitle)")
    continue
}
```

---

## 使用场景示例

### 场景 1：修改原始日历（单日历模式）
```
步骤：
1. 打开偏好设置
2. 选择"单日历模式"
3. 选择包含航旅纵横事件的日历
4. 点击"转换航班事件"

结果：
📅 同一个日历中的事件被直接修改
✅ CA123 北京-上海 T1 当地时间10:30-13:45 → [FLIGHT] CA123 PEK-PVG T1 T2｜Local Time 10:30-13:45 [SYNCFL]
```

### 场景 2：保护原始事件（分离模式）
```
步骤：
1. 打开偏好设置
2. 选择"分离模式"
3. 源日历 = "航旅纵横"（保留原始事件的日历）
4. 目标日历 = "Flighty"（保存格式化事件的日历）
5. 启用"复制告警到新事件"
6. 点击"转换航班事件"

结果：
✅ 航旅纵横日历：原始事件保持不变
✅ Flighty 日历：创建格式化后的新事件
✅ 新事件包含告警和原始信息的备注
```

### 场景 3：多源汇聚
```
步骤：
1. 第一次运行
   - 源日历 = "航旅纵横"
   - 目标日历 = "Flighty"
   - 转换并创建事件

2. 添加到另一个日历后，再次运行
   - 源日历 = "另一个航班日历"
   - 目标日历 = "Flighty"（相同的目标）
   - 转换并创建事件

结果：
✅ Flighty 日历中汇聚了来自多个源的航班事件
✅ 自动检测和跳过重复事件
```

---

## 数据持久化

所有用户选择都自动保存到 UserDefaults：

```swift
// 单日历模式
"selectedCalendarIdentifier" 

// 分离模式
"useSeparateCalendars"          // 模式开关
"sourceCalendarIdentifier"       // 源日历 ID
"targetCalendarIdentifier"       // 目标日历 ID
"copyAlarmsToNewEvents"         // 告警复制选项
```

应用重启后自动恢复用户的上次选择。

---

## 代码集成指南

### 第一步：替换 CalendarManager

选择以下之一：

**选项 A：使用增强版本**（推荐）
```swift
// 删除旧的 CalendarManager.swift
// 将 CalendarManager-Enhanced.swift 重命名为 CalendarManager.swift
// 在 Xcode 中选择"Replace"
```

**选项 B：手动集成**
参考 `CalendarManager-Enhanced.swift` 中的新方法：
- `useSeparateCalendars` 属性
- `sourceCalendarIdentifier` 和 `targetCalendarIdentifier` 属性
- `formatFlightEventsWithSeparateCalendars()` 方法
- `doesEventExistInTargetCalendar()` 辅助方法

### 第二步：更新 UI

在 `ContentView.swift` 中根据模式显示不同的 UI：

```swift
if manager.useSeparateCalendars {
    // 显示源日历和目标日历选择
    // 显示分离模式特定的提示信息
} else {
    // 显示单一日历选择（原始行为）
}
```

也可以直接用 `PreferencesViewEnhanced.swift` 替换 `PreferencesView.swift`。

### 第三步：更新 SyncFlightApp.swift

```swift
.sheet(isPresented: $showPreferences) {
    PreferencesViewEnhanced(manager: manager)  // 使用增强版
}
```

---

## 日志输出示例

### 单日历模式
```
14:23:45 - 📅 开始扫描日历（单日历模式）...
14:23:45 - 📊 扫描结果: 总事件 15，航班事件 3
14:23:46 - ⏭️ 跳过已格式化事件: [FLIGHT] CA123 ...
14:23:46 - ✅ 已格式化: [FLIGHT] MU5147 PEK-SHA T1 T3｜Local Time 10:30-13:45 [SYNCFL]
14:23:46 - ✅ 已格式化: [FLIGHT] 9C1234 SHA-CAN T2 T3｜Local Time 14:00-17:15 [SYNCFL]
14:23:47 - 🎉 已格式化 2 个航班事件
```

### 分离模式
```
14:25:30 - 📅 从 '航旅纵横' 读取，写入到 'Flighty'...
14:25:31 - 📊 源日历扫描结果: 总事件 20，航班事件 5
14:25:31 - ✅ 已创建新事件: [FLIGHT] CA123 PEK-SHA T1 T3｜Local Time 10:30-13:45 [SYNCFL]
14:25:31 - 🔔 已复制 1 个告警
14:25:32 - ⏭️ 跳过重复事件: [FLIGHT] MU5147 PEK-SHA T1 T3｜Local Time 15:45-19:00 [SYNCFL]
14:25:33 - ✅ 已创建新事件: [FLIGHT] 9C1234 SHA-CAN T2 T3｜Local Time 14:00-17:15 [SYNCFL]
14:25:33 - 🎉 已创建 2 个新事件到目标日历（跳过 1 个重复）
```

---

## Q&A 总结

### Q1: 是否支持 4 位数航班号或两字码包含数字的航班号？

**答案：✅ 完全支持**

当前正则表达式模式 `[A-Z0-9]+` 支持：
- ✅ MU5147（两字母 + 四位数字）
- ✅ 9C1234（数字 + 字母 + 数字）
- ✅ CA123（两字母 + 三位数字）
- ✅ 任何长度的字母数字组合（通常 2-6 位）

**验证方法**：在偏好设置中查看"航班号支持"信息，或查看解析后的日志。

### Q2: 可否做到读和写日历分离？

**答案：✅ 完全支持（两种模式）**

#### 单日历模式（默认）
- 原有行为：读和写同一日历
- 优点：简单快速，原地修改
- 用途：个人使用，快速转换

#### 分离模式（新增）
- 新行为：从源日历读取，创建新事件到目标日历
- 优点：保护原始事件，支持多源汇聚，易于回滚
- 用途：备份保护，多日历管理，团队协作

**在偏好设置中可以随时切换两种模式。**

---

## 迁移建议

如果你想使用增强版本：

1. **备份现有项目**（以防万一）
2. **替换 CalendarManager.swift**
   - 用 `CalendarManager-Enhanced.swift` 替代
3. **更新 PreferencesView**
   - 可选：用 `PreferencesViewEnhanced.swift` 替代以获得完整 UI
4. **测试两种模式**
   - 测试单日历模式（应该行为不变）
   - 测试分离模式（新功能）
5. **保留旧版本**
   - 原始 `CalendarManager.swift` 可存档备用

---

## 技术细节

### 航班号正则表达式
```regex
[A-Z0-9]+

支持字符：
- A-Z：大写字母（IATA 航空公司代码标准）
- 0-9：数字
- +：一个或多个

长度范围：
- 最小：2 字符（如 BA、CA）
- 最大：6 字符（如 USONLY）
- 通常：3-5 字符（如 CA123、MU5147、9C1234）
```

### 日历隔离实现
```swift
// 分离模式工作流
1. 获取源日历中的所有事件
2. 过滤出航旅纵横格式的事件
3. 对每个事件：
   a. 解析航班信息
   b. 检查目标日历是否已存在
   c. 创建新事件到目标日历
   d. 复制告警（如果启用）
   e. 添加备注信息
4. 返回统计结果（创建数、跳过数）
```

---

## 常见问题

**Q: 分离模式下，原始事件会被修改吗？**
A: 不会。分离模式只创建新事件，原始事件保持完全不变。

**Q: 可以从多个源日历读取吗？**
A: 当前版本一次只能选择一个源日历。但可以多次运行，每次选择不同的源日历，同时保持目标日历不变，即可实现多源汇聚。

**Q: 如何回滚分离模式的修改？**
A: 只需删除目标日历中的事件，源日历的原始事件不受影响。

**Q: 分离模式下的告警如何处理？**
A: 默认启用自动复制。在偏好设置中可关闭"复制告警到新事件"选项。

**Q: 重复检测是否准确？**
A: 通过比较事件标题进行检测。如果标题相同，认为是重复。可根据需要在代码中调整检测逻辑。

---

**最后更新**：2026-05-12  
**文档版本**：1.0.0  
**作者**：Merak Weng
