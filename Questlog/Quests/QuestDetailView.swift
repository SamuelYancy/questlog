import SwiftUI
import SwiftData

struct QuestDetailView: View {
    @Bindable var quest: Quest
    @Environment(\.modelContext) private var modelContext
    @Environment(ErrorPresenter.self) private var errorPresenter

    @State private var showingObjectiveEditor = false
    @State private var showingQuestEditor = false

    private var sortedObjectives: [Objective] {
        quest.objectives.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            Section {
                if !quest.summary.isEmpty {
                    Text(quest.summary)
                        .font(Theme.Fonts.body(15))
                        .foregroundStyle(Theme.Colors.ink.opacity(0.85))
                        .listRowBackground(Theme.Colors.parchment)
                }
                StatusControls(quest: quest, save: save)
                    .listRowBackground(Theme.Colors.parchment)
            }

            Section {
                if sortedObjectives.isEmpty {
                    Text("No objectives yet. Tap + to chart your path.")
                        .font(Theme.Fonts.body(13))
                        .foregroundStyle(Theme.Colors.ink.opacity(0.6))
                        .listRowBackground(Theme.Colors.parchment)
                } else {
                    ForEach(sortedObjectives) { objective in
                        ObjectiveRow(objective: objective, onCommit: save)
                            .listRowBackground(Theme.Colors.parchment)
                    }
                    .onDelete(perform: deleteObjectives)
                }
            } header: {
                HStack {
                    Text("Objectives")
                        .font(Theme.Fonts.caption(11))
                        .foregroundStyle(Theme.Colors.ink.opacity(0.65))
                    Spacer()
                    Text(quest.progressLabel)
                        .font(Theme.Fonts.caption(11))
                        .foregroundStyle(Theme.Colors.questGold)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.parchment.ignoresSafeArea())
        .navigationTitle(quest.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingObjectiveEditor = true
                } label: {
                    Label("Add Objective", systemImage: "plus")
                        .foregroundStyle(Theme.Colors.questGold)
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("Edit Quest", systemImage: "pencil") {
                    showingQuestEditor = true
                }
            }
        }
        .sheet(isPresented: $showingObjectiveEditor) {
            ObjectiveEditor(quest: quest)
        }
        .sheet(isPresented: $showingQuestEditor) {
            QuestEditorView(mode: .edit(quest))
        }
        .onAppear {
            quest.markOpened()
            save()
        }
    }

    private func deleteObjectives(at offsets: IndexSet) {
        let toDelete = offsets.map { sortedObjectives[$0] }
        for obj in toDelete {
            modelContext.delete(obj)
        }
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorPresenter.report(title: "Couldn’t save changes", error: error)
        }
    }
}

private struct StatusControls: View {
    @Bindable var quest: Quest
    let save: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            switch quest.status {
            case .active:
                actionButton("Complete", systemImage: "checkmark.seal", tint: Theme.Colors.questGold) {
                    quest.transition(to: .completed); save()
                }
                actionButton("Abandon", systemImage: "xmark.circle", tint: Theme.Colors.abandonedGray) {
                    quest.transition(to: .abandoned); save()
                }
            case .completed:
                actionButton("Reopen", systemImage: "arrow.uturn.backward", tint: Theme.Colors.questGold) {
                    quest.transition(to: .active); save()
                }
            case .abandoned:
                actionButton("Restore", systemImage: "arrow.uturn.backward", tint: Theme.Colors.questGold) {
                    quest.transition(to: .active); save()
                }
            }
        }
    }

    private func actionButton(_ title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Theme.Fonts.caption(12))
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .frame(maxWidth: .infinity)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: Theme.Radius.m))
                .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
    }
}
