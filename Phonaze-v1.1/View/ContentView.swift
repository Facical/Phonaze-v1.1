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
                    // iPhone에 현재 모드 전파(WireMessage.modeSet)
                    connectivity.sendMode(new)
                    // (선택) 포커스 튜닝 등 모드별 값 조정 필요시 여기서
                }

            case .disclaimer:
                ResearchDisclaimerView(onConfirm: {
                    route = .platformPicker
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

                        // 현재 모드를 iPhone에 알림
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
                        .overlay(InteractionOverlay(mode: mode))
                        .overlay(backButton { route = .platformPicker }, alignment: .topLeading)
                        .transition(.opacity.combined(with: .scale))
                }

            case .selectTask:
                // 기존 정량 과제, 코드는 그대로 — 상단에 공통 뒤로 버튼만 얹음
                SelectGameView()
                    .environmentObject(connectivity)
                    .overlay(modeBadge, alignment: .topTrailing)
                    .overlay(backButton { route = .start }, alignment: .topLeading)

            case .scrollTask:
                ScrollGameView() // ← 기존 ScrollView를 이름 바꿨다면 여기
                    .environmentObject(connectivity)
                    .overlay(modeBadge, alignment: .topTrailing)
                    .overlay(backButton { route = .start }, alignment: .topLeading)

            case .connection:
                ConnectionView(onDone: { route = .start })
                    .environmentObject(connectivity)
                    .overlay(backButton { route = .start }, alignment: .topLeading)
            }
        }
        .task { connectivity.start() }
        .onAppear { connectivity.sendMode(mode) } // 초기 모드도 전파
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
