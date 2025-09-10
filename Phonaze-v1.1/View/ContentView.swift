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
    @StateObject private var focusTracker = FocusTracker()
    @State private var experimentSession: ExperimentSession?

    enum Route: Hashable {
        case start, disclaimer, platformPicker, web, selectTask, scrollTask, connection
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
                    onOpenConnection:     { route = .connection }
                )
                .environmentObject(connectivity)
                .onChange(of: mode) { _, new in
                    connectivity.sendMode(new)
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
                        experimentSession = session
                        connectivity.setExperimentSession(session)
                        connectivity.setFocusTracker(focusTracker)
                        session.startOrContinue()

                        connectivity.sendMode(mode)
                        route = .web
                    },
                    onBack: { route = .disclaimer }
                )
                .overlay(backButton { route = .disclaimer }, alignment: .topLeading)

            case .web:
                if let p = selectedPlatform {
                    PlatformWebView(platform: p)
                        .environmentObject(connectivity)
                        // ✅ [핵심 수정] InteractionOverlay 제거.
                        // 이제 WebView가 Vision Pro의 네이티브 입력을 직접 받습니다.
                        // .overlay(InteractionOverlay(mode: mode))
                        .overlay(backButton { route = .platformPicker }, alignment: .topLeading)
                        .transition(.opacity.combined(with: .scale))
                }

            case .selectTask:
                SelectGameView(onBack: { route = .start }) // Back button 추가
                    .environmentObject(connectivity)
                    .overlay(modeBadge, alignment: .topTrailing)

            case .scrollTask:
                ScrollGameView(onBack: { route = .start }) // Back button 추가
                    .environmentObject(connectivity)
                    .overlay(modeBadge, alignment: .topTrailing)

            case .connection:
                ConnectionView(onDone: { route = .start })
                    .environmentObject(connectivity)
                    .overlay(backButton { route = .start }, alignment: .topLeading)
            }
        }
        .task { connectivity.start() }
        .onAppear { connectivity.sendMode(mode) } // 초기 모드 전파
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
