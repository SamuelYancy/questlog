import Foundation

struct RecapSnapshot: Sendable {
    let activeQuestCount: Int
    let lastOpenedAgo: String?
}

protocol RecapService: Sendable {
    func summarize(_ snapshot: RecapSnapshot) async -> String
}

struct StubRecapService: RecapService {
    func summarize(_ snapshot: RecapSnapshot) async -> String {
        let questPart = "\(snapshot.activeQuestCount) active quest\(snapshot.activeQuestCount == 1 ? "" : "s")"
        if let ago = snapshot.lastOpenedAgo {
            return "\(questPart) · last opened \(ago)"
        }
        return questPart
    }
}
