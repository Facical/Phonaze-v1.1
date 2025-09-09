import SwiftUI

/// Entry screen: choose interaction method.
/// - Direct Touch: use visionOS default pinch/tap
/// - Pinch: alias of direct touch (kept for legacy menu parity)
/// - Phonaze (Gaze + iPhone): go to ConnectionView first
struct StartView: View {
    @EnvironmentObject var gameState: GameState

    @State private var goHome = false
    @State private var goConnection = false
    @State private var showInfo = false

    var body: some View {
        VStack(spacing: 28) {
            HStack {
                Text("Select Interaction Mode")
                    .font(.largeTitle).bold()
                Spacer()
                Button {
                    showInfo.toggle()
                } label: {
                    Label("Info", systemImage: "info.circle")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                .accessibilityLabel("Interaction modes info")
            }
            .padding(.horizontal)

            // 1) Direct Touch
            Button {
                gameState.currentInteractionMethod = .directTouch
                goHome = true
            } label: {
                modeButtonLabel(title: "Direct Touch",
                                subtitle: "Use visionOS gaze + hand tap",
                                systemImage: "hand.point.up.left.fill",
                                color: .orange)
            }

            // 2) Pinch (kept for legacy parity)
            Button {
                gameState.currentInteractionMethod = .pinch
                goHome = true
            } label: {
                modeButtonLabel(title: "Pinch",
                                subtitle: "Gaze to point, pinch to select",
                                systemImage: "hand.pinch.fill",
                                color: .purple)
            }

            // 3) Phonaze
            Button {
                gameState.currentInteractionMethod = .phonaze
                goConnection = true
            } label: {
                modeButtonLabel(title: "Phonaze (Gaze + iPhone)",
                                subtitle: "Gaze to point, iPhone tap to confirm",
                                systemImage: "iphone.and.arrow.forward",
                                color: .cyan)
            }

            Spacer(minLength: 16)
        }
        .padding(36)
        // Navigation
        .navigationDestination(isPresented: $goHome) {
            HomeView()
        }
        .navigationDestination(isPresented: $goConnection) {
            ConnectionView()
        }
        // Info
        .sheet(isPresented: $showInfo) {
            ModeSelectionInfoView()
                .presentationDetents([.medium, .large])
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func modeButtonLabel(title: String, subtitle: String, systemImage: String, color: Color) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: systemImage)
                .font(.title)
                .frame(width: 44, height: 44)
                .foregroundStyle(.white)
                .background(color.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title2).bold()
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .frame(maxWidth: 520)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
