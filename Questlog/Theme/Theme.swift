import SwiftUI

enum Theme {
    enum Colors {
        static let parchment = Color("Parchment")
        static let ink = Color("Ink")
        static let questGold = Color("QuestGold")
        static let abandonedGray = Color("AbandonedGray")
    }

    enum Fonts {
        static func display(_ size: CGFloat) -> Font {
            .system(size: size, weight: .semibold, design: .serif)
        }

        static func body(_ size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .serif)
        }

        static func caption(_ size: CGFloat) -> Font {
            .system(size: size, weight: .medium, design: .serif).smallCaps()
        }
    }

    enum Sounds {
        static let questAccepted = "quest_accepted"
        static let objectiveComplete = "objective_complete"
        static let questComplete = "quest_complete"
    }

    enum Spacing {
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let s: CGFloat = 6
        static let m: CGFloat = 12
    }
}
