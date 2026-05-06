import SwiftUI

struct QuestRowView: View {
    let quest: Quest

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s / 2) {
                Text(quest.title)
                    .font(Theme.Fonts.display(18))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(2)

                if !quest.summary.isEmpty {
                    Text(quest.summary)
                        .font(Theme.Fonts.body(13))
                        .foregroundStyle(Theme.Colors.ink.opacity(0.7))
                        .lineLimit(1)
                }

                HStack(spacing: Theme.Spacing.s) {
                    StatusPill(status: quest.status)
                    Text(quest.progressLabel + " objectives")
                        .font(Theme.Fonts.caption(11))
                        .foregroundStyle(Theme.Colors.ink.opacity(0.65))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Theme.Spacing.s / 2)
    }
}

struct StatusPill: View {
    let status: QuestStatus

    var body: some View {
        Text(status.displayName.uppercased())
            .font(Theme.Fonts.caption(10))
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, 3)
            .background(status.pillColor.opacity(0.22), in: Capsule())
            .foregroundStyle(status.pillColor)
            .overlay(
                Capsule().stroke(status.pillColor.opacity(0.55), lineWidth: 0.5)
            )
    }
}
