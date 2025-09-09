import SwiftUI

/// Top HUD: shows connection, last focused item, and active section.
/// (Minimal; can be extended to show target/score from ExperimentSession later.)
struct ExperimentHUD: View {
    let title: String
    let connected: Bool
    let focusedTitle: String
    let sectionTitle: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                HStack(spacing: 8) {
                    Circle()
                        .fill(connected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text(connected ? "Connected" : "Not Connected")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 18) {
                Label { Text(sectionTitle) } icon: { Image(systemName: "square.stack.3d.down.dottedline") }
                Label { Text(focusedTitle) } icon: { Image(systemName: "eye") }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider().opacity(0.25)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .background(.thinMaterial) // subtle bar
    }
}
