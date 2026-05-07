import SwiftUI
import SwiftData

struct QuestListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ErrorPresenter.self) private var errorPresenter

    @State private var statusFilter: QuestStatus = .active
    @State private var showingNewQuest = false

    var body: some View {
        NavigationStack {
            Group {
                switch statusFilter {
                case .active:
                    QuestListContent(filter: .active, modelContext: modelContext, errorPresenter: errorPresenter)
                case .completed:
                    QuestListContent(filter: .completed, modelContext: modelContext, errorPresenter: errorPresenter)
                case .abandoned:
                    QuestListContent(filter: .abandoned, modelContext: modelContext, errorPresenter: errorPresenter)
                }
            }
            .background(Theme.Colors.parchment.ignoresSafeArea())
            .navigationTitle("Questlog")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    KnightAvatarView(size: 32)
                }
                #else
                ToolbarItem(placement: .navigation) {
                    KnightAvatarView(size: 28)
                }
                #endif
                ToolbarItem(placement: .principal) {
                    Picker("Filter", selection: $statusFilter) {
                        ForEach(QuestStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 320)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewQuest = true
                    } label: {
                        Label("New Quest", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.questGold)
                    }
                }
            }
            .sheet(isPresented: $showingNewQuest) {
                QuestEditorView(mode: .create)
            }
        }
    }
}

private struct QuestListContent: View {
    @Query private var quests: [Quest]
    let modelContext: ModelContext
    let errorPresenter: ErrorPresenter

    init(filter: QuestStatus, modelContext: ModelContext, errorPresenter: ErrorPresenter) {
        let raw = filter.rawValue
        _quests = Query(
            filter: #Predicate<Quest> { $0.statusRaw == raw },
            sort: \Quest.lastOpenedAt,
            order: .reverse
        )
        self.modelContext = modelContext
        self.errorPresenter = errorPresenter
    }

    var body: some View {
        if quests.isEmpty {
            EmptyQuestsView()
        } else {
            List {
                ForEach(quests) { quest in
                    NavigationLink(value: quest) {
                        QuestRowView(quest: quest)
                    }
                    .listRowBackground(Theme.Colors.parchment)
                }
                .onDelete(perform: delete)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationDestination(for: Quest.self) { quest in
                QuestDetailView(quest: quest)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(quests[index])
        }
        do {
            try modelContext.save()
        } catch {
            errorPresenter.report(title: "Couldn’t delete quest", error: error)
        }
    }
}

private struct EmptyQuestsView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "scroll")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.Colors.questGold.opacity(0.7))
            Text("No active quests.")
                .font(Theme.Fonts.display(20))
                .foregroundStyle(Theme.Colors.ink)
            Text("Begin a new adventure.")
                .font(Theme.Fonts.body(15))
                .foregroundStyle(Theme.Colors.ink.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.xl)
    }
}
