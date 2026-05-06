import Foundation
import SwiftUI

enum QuestStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case completed
    case abandoned

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: "Active"
        case .completed: "Completed"
        case .abandoned: "Abandoned"
        }
    }

    var pillColor: Color {
        switch self {
        case .active: Theme.Colors.questGold
        case .completed: Theme.Colors.questGold.opacity(0.55)
        case .abandoned: Theme.Colors.abandonedGray
        }
    }

    func canTransition(to next: QuestStatus) -> Bool {
        switch (self, next) {
        case (.active, .completed),
             (.active, .abandoned),
             (.completed, .active),
             (.abandoned, .active):
            return true
        case (let a, let b) where a == b:
            return false
        default:
            return false
        }
    }
}
