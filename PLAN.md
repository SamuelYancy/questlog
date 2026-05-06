# Plan: Questlog — Quest-themed iOS task manager (MVP)

## Context

Samuel wants a quest/fantasy-themed iOS task manager. Projects feel like main quests; subtasks are objectives ticked off along the quest path. Skyrim-adjacent visual/audio flavor to make todo work feel like a game. On every app launch, an AI-generated recap of recent quest activity. MVP path: build → run in iOS simulator on Mac → ship to TestFlight on Samuel's iPhone. macOS app is a likely future expansion.

Stack is Swift per Samuel's call — agreed (see Architecture #1 for why SwiftUI specifically).

This plan covers MVP only. Game mechanics (XP, levels, achievements) are intentionally deferred until we've used the bare app and know what's fun.

## Prerequisites

- **Xcode.app is installed** (Xcode 26.4.1 at `/Applications/Xcode.app`, all SDKs present including iPhoneOS, iPhoneSimulator, MacOSX). Active developer directory currently points at CommandLineTools — needs one-time switch via `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` before `xcodebuild` works without `DEVELOPER_DIR=` prefix.
- **Apple Developer Program** ($99/yr) required for TestFlight (M9). Free tier allows simulator + tethered on-device install but not TestFlight distribution.
- **Apple Intelligence-capable iPhone** (iPhone 15 Pro / 15 Pro Max / 16+ / 17+) if/when we add on-device AI recap (currently deferred — see Architecture #3).

## Phase 1 findings

Greenfield repo. Only `.gitignore` and a 10-byte `README.md` present at start. No prior code, no patterns to match.

Environment:
- macOS 26.0 (Tahoe), Apple Silicon
- Swift 6.2.4 (CLI tools only — full Xcode missing)
- macOS SDK 26.2 — no iOS SDK because no Xcode

## Architecture decisions

### #1 UI framework — SwiftUI, multi-platform target

Single Xcode target builds for iOS, iPadOS, and macOS. Use `#if os(iOS)` / `#if os(macOS)` only for nav-shell differences (TabView on iOS, NavigationSplitView on macOS). Minimum deployment: iOS 17 / macOS 14 (required for SwiftData + `@Observable`).

### #2 Persistence — SwiftData

`@Model` Quest and Objective. `@Query` directly in views for simple lists. ModelContext injected via `.modelContainer()` in the App entry point. CloudKit sync stays off for MVP — flip to `.cloudKit` later if we want cross-device.

### #3 AI recap — DEFERRED to v2

Out of MVP scope. Stub a `RecapService` protocol now so v2 can drop in either Apple Foundation Models or a proxied Anthropic call without touching views. MVP launch screen shows a simple non-AI status line ("3 active quests · last opened 3h ago").

### #4 Data model shape — Hybrid (minimal now, additive later)

```swift
@Model class Quest {
  var title: String
  var summary: String
  var status: QuestStatus  // .active, .completed, .abandoned
  var createdAt: Date
  var completedAt: Date?
  var lastOpenedAt: Date
  @Relationship(deleteRule: .cascade) var objectives: [Objective]
}

@Model class Objective {
  var title: String
  var isComplete: Bool
  var order: Int
  var quest: Quest?
}
```

XP, level, questType fields are deliberately omitted. Add via SwiftData migration once we know what mechanics feel fun.

## Code quality decisions

### #1 File layout — feature folders

```
Questlog/
  App/                  // QuestlogApp.swift, AppEntry, ModelContainer setup
  Quests/              // QuestListView, QuestDetailView, QuestRowView
  Objectives/          // ObjectiveRow, ObjectiveEditor
  Theme/               // Theme.swift (Colors, Fonts, Sounds, Spacing)
  Persistence/         // Quest.swift, Objective.swift, QuestStatus.swift, Migration.swift
  Services/            // ErrorPresenter, SoundService (stub), RecapService (stub)
  Common/              // shared View modifiers, extensions, Date+formatting
  Resources/           // Assets.xcassets, fonts, audio
QuestlogTests/         // see Test strategy
```

### #2 State pattern — Pure SwiftUI MV (`@Observable` + `@Query`)

Views read SwiftData via `@Query` and write through `modelContext`. No ViewModel layer. Cross-cutting concerns are `@Observable` services injected via `.environment()`:
- `ErrorPresenter` — collects and surfaces errors
- `SoundService` — plays UI sounds (stub for MVP)
- `RecapService` — protocol stub for v2 AI recap

### #3 Theme system — typed namespaced Theme

```swift
enum Theme {
  enum Colors {
    static let parchment = Color("Parchment")
    static let ink = Color("Ink")
    static let questGold = Color("QuestGold")
    static let abandonedGray = Color("AbandonedGray")
  }
  enum Fonts {
    static func display(_ size: CGFloat) -> Font { .custom("Cinzel", size: size) }
    static func body(_ size: CGFloat) -> Font { .custom("Lora", size: size) }
  }
  enum Sounds { /* sound asset names */ }
  enum Spacing {
    static let s: CGFloat = 8; static let m: CGFloat = 16; static let l: CGFloat = 24
  }
}
```

Asset catalog backs the Color names. Custom fonts (Cinzel, Lora — both free Google Fonts with quest-appropriate feel) shipped via `Resources/`. **Never** inline a `Color()` or `Font.custom()` outside `Theme.swift`.

### #4 Error handling — typed throws + ErrorPresenter

Service layer uses Swift 6.2 typed throws:

```swift
enum PersistenceError: Error { case saveFailed, fetchFailed, modelMissing }
func saveQuest(_ q: Quest) throws(PersistenceError) { ... }
```

`ErrorPresenter` is an `@Observable` collector mounted at the App root; views call `errorPresenter.report(error)` for unexpected failures. SwiftUI `.alert($errorPresenter.currentError)` modifier handles presentation. Expected failures (validation) are handled inline at the call site.

## Testing strategy — light MVP footprint

Use **Swift Testing** (`@Test` / `#expect`), not XCTest. Total target: ~10 tests, ~30-60 min upfront.

**Unit tests** (`QuestlogTests/`):
- `QuestStatusTests` — valid transitions; illegal transitions are rejected
- `QuestTests` — `lastOpenedAt` updates on `markOpened()`; `completedAt` set when status becomes `.completed`
- `ObjectiveTests` — `order` preserved on insert/delete/reorder; cascade delete when parent quest deleted

**UI smoke test** (`QuestlogUITests/`):
- App launches, root quest list view appears, no crash. One test, ~5 lines.

**Out of scope for MVP:** service-layer tests (no real services yet), snapshot tests (defer until theme is stable), full UI coverage. Add service tests in v2 alongside `RecapService`.

## Performance considerations

### #1 @Query and list virtualization conventions

Set as project conventions on day one (zero code cost):

- **Every `@Query` includes `#Predicate` + `sort`**, even when it's "fetch all active":
  ```swift
  @Query(filter: #Predicate<Quest> { $0.status == .active },
         sort: \Quest.lastOpenedAt, order: .reverse)
  var quests: [Quest]
  ```
- **All multi-row UI uses `List` or `LazyVStack`.** Plain `ForEach` inside `VStack` is banned for collections.
- **Objective progress display ("3/5") uses a computed property on `Quest`.** At MVP scale (<100 quests, <50 objectives each) this is cheap. Denormalize `completedObjectiveCount` onto Quest only if scale demands it later.

### #2 Cold-start launch

No special handling for MVP. Default SwiftUI + SwiftData launch on iPhone 15+ is ~200-400ms — acceptable. If TestFlight shows it feels sluggish on Samuel's actual device, add a themed splash screen ("Preparing your adventure...") as a fast follow-up.

## Implementation milestones

Tackled in order. Each is a logical commit point.

### M0 — Prerequisites (Samuel, not Claude)
- Install **Xcode.app** from Mac App Store (~10 GB)
- Sign in to Apple ID in Xcode → Settings → Accounts
- Confirm Apple Developer Program membership for TestFlight (or accept simulator + tethered-only path on free tier)

### M1 — Project bootstrap
- `File → New → Multiplatform App`, name "Questlog", bundle ID e.g. `com.samuelyancy.questlog`
- Deployment targets: **iOS 17.0**, **macOS 14.0** (required for SwiftData + `@Observable`)
- Create folder structure: `App/`, `Quests/`, `Objectives/`, `Theme/`, `Persistence/`, `Services/`, `Common/`, `Resources/`
- Configure `.gitignore` for Xcode (DerivedData, xcuserdata, etc.)
- Initial commit

### M2 — Theme foundation
- Create `Theme/Theme.swift` with `Colors`, `Fonts`, `Sounds`, `Spacing` namespaces (see Code quality #3 for shape)
- Add color sets to `Assets.xcassets`: `Parchment`, `Ink`, `QuestGold`, `AbandonedGray` (light + dark variants)
- Add **Cinzel** (display) and **Lora** (body) fonts to `Resources/`. Register via `UIAppFonts` in `Info.plist`.
- Build a `ThemePreview` SwiftUI view to verify everything renders. Delete or move to a debug-only target before ship.

### M3 — Persistence layer
- `Persistence/QuestStatus.swift` — `enum QuestStatus: String, Codable { case active, completed, abandoned }`
- `Persistence/Quest.swift` — `@Model` per Architecture #4
- `Persistence/Objective.swift` — `@Model` per Architecture #4
- `App/QuestlogApp.swift` — `.modelContainer(for: [Quest.self, Objective.self])` on the root scene
- No CloudKit yet (MVP stays local)

### M4 — Quest list view
- `Quests/QuestListView.swift` — `@Query` for active quests, sorted by `lastOpenedAt` desc
- `Quests/QuestRowView.swift` — title, status pill (Theme.Colors), "`X/Y objectives`" computed on Quest
- Empty state copy: "No active quests. Begin a new adventure."
- Toolbar `+` button → sheet with `QuestEditorView`
- A status filter (active/completed/abandoned) is a 5-line picker — include it.

### M5 — Quest detail + objectives
- `Quests/QuestDetailView.swift` — title (Theme.Fonts.display), summary, status controls (mark complete / abandon / restore), objectives list
- `Objectives/ObjectiveRow.swift` — checkbox toggle, inline edit, swipe-to-delete
- `Objectives/ObjectiveEditor.swift` — sheet for adding/editing objectives
- Update `lastOpenedAt = .now` on `.onAppear`
- Cascade delete: handled by `@Relationship(deleteRule: .cascade)` on Quest.objectives

### M6 — Error handling + Services scaffolding
- `Services/ErrorPresenter.swift` — `@Observable` class with `currentError: AppError?` and `.report(_:)` method
- `App/QuestlogApp.swift` — `.environment(errorPresenter)` and `.alert(...)` mounted at root
- `Services/SoundService.swift` — protocol stub only, no implementation (sounds deferred post-MVP)
- `Services/RecapService.swift` — protocol stub only (AI recap deferred post-MVP)

### M7 — Tests (light footprint)
- `QuestlogTests/` using **Swift Testing** (`import Testing`):
  - `QuestStatusTests.swift` — valid/invalid transitions
  - `QuestTests.swift` — `markOpened()` updates `lastOpenedAt`; `complete()` sets `completedAt` and status
  - `ObjectiveTests.swift` — order preserved on insert/delete; cascade on parent delete
- `QuestlogUITests/AppLaunchTests.swift` — single `@Test` that launches and asserts root nav title

### M8 — Simulator validation
- Run on iOS 17 simulator (iPhone 15 Pro)
- Manual checklist: create quest, add 3 objectives, toggle 2 complete, abandon, restore, delete — all should round-trip cleanly
- Run `xcodebuild test` for both targets — all green
- Quick scroll/cold-start sanity check

### M9 — TestFlight submission (DEFERRED)
Skipped for now per Samuel's call. Pick back up once MVP is solid in simulator.

### Out of scope (post-MVP backlog)
- AI recap (Apple Foundation Models on Apple Intelligence devices, or Anthropic via proxy)
- UI sounds (quest accepted, objective complete) and ambient music
- iCloud sync via CloudKit (`.cloudKit` toggle on `ModelContainer`)
- macOS target activation + sidebar layout
- Game mechanics (XP, levels, quest types, achievements)
- Themed splash screen if cold start feels slow

## Verification

### Code-level
- `xcodebuild -scheme Questlog test` — all Swift Testing targets pass
- `xcodebuild -scheme Questlog build` — clean build, no warnings

### End-to-end (simulator, iOS 17 iPhone 15 Pro)
1. Launch app → empty state visible, "Begin a new adventure" copy renders in custom font.
2. Tap `+` → editor sheet → create "Slay the Refactor Hydra" with summary.
3. Quest appears on list with status pill, "0/0 objectives".
4. Tap into quest → add 3 objectives.
5. Toggle 2 complete → row updates to "2/3".
6. Mark quest complete → leaves active list, appears in "completed" filter.
7. Force-quit and relaunch → all data persists, list ordered by `lastOpenedAt`.
8. Trigger an error path (e.g., delete the underlying ModelContainer mid-write — debug only) → ErrorPresenter alert appears at root.

### TestFlight (real device)
- Repeat steps 1-7 on Samuel's iPhone via TestFlight build.
- Cold start feels instant (or trigger M-spec splash fallback if not).
- No unexpected crashes in 5 min of use.

## Critical files

After M9, the code surface should be roughly:

```
Questlog/
  App/QuestlogApp.swift                          // App entry, ModelContainer, services
  Quests/QuestListView.swift                     // @Query, list, filter
  Quests/QuestRowView.swift                      // row presentation
  Quests/QuestDetailView.swift                   // detail + objectives list
  Quests/QuestEditorView.swift                   // create/edit sheet
  Objectives/ObjectiveRow.swift                  // toggle + edit + delete
  Objectives/ObjectiveEditor.swift               // create/edit sheet
  Theme/Theme.swift                              // Colors, Fonts, Sounds, Spacing
  Persistence/Quest.swift                        // @Model
  Persistence/Objective.swift                    // @Model
  Persistence/QuestStatus.swift                  // enum
  Services/ErrorPresenter.swift                  // @Observable error sink
  Services/SoundService.swift                    // protocol stub
  Services/RecapService.swift                    // protocol stub
  Common/Date+Relative.swift                     // "3h ago" formatting
  Resources/Assets.xcassets                      // colors
  Resources/Fonts/                               // Cinzel, Lora
QuestlogTests/
  QuestStatusTests.swift
  QuestTests.swift
  ObjectiveTests.swift
QuestlogUITests/
  AppLaunchTests.swift
```

Total estimate: **~600-900 LoC of Swift + ~50 LoC of tests**. Single-developer, single-evening to single-weekend effort once Xcode is installed.
