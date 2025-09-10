import SwiftUI

struct ContentView: View {
    @State private var route: Route = .start
    @State private var selectedPlatform: StreamingPlatform?
    @State private var mode: InteractionMode = .directTouch

    @EnvironmentObject private var connectivity: ConnectivityManager
    @EnvironmentObject private var focusTracker: FocusTracker
    @EnvironmentObject private var experimentSession: ExperimentSession

    enum Route: Hashable {
        case start, disclaimer, platformPicker, web, selectTask, scrollTask, connection, about
    }

    var body: some View {
        ZStack {
            switch route {
            case .start:
                StartView(
                    mode: $mode,
                    onSelectMediaBrowsing: { route = .disclaimer },
                    onOpenScrollTask:     { route = .scrollTask },
                    onOpenSelectTask:     { route = .selectTask },
                    onOpenConnection:     { route = .connection },
                    onOpenAbout:          { route = .about }
                )
                .environmentObject(connectivity)
                .onChange(of: mode) { _, new in
                    connectivity.sendMode(new)
                }

            case .disclaimer:
                VStack(spacing: 0) {
                    NavigationHeader(
                        title: "Research Disclaimer",
                        showBackButton: true,
                        onBack: { route = .start }
                    )
                    ResearchDisclaimerView(
                        onConfirm: { route = .platformPicker },
                        onCancel: { route = .start }
                    )
                }
                .background(Color.black.opacity(0.9))

            case .platformPicker:
                VStack(spacing: 0) {
                    NavigationHeader(
                        title: "Select Platform",
                        showBackButton: true,
                        onBack: { route = .disclaimer }
                    )
                    PlatformPickerView(
                        onPick: { platform in
                            selectedPlatform = platform
                            var cfg = experimentSession.config
                            cfg.platform = platform.rawValue
                            cfg.interactionMode = mode.rawValue
                            cfg.taskType = "mediaBrowsing"
                            experimentSession.startOrContinue()
                            connectivity.sendMode(mode)
                            route = .web
                        }
                    )
                }

            case .web:
                if let p = selectedPlatform {
                    ZStack {
                        PlatformWebView(platform: p)
                            .environmentObject(connectivity)
                            .environmentObject(focusTracker)
                            .environmentObject(experimentSession)
                            .overlay(InteractionOverlay(mode: mode))
                        
                        // Web view needs floating header for better visibility
                        VStack {
                            HStack {
                                Button(action: { route = .platformPicker }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Back")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.5))
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(20)
                                }
                                
                                Spacer()
                                
                                // Mode badge
                                Text(mode == .phonaze ? "Phonaze" :
                                     mode == .pinch   ? "Pinch" : "Direct Touch")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.5))
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(20)
                            }
                            .padding(16)
                            
                            Spacer()
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                }

            case .selectTask:
                SelectGameView(onBack: { route = .start })
                    .environmentObject(connectivity)

            case .scrollTask:
                ScrollGameView(onBack: { route = .start })
                    .environmentObject(connectivity)

            case .connection:
                ConnectionView(onDone: { route = .start })
                    .environmentObject(connectivity)
                    
            case .about:
                AboutLogsView(onBack: { route = .start })
                    .environmentObject(experimentSession)
                    .environmentObject(connectivity)
            }
        }
        .task { connectivity.start() }
        .onAppear { connectivity.sendMode(mode) }
    }
}
