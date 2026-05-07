import SwiftUI
import SwiftData

@main
struct QuestlogApp: App {
    @State private var errorPresenter = ErrorPresenter()
    private let soundService: any SoundService = NoopSoundService()
    private let recapService: any RecapService = StubRecapService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(errorPresenter)
                .alertBinding(errorPresenter: errorPresenter)
                .tint(Theme.Colors.questGold)
        }
        .modelContainer(for: [Quest.self, Objective.self])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        QuestListView()
            .task { seedIfNeeded() }
    }

    private func seedIfNeeded() {
        let count = (try? modelContext.fetchCount(FetchDescriptor<Quest>())) ?? 0
        guard count == 0 else { return }
        modelContext.insert(Quest(title: "Build app for iphone13 pro"))
        try? modelContext.save()
    }
}

private extension View {
    func alertBinding(errorPresenter: ErrorPresenter) -> some View {
        modifier(ErrorPresenterAlertModifier(presenter: errorPresenter))
    }
}

private struct ErrorPresenterAlertModifier: ViewModifier {
    @Bindable var presenter: ErrorPresenter

    func body(content: Content) -> some View {
        content.alert(
            presenter.currentError?.title ?? "Something went wrong",
            isPresented: Binding(
                get: { presenter.currentError != nil },
                set: { isPresented in if !isPresented { presenter.dismiss() } }
            ),
            presenting: presenter.currentError
        ) { _ in
            Button("OK", role: .cancel) { presenter.dismiss() }
        } message: { error in
            Text(error.message)
        }
    }
}
