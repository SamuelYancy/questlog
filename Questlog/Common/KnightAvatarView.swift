import SwiftUI

struct KnightAvatarView: View {
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.parchment)
                .overlay(Circle().stroke(Theme.Colors.questGold, lineWidth: 1.5))
                .shadow(color: Theme.Colors.ink.opacity(0.15), radius: 1, x: 0, y: 1)

            Capsule()
                .fill(Color.red.opacity(0.78))
                .frame(width: size * 0.13, height: size * 0.32)
                .rotationEffect(.degrees(-18))
                .offset(x: -size * 0.04, y: -size * 0.46)

            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.88), Color(white: 0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.7, height: size * 0.78)
                    .overlay(Capsule().stroke(Theme.Colors.ink.opacity(0.55), lineWidth: 1))

                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.Colors.ink)
                    .frame(width: size * 0.5, height: size * 0.08)
                    .offset(y: -size * 0.06)

                HStack(spacing: size * 0.14) {
                    Circle().fill(Theme.Colors.questGold).frame(width: size * 0.055, height: size * 0.055)
                    Circle().fill(Theme.Colors.questGold).frame(width: size * 0.055, height: size * 0.055)
                }
                .offset(y: -size * 0.06)

                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.Colors.ink.opacity(0.4))
                    .frame(width: size * 0.36, height: size * 0.025)
                    .offset(y: size * 0.18)
            }
            .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Knight avatar")
    }
}

#Preview {
    HStack(spacing: 16) {
        KnightAvatarView(size: 24)
        KnightAvatarView(size: 36)
        KnightAvatarView(size: 64)
        KnightAvatarView(size: 96)
    }
    .padding()
    .background(Theme.Colors.parchment)
}
