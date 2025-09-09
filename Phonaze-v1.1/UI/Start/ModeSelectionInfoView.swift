import SwiftUI

/// Brief explanation for each mode and study notes (English-only strings)
struct ModeSelectionInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("About Interaction Modes")
                    .font(.title).bold()

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Direct Touch").font(.headline)
                        Text("Use built-in visionOS gaze + hand tap. Point with your eyes; tap with your fingers to select.")
                            .foregroundStyle(.secondary)
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pinch").font(.headline)
                        Text("Functionally similar to Direct Touch; kept as a separate menu for legacy tasks.")
                            .foregroundStyle(.secondary)
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phonaze (Gaze + iPhone)").font(.headline)
                        Text("Eyes for pointing, iPhone tap to confirm. iPhone can also provide horizontal/vertical scrolling during browsing tasks.")
                            .foregroundStyle(.secondary)
                    }
                }

                Divider().padding(.vertical, 8)

                Text("Study Notes").font(.title3).bold()
                VStack(alignment: .leading, spacing: 10) {
                    Label("All UI strings are in English.", systemImage: "character.book.closed")
                    Label("Browsing Task measures time, accuracy, and error rate.", systemImage: "chart.bar.doc.horizontal")
                    Label("Video playback uses local files only (no network).", systemImage: "externaldrive")
                    Label("Gaze highlights a card; selection is confirmed by iPhone tap.", systemImage: "eye")
                }
                .foregroundStyle(.secondary)
            }
            .padding(24)
        }
    }
}
