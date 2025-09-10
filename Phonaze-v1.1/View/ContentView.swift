import SwiftUI

/// 앱 루트 컨테이너: Start → Disclaimer → PlatformPicker → Web
struct ContentView: View {
    // 라우팅 상태
    @State private var route: Route = .start
    @State private var selectedPlatform: StreamingPlatform?

    // Dependencies (connection/focus/session)
    @EnvironmentObject private var connectivity: ConnectivityManager
    @StateObject private var focusTracker = FocusTracker()
    @State private var experimentSession: ExperimentSession?

    enum Route: Hashable {
        case start
        case disclaimer
        case platformPicker
        case web
        case selectTask
        case scrollTask
        case connection
    }

    var body: some View {
        ZStack {
            switch route {
            case .start:
                StartView(
                    onSelectMediaBrowsing: { route = .disclaimer },
                    onOpenScrollTask:     { route = .scrollTask },
                    onOpenSelectTask:     { route = .selectTask },
                    onOpenConnection:     { route = .connection }
                )
                .environmentObject(connectivity)

            case .disclaimer:
                ResearchDisclaimerView(onConfirm: {
                    route = .platformPicker
                })

            case .platformPicker:
                PlatformPickerView(
                    onPick: { platform in
                        selectedPlatform = platform

                        // Create session
                        var cfg = ExperimentConfig.default(participantID: "P\(Int(Date().timeIntervalSince1970))")
                        cfg.platform = platform.rawValue
                        let session = ExperimentSession(
                            config: cfg,
                            focusTracker: focusTracker,
                            sender: { msg in connectivity.sendRaw(msg) }
                        )
                        experimentSession = session
                        connectivity.setExperimentSession(session)
                        connectivity.setFocusTracker(focusTracker)
                        session.startOrContinue()

                        route = .web
                    },
                    onBack: {
                        route = .disclaimer
                    }
                )

            case .web:
                if let p = selectedPlatform {
                    PlatformWebView(platform: p)
                        .environmentObject(connectivity)
                        .overlay(InteractionOverlay(mode: .directTouch)) // Start에서 모드 선택 후 주입해도 됨
                        .transition(.opacity.combined(with: .scale))
                } else {
                    PlatformPickerView(onPick: { p in
                        selectedPlatform = p; route = .web
                    }, onBack: { route = .disclaimer })
                }

            case .selectTask:
                // Quantitative task (keep existing SelectView)
                SelectGameView()
                    .environmentObject(connectivity)

            case .scrollTask:
                ScrollGameView()
                    .environmentObject(connectivity)

            case .connection:
                ConnectionView(onDone: { route = .start })
                    .environmentObject(connectivity)
            }
        }
        .task { connectivity.start() } // Start advertisement when app starts
    }
}

