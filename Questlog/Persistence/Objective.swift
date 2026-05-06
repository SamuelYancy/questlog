import Foundation
import SwiftData

@Model
final class Objective {
    var title: String
    var isComplete: Bool
    var order: Int
    var quest: Quest?

    init(title: String, isComplete: Bool = false, order: Int = 0, quest: Quest? = nil) {
        self.title = title
        self.isComplete = isComplete
        self.order = order
        self.quest = quest
    }

    func toggle() {
        isComplete.toggle()
    }
}
