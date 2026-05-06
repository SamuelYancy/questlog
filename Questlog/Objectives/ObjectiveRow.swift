import SwiftUI

struct ObjectiveRow: View {
    @Bindable var objective: Objective
    let onCommit: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Button {
                objective.toggle()
                onCommit()
            } label: {
                Image(systemName: objective.isComplete ? "checkmark.seal.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(objective.isComplete ? Theme.Colors.questGold : Theme.Colors.ink.opacity(0.45))
            }
            .buttonStyle(.plain)

            TextField("Objective", text: $objective.title)
                .font(Theme.Fonts.body(15))
                .foregroundStyle(Theme.Colors.ink)
                .strikethrough(objective.isComplete, color: Theme.Colors.ink.opacity(0.6))
                .onSubmit(onCommit)
        }
        .padding(.vertical, 2)
    }
}
