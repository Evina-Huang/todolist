# QuietToday

QuietToday is a small iOS todo app for keeping today simple. It focuses on a calm daily list, quick entry, gentle reminders, and recurring routines that materialize into today's tasks when needed.

## Features

- Add one-line todos from the Today screen.
- Tap the keyboard Done key to submit a new todo.
- Mark tasks complete or edit titles inline.
- Swipe right on a task to set or change a reminder.
- Swipe left on a task to delete it, or skip today's routine instance.
- Create repeating routines for daily, weekly, or monthly tasks.
- Store tasks and routines locally in Application Support.
- Schedule local notifications for task and routine reminders.

## Project

- `QuietToday/` - SwiftUI app source.
- `QuietToday/Models/` - task, routine, and reminder models.
- `QuietToday/Services/` - persistence and notification scheduling.
- `QuietToday/Views/` - Today, routine, reminder, and shared UI views.
- `BrandConcepts/` - logo and brand exploration assets.
- `Screenshots/` - current app screenshots.
- `project.yml` - XcodeGen project configuration.

## Requirements

- Xcode 16 or newer
- iOS 17.0 or newer

The app is written in SwiftUI and has no third-party runtime dependencies.

## Running

Open `QuietToday.xcodeproj` in Xcode, choose the `QuietToday` scheme, and run it on an iOS simulator or device.

You can also build from the command line:

```sh
xcodebuild -project QuietToday.xcodeproj \
  -scheme QuietToday \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Notes

Notification permissions are requested by the app when reminders are scheduled. App data is stored locally on the device and is not synced to a server.
