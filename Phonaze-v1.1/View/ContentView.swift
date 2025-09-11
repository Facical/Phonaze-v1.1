// Phonaze-v1.1/View/ContentView.swift

import SwiftUI

struct ContentView: View {
    // 라우팅
    @State private var route: Route = .start
    @State private var selectedPlatform: StreamingPlatform?

    // 모드
    @State private var mode: InteractionMode = .directTouch

    // 의존
    @EnvironmentObject private var connectivity: ConnectivityManager
    @EnvironmentObject private var focusTracker: FocusTracker
    @EnvironmentObject private var experimentSession: ExperimentSession
    
    @EnvironmentObject private var enhancedLogger: EnhancedExperimentLogger  // 추가
    @StateObject private var unintendedTracker = UnintendedSelectionTracker()  // 추가

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
                    onOpenAbout:         { route = .about }
                )
                .onChange(of: mode) { _, new in
                    connectivity.sendMode(new)
                    setCurrentInteractionMode(new) // 추가: 모드 저장
                }

            case .disclaimer:
                ResearchDisclaimerView(onConfirm: {
                    route = .platformPicker
                }, onCancel: {
                    route = .start
                })
                .overlay(backButton { route = .start }, alignment: .topLeading)

            case .platformPicker:
                PlatformPickerView(
                    onPick: { platform in
                        selectedPlatform = platform
                        
                        var cfg = ExperimentConfig.default(participantID: "P\(Int(Date().timeIntervalSince1970))")
                        cfg.platform = platform.rawValue
                        cfg.interactionMode = mode.rawValue
                        cfg.taskType = "browsing"

                        let session = ExperimentSession(
                            config: cfg,
                            focusTracker: focusTracker,
                            sender: { msg in connectivity.sendRaw(msg) }
                        )
                        
                        connectivity.setExperimentSession(session)
                        session.startOrContinue()
                        connectivity.sendMode(mode)
                        
                        route = .web
                    },
                    onBack: { route = .disclaimer }
                )
                .overlay(backButton { route = .disclaimer }, alignment: .topLeading)

            case .web:
                if let p = selectedPlatform {
                    PlatformWebViewEnhanced(
                        platform: p,
                        onBack: { route = .platformPicker },
                        onSessionComplete: { sessionData in
                            // 브라우징 세션 데이터 로깅
                            let metrics = EnhancedExperimentLogger.BrowsingMetrics(
                                platform: sessionData.platform,
                                interactionMode: mode.rawValue,
                                sessionDuration: sessionData.totalDuration,
                                pagesVisited: sessionData.pagesVisited,
                                totalClicks: sessionData.totalInteractions,
                                totalScrolls: 0,
                                unintendedSelections: sessionData.unintendedSelections,
                                videoPlays: 0,
                                searchQueries: 0,
                                navigationActions: sessionData.pagesVisited
                            )
                            enhancedLogger.logBrowsingMetrics(metrics)
                        }
                    )
                    .environmentObject(unintendedTracker)
                    .transition(.opacity.combined(with: .scale))
                }

            case .selectTask:
                SelectGameView(onBack: { route = .start })
                    .environmentObject(enhancedLogger)
                    .environmentObject(unintendedTracker)
                    .overlay(modeBadge, alignment: .topTrailing)

            case .scrollTask:
                ScrollGameView(onBack: { route = .start })
                    .environmentObject(enhancedLogger)
                    .environmentObject(unintendedTracker)
                    .overlay(modeBadge, alignment: .topTrailing)

            case .connection:
                ConnectionView(onDone: { route = .start })
                    .overlay(backButton { route = .start }, alignment: .topLeading)
                    
            case .about:
                AboutLogsView(onBack: { route = .start })
            }
        }
        .environmentObject(unintendedTracker)
        .environmentObject(enhancedLogger)
        .task { connectivity.start() }
        .onAppear {
            connectivity.sendMode(mode)
            setCurrentInteractionMode(mode) // 추가: 초기 모드 저장
        }
    }

    // MARK: - UI helpers
    private func backButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label("Back", systemImage: "chevron.left")
                .font(.headline)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(16)
    }

    private var modeBadge: some View {
        Text(mode == .phonaze ? "Phonaze (iPhone)" :
             mode == .pinch   ? "Pinch" : "Direct Touch")
            .font(.footnote)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(16)
    }
}
