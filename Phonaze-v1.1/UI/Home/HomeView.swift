import SwiftUI

/// Main menu after a mode is chosen / connection is established (for Phonaze).
/// - Shows current interaction method
/// - Entry points to legacy tasks and the new Media Browsing Task
struct HomeView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @EnvironmentObject var gameState: GameState

    @State private var selectViewID = UUID()
    @State private var goMediaHome = false

    private var modeText: String {
        switch gameState.currentInteractionMethod {
        case .directTouch: return "Direct Touch"
        case .pinch:       return "Pinch"
        case .phonaze:     return "Phonaze (Gaze + iPhone)"
        case .none:        return "Not Selected"
        }
    }

    var body: some View {
        HStack(spacing: 40) {
            // Left spacer/illustration area (optional)
            VStack { Spacer() }
                .frame(minWidth: 140)
                .padding(.vertical, 40)

            // Main menu
            VStack(spacing: 22) {
                Text("Phonaze Menu")
                    .font(.title).bold()

                Text("(\(modeText))")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                // === New Media Browsing Task ===
                Button {
                    // For Phonaze, ensure the device is connected
                    if gameState.currentInteractionMethod == .phonaze, connectivity.isConnected == false {
                        // If not connected, push user back to ConnectionView
                        goMediaHome = false
                    } else {
                        goMediaHome = true
                    }
                } label: {
                    menuButtonLabel(
                        title: "Media Browsing Task",
                        subtitle: "Netflix-style home | local videos",
                        systemImage: "play.rectangle.on.rectangle",
                        tint: .red.opacity(0.85)
                    )
                }
                .buttonStyle(.plain)
                .navigationDestination(isPresented: $goMediaHome) {
                    // Temporary placeholder until MediaHomeView is added.
                    MediaHomeView()
                }

                // === Legacy Tasks (kept) ===
                NavigationLink(destination: SelectView().id(selectViewID)) {
                    menuButtonLabel(
                        title: "Panel Select Task",
                        subtitle: "Legacy selection game",
                        systemImage: "square.grid.4x3.fill",
                        tint: .blue.opacity(0.8)
                    )
                }
                .simultaneousGesture(TapGesture().onEnded { selectViewID = UUID() })

                NavigationLink(destination: ScrollViewGame()) {
                    menuButtonLabel(
                        title: "Number Scroll Task",
                        subtitle: "Legacy scrolling game",
                        systemImage: "number.circle",
                        tint: .green.opacity(0.8)
                    )
                }

                Divider().padding(.vertical, 6)

                Button {
                    // If Phonaze, gracefully disconnect then go back to Start
                    if gameState.currentInteractionMethod == .phonaze {
                        connectivity.disconnect()
                    }
                    gameState.shouldReturnToStart = true
                } label: {
                    menuButtonLabel(
                        title: "Select Mode Again",
                        subtitle: "Return to start and choose a mode",
                        systemImage: "arrow.uturn.backward.circle.fill",
                        tint: .gray.opacity(0.7)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(40)
        }
        .navigationTitle("Home")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            gameState.shouldReturnToStart = false
            gameState.resetGame()
        }
        .alert("Not Connected", isPresented: .constant(shouldWarnConnection)) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please connect your iPhone first to use the Phonaze mode.")
        }
    }

    private var shouldWarnConnection: Bool {
        gameState.currentInteractionMethod == .phonaze && connectivity.isConnected == false && goMediaHome == true
    }

    @ViewBuilder
    private func menuButtonLabel(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: 520)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Temporary placeholder view to keep build green
/// Replace this with the real MediaHomeView (UI/MediaBrowse/MediaHomeView.swift).
struct MediaHomePlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Media Home (Placeholder)").font(.title2).bold()
            Text("Add UI/MediaBrowse/MediaHomeView.swift and navigate here.")
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }
}
