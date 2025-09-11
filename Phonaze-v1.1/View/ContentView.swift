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
                        
                        // 실험 설정 업데이트
                        var cfg = ExperimentConfig.default(participantID: "P\(Int(Date().timeIntervalSince1970))")
                        cfg.platform = platform.rawValue
                        cfg.interactionMode = mode.rawValue
                        cfg.taskType = "browsing"

                        // 실험 세션 재생성 (새로운 설정으로)
                        let session = ExperimentSession(
                            config: cfg,
                            focusTracker: focusTracker,
                            sender: { msg in connectivity.sendRaw(msg) }
                        )
                        
                        // ConnectivityManager에 연결
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
                    PlatformWebView(platform: p, onBack: { route = .platformPicker })
                        // ✅ InteractionOverlay 완전 제거 - Vision Pro 네이티브 입력만 사용
                        .transition(.opacity.combined(with: .scale))
                }

            case .selectTask:
                SelectGameView(onBack: { route = .start })
                    .overlay(modeBadge, alignment: .topTrailing)

            case .scrollTask:
                ScrollGameView(onBack: { route = .start })
                    .overlay(modeBadge, alignment: .topTrailing)

            case .connection:
                ConnectionView(onDone: { route = .start })
                    .overlay(backButton { route = .start }, alignment: .topLeading)
                    
            case .about:
                AboutLogsView(onBack: { route = .start })
            }
        }
        .task { connectivity.start() }
        .onAppear { connectivity.sendMode(mode) }
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
