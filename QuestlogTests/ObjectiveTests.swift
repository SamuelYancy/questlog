import Foundation
import SwiftData
import Testing
@testable import Questlog

@Suite("Objective model behavior")
struct ObjectiveTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Quest.self, Objective.self, configurations: config)
        return ModelContext(container)
    }

    @Test("nextObjectiveOrder hands out increasing values")
    func ordersIncrease() throws {
        let context = try makeContext()
        let quest = Quest(title: "Map the Caverns")
        context.insert(quest)

        let a = Objective(title: "Find the entrance", order: quest.nextObjectiveOrder(), quest: quest)
        context.insert(a)
        let b = Objective(title: "Light the torches", order: quest.nextObjectiveOrder(), quest: quest)
        context.insert(b)
        let c = Objective(title: "Mark the path", order: quest.nextObjectiveOrder(), quest: quest)
        context.insert(c)

        try context.save()

        let sorted = quest.objectives.sorted { $0.order < $1.order }
        #expect(sorted.map(\.title) == ["Find the entrance", "Light the torches", "Mark the path"])
    }

    @Test("cascade delete removes objectives when quest is deleted")
    func cascadeDelete() throws {
        let context = try makeContext()
        let quest = Quest(title: "Hunt the Stag")
        context.insert(quest)
        let obj = Objective(title: "Track the prints", order: 0, quest: quest)
        context.insert(obj)
        try context.save()

        context.delete(quest)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Objective>())
        #expect(remaining.isEmpty)
    }

    @Test("toggle flips completion")
    func toggleFlipsCompletion() throws {
        let obj = Objective(title: "Drink the potion")
        #expect(!obj.isComplete)
        obj.toggle()
        #expect(obj.isComplete)
        obj.toggle()
        #expect(!obj.isComplete)
    }

    @Test("completedObjectiveCount and progressLabel reflect state")
    func progressLabel() throws {
        let context = try makeContext()
        let quest = Quest(title: "Brew the Elixir")
        context.insert(quest)
        for i in 0..<3 {
            let obj = Objective(title: "Step \(i)", order: i, quest: quest)
            context.insert(obj)
        }
        try context.save()

        quest.objectives.first(where: { $0.order == 0 })?.isComplete = true
        try context.save()

        #expect(quest.completedObjectiveCount == 1)
        #expect(quest.totalObjectiveCount == 3)
        #expect(quest.progressLabel == "1/3")
    }
}
