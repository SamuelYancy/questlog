import Foundation
import SwiftData

@Model
final class Quest {
    var title: String
    var summary: String
    var statusRaw: String
    var createdAt: Date
    var completedAt: Date?
    var lastOpenedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Objective.quest)
    var objectives: [Objective] = []

    init(
        title: String,
        summary: String = "",
        status: QuestStatus = .active,
        createdAt: Date = .now,
        lastOpenedAt: Date = .now
    ) {
        self.title = title
        self.summary = summary
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
        self.completedAt = nil
    }

    var status: QuestStatus {
        get { QuestStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var completedObjectiveCount: Int {
        objectives.lazy.filter(\.isComplete).count
    }

    var totalObjectiveCount: Int { objectives.count }

    var progressLabel: String { "\(completedObjectiveCount)/\(totalObjectiveCount)" }

    func markOpened(now: Date = .now) {
        lastOpenedAt = now
    }

    @discardableResult
    func transition(to next: QuestStatus, now: Date = .now) -> Bool {
        guard status.canTransition(to: next) else { return false }
        status = next
        switch next {
        case .completed:
            completedAt = now
        case .active, .abandoned:
            completedAt = nil
        }
        return true
    }

    func nextObjectiveOrder() -> Int {
        (objectives.map(\.order).max() ?? -1) + 1
    }
}
