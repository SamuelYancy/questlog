import SwiftUI
import SwiftData

struct ObjectiveEditor: View {
    let quest: Quest
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ErrorPresenter.self) private var errorPresenter

    @State private var title: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Objective", text: $title)
                    .font(Theme.Fonts.body(16))
            }
            .navigationTitle("New Objective")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func add() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let objective = Objective(title: trimmed, order: quest.nextObjectiveOrder(), quest: quest)
        modelContext.insert(objective)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorPresenter.report(title: "Couldn’t add objective", error: error)
        }
    }
}
