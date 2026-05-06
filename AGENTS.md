# AGENTS.md

## Setup

```sh
brew install xcodegen
xcodegen generate                         # regenerates Questlog.xcodeproj (gitignored)
```

## Commands

Always prepend `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` — `xcode-select` points at CommandLineTools.

```sh
DEV=/Applications/Xcode.app/Contents/Developer

# iOS build + test (use iPhone 17 Pro simulator)
DEVELOPER_DIR=$DEV xcodebuild -project Questlog.xcodeproj -scheme Questlog \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
DEVELOPER_DIR=$DEV xcodebuild -project Questlog.xcodeproj -scheme Questlog \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# macOS build (requires ad-hoc signing override)
DEVELOPER_DIR=$DEV xcodebuild -project Questlog.xcodeproj -scheme Questlog \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

DerivedData hash: `Questlog-hdrdrmchkblprlgwxcwvutcahjig`. If it changes: `ls ~/Library/Developer/Xcode/DerivedData/ | grep Questlog`.

## Architecture

- Single target `Questlog` (iOS 17 + macOS 14), SwiftUI + SwiftData, Swift 6 strict concurrency
- Entry: `Questlog/App/QuestlogApp.swift`
- Directories: `Quests/` `Objectives/` `Persistence/` `Theme/` `Services/` `Common/` `Resources/`
- Tests: `QuestlogTests/` (Swift Testing `@Test`/`@Suite`) + `QuestlogUITests/` (XCTest)
- In-memory test context: `ModelConfiguration(isStoredInMemoryOnly: true)` — see `QuestTests.makeContext()`

## Conventions (enforce)

- **All `Color`/`Font` through `Theme.Colors.*` / `Theme.Fonts.*` in `Theme/Theme.swift`.** No inline `Color("...")` or `Font.custom(...)`.
- **`@Query` always needs `#Predicate` + `sort`**, even for "fetch all".
- **`Quest.status` is computed from `statusRaw: String`.** `#Predicate` can't compare enums across SQLite — filter on `statusRaw == raw`.
- **`List` or `LazyVStack` for collections.** No `ForEach` inside `VStack` for data-driven lists.
- **`@Bindable var` for `@Model` instances** that need two-way binding.
- **Platform guards:** `.insetGrouped` is iOS-only — `#if os(iOS)` / `#else` with `.inset` for macOS.
- **No ViewModel layer.** Use `@Query` + `modelContext` directly in views.
- **No `@StateObject` / `ObservableObject` / `@Published`.** Codebase uses `@Observable` macro.

## Project file

`project.yml` → `xcodegen generate` → `Questlog.xcodeproj`. Never hand-edit the pbxproj.

## Deferred (don't add without asking)

Custom fonts, AI recap, sounds, CloudKit sync, XP/levels, splash screen, TestFlight automation.
