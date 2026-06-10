# QuietToday

QuietToday 是一个安静、克制的 iOS 待办应用。它不强调复杂的日期管理，而是把注意力放在眼前这一页：快速写下事情，完成后轻轻划掉，需要时再加提醒或例行任务。

项目地址：[github.com/Evina-Huang/QuietToday](https://github.com/Evina-Huang/QuietToday)

## 功能

- 在主页面快速添加待办。
- 点击键盘的“完成”即可提交新待办。
- 直接在列表里修改待办，点击键盘“完成”会保存修改。
- 点击重勾按钮完成任务，带有更明确的完成反馈。
- 左滑删除普通待办，或跳过当天生成的例行任务。
- 右滑设置提醒、修改提醒、置顶或取消置顶。
- 支持每日、每周、每月例行任务。
- 支持本地通知提醒。
- 支持桌面小组件，包含小尺寸和中尺寸。
- 数据保存在本地设备，不依赖服务器。

## 小组件

QuietToday Widget 使用 WidgetKit 构建，展示当前待办概览和进度。空白状态会显示“今日留白”，有待办时会优先展示未完成事项。

小组件和 App 通过 App Group 共享快照数据：

```text
group.com.evina.quiettoday
```

在真机或发布版本中，需要在 Apple Developer 和 Xcode Signing & Capabilities 里启用对应的 App Group。

## 项目结构

- `QuietToday/`：SwiftUI App 源码。
- `QuietToday/Models/`：待办、例行任务和提醒模型。
- `QuietToday/Services/`：本地存储、通知调度和小组件快照刷新。
- `QuietToday/Views/`：主页面、任务行、提醒、例行任务等界面。
- `QuietToday/Shared/`：App 和 Widget 共享的数据结构。
- `QuietTodayWidget/`：WidgetKit 小组件扩展。
- `BrandConcepts/`：品牌和图标探索素材。
- `Screenshots/`：应用截图。
- `project.yml`：XcodeGen 项目配置。

## 环境要求

- Xcode 16 或更新版本
- iOS 17.0 或更新版本
- XcodeGen

应用使用 SwiftUI 和 WidgetKit 构建，没有第三方运行时依赖。

## 运行

如果修改了 `project.yml`，先重新生成 Xcode 项目：

```sh
xcodegen generate
```

然后打开 `QuietToday.xcodeproj`，选择 `QuietToday` scheme，在 iOS 模拟器或真机上运行。

也可以使用命令行构建：

```sh
xcodebuild -project QuietToday.xcodeproj \
  -scheme QuietToday \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 备注

提醒功能会在设置提醒时请求通知权限。应用数据和小组件快照都保存在本地，不会上传到服务器。
