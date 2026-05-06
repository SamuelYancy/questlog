import SwiftUI
import SwiftData

struct QuestEditorView: View {
    enum Mode {
        case create
        case edit(Quest)
    }

    let mode: Mode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ErrorPresenter.self) private var errorPresenter

    @State private var title: String = ""
    @State private var summary: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quest") {
                    TextField("Title", text: $title)
                        .font(Theme.Fonts.body(16))
                    TextField("Summary", text: $summary, axis: .vertical)
                        .lineLimit(3...6)
                        .font(Theme.Fonts.body(14))
                }
            }
            .navigationTitle(isEditing ? "Edit Quest" : "New Quest")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Begin") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private func loadIfEditing() {
        if case .edit(let quest) = mode {
            title = quest.title
            summary = quest.summary
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        switch mode {
        case .create:
            let quest = Quest(title: trimmedTitle, summary: trimmedSummary)
            modelContext.insert(quest)
        case .edit(let quest):
            quest.title = trimmedTitle
            quest.summary = trimmedSummary
        }
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorPresenter.report(title: "Couldn’t save quest", error: error)
        }
    }
}
