# 🔧 编译错误修复指南

## 问题现象

编译出现以下错误：
- `Ambiguous use of 'init()'` - CalendarManager
- `Reference to member 'shared' cannot be resolved` - FormatFlightEventsIntent
- `'CalendarManager' is ambiguous for type lookup` - LogsPanelView

## 根本原因

同时存在两个 `CalendarManager` 类定义导致冲突：
- `CalendarManager.swift`（原始版本）
- `CalendarManager-Enhanced.swift`（增强版本）

类似地，也存在两个 `PreferencesView` 版本的冲突。

---

## 🛠️ 修复步骤

### 第 1 步：在 Xcode 中删除冗余文件

在 Xcode 项目中，右击这些文件并选择 **Delete → Remove Reference**（不删除文件）或 **Delete → Delete**（删除文件）：

1. ❌ **CalendarManager-Enhanced.swift** - 删除（已整合到 CalendarManager.swift）
2. ❌ **PreferencesViewEnhanced.swift** - 删除（已整合到 PreferencesView.swift）
3. ❌ **PreferencesView-New.swift** - 暂不动，见下一步

### 第 2 步：更新 PreferencesView.swift

选择以下之一：

**方案 A：使用新的增强版本（推荐）**

1. 在 Xcode 中删除 `PreferencesView.swift`
2. 将 `PreferencesView-New.swift` 重命名为 `PreferencesView.swift`
   - 右击 → Rename
3. 确保文件在 Target 中被正确选中

**方案 B：手动编辑**

如果不想用新文件，可以手动更新 PreferencesView.swift 以支持新的属性：
- 添加模式选择控件（Picker for `useSeparateCalendars`）
- 添加源日历选择（源日历和目标日历）
- 添加分离模式特定选项

### 第 3 步：清理并重建

1. 在 Xcode 中，选择 **Product → Clean Build Folder**（Shift + Cmd + K）
2. 选择 **Product → Build**（Cmd + B）
3. 如果仍有错误，检查：
   - 所有文件都在正确的 Target 中
   - 没有重复的类定义

### 第 4 步：验证修复

检查以下文件是否能够正确引用 `CalendarManager`：

✅ **应该能编译的文件**：
- `FormatFlightEventsIntent.swift` - 使用 `CalendarManager.shared`
- `LogsPanelView.swift` - 接收 `@ObservedObject var manager: CalendarManager`
- `PreferencesView.swift` - 绑定 `useSeparateCalendars`, `sourceCalendarIdentifier` 等
- `ContentView.swift` - 使用 `CalendarManager.shared`

---

## 📋 文件最终清单

### 应该保留的文件

```
✅ CalendarManager.swift
   - 支持单日历和分离模式的完整实现
   - 包含所有日历管理逻辑

✅ PreferencesView.swift
   - 支持两种模式的完整 UI
   - 包含模式切换、日历选择等

✅ 其他核心文件
   - FlightParser.swift
   - AirportDictionary.swift
   - LogsPanelView.swift
   - ContentView.swift
   - FormatFlightEventsIntent.swift
   - PlatformBridge.swift
   - syncFlight_reBuiltApp.swift
```

### 应该删除的文件

```
❌ CalendarManager-Enhanced.swift
   - 功能已整合到 CalendarManager.swift

❌ PreferencesViewEnhanced.swift
   - 功能已整合到 PreferencesView.swift

❌ PreferencesView-New.swift
   - 如果已使用其内容更新 PreferencesView.swift，可删除
   - 或直接删除后将新内容复制到 PreferencesView.swift
```

---

## 🔍 逐步排除法

如果清理后仍有问题，依次尝试：

### 检查 1：验证 CalendarManager 只有一个

```bash
# 在终端中执行
grep -r "class CalendarManager" /Users/merak/Documents/Xcode/syncFlight_reBuilt/

# 应该只显示一个匹配（来自 CalendarManager.swift）
# 如果有多个，表示还有重复的文件
```

### 检查 2：验证文件在 Target 中

1. 在 Xcode 中选择项目
2. 选择 Target
3. 进入 Build Phases → Compile Sources
4. 检查每个 .swift 文件是否只出现一次
5. 删除任何重复的文件引用

### 检查 3：清除派生数据

```bash
# 清除 Xcode 的派生数据
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 或在 Xcode 中：
# Cmd + Shift + K （Clean Build Folder）
```

### 检查 4：验证导入语句

确保所有文件正确导入：

```swift
// 应该出现在需要 CalendarManager 的文件中
import Combine

// 不应该有重复的导入
```

---

## ✅ 验证清单

修复完成后，确保：

- [ ] 没有编译错误或警告
- [ ] Xcode 的 Project Navigator 中没有重复文件
- [ ] 所有 `.swift` 文件只在 Target 中出现一次
- [ ] 能够成功构建项目
- [ ] 应用能够正常运行

---

## 📞 如果仍有问题

如果按照以上步骤后仍有编译错误，请提供：

1. 错误消息的完整文本
2. Xcode 中 Project Navigator 的当前文件列表
3. Build Phases 中 Compile Sources 的内容

---

## 🎯 推荐操作流程

1. ✅ Xcode 中删除 `CalendarManager-Enhanced.swift`
2. ✅ Xcode 中删除 `PreferencesViewEnhanced.swift`
3. ✅ Xcode 中删除 `PreferencesView.swift`
4. ✅ Xcode 中删除 `PreferencesView-New.swift`
5. ✅ 拖拽本文档中的 `PreferencesView.swift` 内容到编辑器中创建新文件
6. ✅ Clean Build Folder（Shift + Cmd + K）
7. ✅ Build（Cmd + B）
8. ✅ 完成！

---

**最后更新**：2026-05-12  
**作者**：Merak Weng
