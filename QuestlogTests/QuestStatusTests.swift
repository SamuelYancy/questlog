import Testing
@testable import Questlog

@Suite("QuestStatus transitions")
struct QuestStatusTests {

    @Test("active can transition to completed and abandoned")
    func activeAllowedTransitions() {
        #expect(QuestStatus.active.canTransition(to: .completed))
        #expect(QuestStatus.active.canTransition(to: .abandoned))
    }

    @Test("self-transition is rejected")
    func selfTransitionRejected() {
        for status in QuestStatus.allCases {
            #expect(!status.canTransition(to: status))
        }
    }

    @Test("completed and abandoned can both reopen to active")
    func reopenAllowed() {
        #expect(QuestStatus.completed.canTransition(to: .active))
        #expect(QuestStatus.abandoned.canTransition(to: .active))
    }

    @Test("completed cannot directly become abandoned")
    func illegalTerminalCrosswiring() {
        #expect(!QuestStatus.completed.canTransition(to: .abandoned))
        #expect(!QuestStatus.abandoned.canTransition(to: .completed))
    }
}
