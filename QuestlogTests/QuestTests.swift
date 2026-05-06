import Foundation
import SwiftData
import Testing
@testable import Questlog

@Suite("Quest model behavior")
struct QuestTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Quest.self, Objective.self, configurations: config)
        return ModelContext(container)
    }

    @Test("markOpened updates lastOpenedAt")
    func markOpenedUpdatesTimestamp() throws {
        let context = try makeContext()
        let initial = Date(timeIntervalSince1970: 0)
        let quest = Quest(title: "Slay the Hydra", lastOpenedAt: initial)
        context.insert(quest)

        let later = Date(timeIntervalSince1970: 10_000)
        quest.markOpened(now: later)

        #expect(quest.lastOpenedAt == later)
    }

    @Test("transition to completed sets completedAt")
    func completionStampsCompletedAt() throws {
        let context = try makeContext()
        let quest = Quest(title: "Forge the Blade")
        context.insert(quest)

        let when = Date(timeIntervalSince1970: 12_345)
        let ok = quest.transition(to: .completed, now: when)

        #expect(ok)
        #expect(quest.status == .completed)
        #expect(quest.completedAt == when)
    }

    @Test("reopening a completed quest clears completedAt")
    func reopeningClearsCompletion() throws {
        let context = try makeContext()
        let quest = Quest(title: "Tame the Beast")
        context.insert(quest)

        _ = quest.transition(to: .completed)
        #expect(quest.completedAt != nil)

        _ = quest.transition(to: .active)
        #expect(quest.status == .active)
        #expect(quest.completedAt == nil)
    }

    @Test("illegal transition is a no-op")
    func illegalTransitionNoOp() throws {
        let context = try makeContext()
        let quest = Quest(title: "Cross the Mountain")
        context.insert(quest)
        _ = quest.transition(to: .completed)

        let ok = quest.transition(to: .abandoned)
        #expect(!ok)
        #expect(quest.status == .completed)
    }
}
