# Questlog

Quest-themed iOS task manager. Projects are main quests; subtasks are objectives ticked off along the way. Skyrim-adjacent flavor to make todo work feel like a game.

## Status

MVP scaffold complete. iOS + macOS both build clean, 12/12 unit tests + 1/1 UI smoke test green. Not yet on TestFlight.

## Stack

- **SwiftUI** (multiplatform: iOS 17+, macOS 14+)
- **SwiftData** (`@Model` Quest + Objective, cascade delete, in-process `@Query`)
- **Swift Testing** for unit tests, **XCTest** for UI tests
- **Swift 6** with strict concurrency
- **xcodegen** for project generation (project file is gitignored — regenerate from `project.yml`)

## What's in the MVP

- Create / edit / delete quests with title + summary
- Status state machine: `active ↔ completed`, `active ↔ abandoned` (no completed↔abandoned crosswire)
- Filter quests by status (segmented picker)
- Add / toggle / inline-edit / swipe-delete objectives within a quest
- Quest list sorted by `lastOpenedAt` desc
- Themed parchment/ink/quest-gold palette with light + dark variants
- Empty state, error alert pipeline (`ErrorPresenter`), service stubs for sounds + AI recap

## Deferred (post-MVP)

- AI-generated launch recap (Apple Foundation Models or proxied Anthropic)
- UI sounds + ambient music
- iCloud sync via CloudKit
- Custom Cinzel/Lora fonts (currently using system serif as placeholder behind same `Theme.Fonts` API)
- Game mechanics: XP, levels, achievements
- TestFlight distribution

## Run it

Prerequisites: macOS with Xcode 26+ installed at `/Applications/Xcode.app`. The `xcode-select` developer dir may still point at CommandLineTools — pass `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` to `xcodebuild`/`xcrun`, or run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` once.

```sh
# Generate the Xcode project (gitignored)
brew install xcodegen   # if not installed
xcodegen generate

# Open in Xcode and ⌘R against the iPhone 17 Pro simulator
open Questlog.xcodeproj

# Or build + launch from the CLI
DEV=/Applications/Xcode.app/Contents/Developer
DEVELOPER_DIR=$DEV xcodebuild -project Questlog.xcodeproj -scheme Questlog \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
DEVELOPER_DIR=$DEV xcrun simctl boot "iPhone 17 Pro" 2>/dev/null
open -a Simulator
APP="$HOME/Library/Developer/Xcode/DerivedData/Questlog-hdrdrmchkblprlgwxcwvutcahjig/Build/Products/Debug-iphonesimulator/Questlog.app"
DEVELOPER_DIR=$DEV xcrun simctl install booted "$APP"
DEVELOPER_DIR=$DEV xcrun simctl launch booted com.samuelyancy.questlog
```

## Run the tests

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Questlog.xcodeproj -scheme Questlog \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Layout

```
Questlog/
  App/QuestlogApp.swift          // App entry, ModelContainer, error alert mount
  Quests/                        // QuestListView, QuestDetailView, QuestRowView, QuestEditorView
  Objectives/                    // ObjectiveRow, ObjectiveEditor
  Theme/Theme.swift              // Colors, Fonts, Sounds, Spacing, Radius
  Persistence/                   // Quest @Model, Objective @Model, QuestStatus enum
  Services/                      // ErrorPresenter, SoundService stub, RecapService stub, AppError
  Common/Date+Relative.swift
  Resources/Assets.xcassets      // Parchment / Ink / QuestGold / AbandonedGray colorsets
QuestlogTests/                   // QuestStatusTests, QuestTests, ObjectiveTests
QuestlogUITests/AppLaunchTests.swift
project.yml                      // xcodegen spec
PLAN.md                          // architectural plan + decisions
CLAUDE.md                        // notes for AI collaborators
```

## Design rules (don't break these)

- **Never inline `Color(...)` or `Font.custom(...)` outside `Theme/Theme.swift`.** Add a token there and reference `Theme.Colors.X` / `Theme.Fonts.Y(...)`.
- **Every `@Query` includes `#Predicate` + `sort`**, even when fetching "all". No unsorted/unfiltered queries.
- **Multi-row UI uses `List` or `LazyVStack`.** No bare `ForEach` inside `VStack` for collections.
- **`Quest.status` is a computed wrapper over `statusRaw: String`** — `#Predicate` can't compare enum values directly. Filter on `statusRaw`.
- **Platform-specific list styles need `#if os(iOS)`** (e.g. `.insetGrouped` is iOS-only).

See `PLAN.md` for the full architectural rationale.
