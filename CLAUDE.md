# CLAUDE.md — Questlog repo notes

## What this is

Quest/fantasy-themed iOS+macOS task manager. SwiftUI + SwiftData. Multiplatform single target. iOS 17 / macOS 14 deployment, Swift 6 strict concurrency. See `PLAN.md` for the full architectural plan and `README.md` for user-facing docs.

## Environment quirks

- `xcode-select -p` points at `/Library/Developer/CommandLineTools` — `xcodebuild` / `xcrun simctl` will fail without `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Prepend it on every invocation, or assume Samuel has run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
- Only iPhone 16/17-series simulators installed (no iPhone 15 Pro despite what `PLAN.md` says). Use **iPhone 17 Pro** as the canonical sim.
- Xcode is 26.4.1; SDKs are iOS 26.4 / macOS 26.4 (deployment target stays at 17.0 / 14.0).

## Project file is generated

`Questlog.xcodeproj` is in `.gitignore`. Regenerate with `xcodegen generate` from `project.yml`. Never hand-edit the pbxproj — change `project.yml` and regenerate.

## Build / test / run commands

```sh
DEV=/Applications/Xcode.app/Contents/Developer

# Build iOS sim
DEVELOPER_DIR=$DEV xcodebuild -project Questlog.xcodeproj -scheme Questlog \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run all tests (12 unit + 1 UI)
DEVELOPER_DIR=$DEV xcodebuild -project Questlog.xcodeproj -scheme Questlog \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Build macOS — requires ad-hoc signing override since DEVELOPMENT_TEAM is unset
DEVELOPER_DIR=$DEV xcodebuild -project Questlog.xcodeproj -scheme Questlog \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build

# Boot sim + install + launch
DEVELOPER_DIR=$DEV xcrun simctl boot "iPhone 17 Pro" 2>/dev/null
open -a Simulator
APP="$HOME/Library/Developer/Xcode/DerivedData/Questlog-hdrdrmchkblprlgwxcwvutcahjig/Build/Products/Debug-iphonesimulator/Questlog.app"
DEVELOPER_DIR=$DEV xcrun simctl install booted "$APP"
DEVELOPER_DIR=$DEV xcrun simctl launch booted com.samuelyancy.questlog
```

The DerivedData path hash (`Questlog-hdrdrmchkblprlgwxcwvutcahjig`) is stable per machine. If it changes, find the current one with `ls $HOME/Library/Developer/Xcode/DerivedData/ | grep Questlog`.

## Code conventions (enforce these)

- **Theme tokens only.** Every `Color` and `Font` reference goes through `Theme.Colors.*` / `Theme.Fonts.*` in `Questlog/Theme/Theme.swift`. No inline `Color("foo")` or `Font.custom(...)` anywhere else.
- **`@Query` is always `#Predicate` + `sort`.** Even "fetch all" queries must specify both. The `QuestListContent` private wrapper in `QuestListView.swift` exists only because `@Query` initializers run before stored-property init — when you need a runtime-decided filter, build a small wrapper that takes the filter and constructs `_quests = Query(...)` in its init.
- **`Quest.status` is computed from `Quest.statusRaw: String`.** SwiftData `#Predicate` can't compare enum values across the SQLite boundary, so filtering uses `statusRaw == raw` with `let raw = filter.rawValue` captured before the predicate. Don't try to "fix" this by storing `QuestStatus` directly — it'll break list filtering at runtime.
- **`List` or `LazyVStack` for collections.** `ForEach` inside `VStack` is banned for any data-driven list.
- **Platform guards for divergent UI.** `.insetGrouped` is iOS-only — wrap with `#if os(iOS)` and provide `.inset` for macOS. Same for `.navigationBarTitleDisplayMode`.
- **`@Bindable var` for `@Model` instances passed into views** that need two-way binding to model properties (see `ObjectiveRow`, `QuestDetailView`).

## Test layout

- `QuestlogTests/` uses `import Testing` (Swift Testing, `@Test` / `#expect` / `@Suite`).
- `QuestlogUITests/` uses XCTest (Swift Testing isn't supported for UI tests as of Xcode 26).
- SwiftData unit tests build an in-memory `ModelContainer` via `ModelConfiguration(isStoredInMemoryOnly: true)` — see `QuestTests.makeContext()`.

## Things deferred (don't add without asking)

- Custom fonts (Cinzel, Lora) — `Theme.Fonts` currently returns `.system(design: .serif)` as a placeholder. Swap to `.custom(...)` only when actual `.ttf` files land in `Resources/Fonts/` and are registered via `UIAppFonts` in Info.plist (set via `INFOPLIST_KEY_*` in `project.yml`).
- AI recap, sounds, CloudKit sync, XP/levels, splash screen, TestFlight automation. All listed as out-of-scope in `PLAN.md`.

## Don'ts

- Don't commit `Questlog.xcodeproj/`, `DerivedData/`, `build/`, or `xcuserdata/` — gitignored.
- Don't run `sudo xcode-select` without asking; Samuel can do it himself, and `DEVELOPER_DIR=` works fine.
- Don't add `DEVELOPMENT_TEAM` to `project.yml` — Samuel hasn't enrolled in the Apple Developer Program yet (M0 in `PLAN.md`).
- Don't introduce `@StateObject` / `ObservableObject` / `@Published` — this codebase uses Swift 5.9+ `@Observable` macro throughout.
- Don't add a ViewModel layer — `PLAN.md` Code Quality #2 commits to pure SwiftUI MV (`@Query` + `modelContext` directly in views).
