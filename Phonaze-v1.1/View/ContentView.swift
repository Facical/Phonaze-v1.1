import SwiftUI

/// 앱 루트 컨테이너: Start → Disclaimer → PlatformPicker → Web
struct ContentView: View {
    // 라우팅 상태
    @State private var route: Route = .start
    @State private var selectedPlatform: StreamingPlatform?

    // 의존(연결/포커스/세션)
    @EnvironmentObject private var connectivity: ConnectivityManager
    @StateObject private var focusTracker = FocusTracker()
    @State private var experimentSession: ExperimentSession?

    enum Route: Hashable {
        case start
        case disclaimer
        case platformPicker
        case web
    }

    var body: some View {
        ZStack {
            switch route {
            case .start:
                // StartView는 기존 폴더 유지. 아래와 같이 진입 콜백만 연결해 주세요.
                StartView(onSelectMediaBrowsing: {
                    route = .disclaimer
                })
                // ※ 기존 StartView에 onSelectMediaBrowsing 파라미터가 없다면,
                //   버튼 Action 내부에서 route = .disclaimer로 바꿔주세요.

            case .disclaimer:
                // 기존 ResearchDisclaimerView 사용
                ResearchDisclaimerView(onConfirm: {
                    route = .platformPicker
                })

            case .platformPicker:
                PlatformPickerView(
                    onPick: { platform in
                        // 선택된 플랫폼을 세션 구성에 반영
                        selectedPlatform = platform

                        // 세션 생성 (플랫폼/모드 세팅 포함)
                        // participantID는 예시로 타임스탬프 사용. 필요 시 UI 입력으로 대체.
                        var cfg = ExperimentConfig.default(participantID: "P\(Int(Date().timeIntervalSince1970))")
                        cfg.platform = platform.rawValue
                        // 모드는 추후 모드 선택 UI에서 반영. 기본값 directTouch 유지.
                        // cfg.interactionMode = "directTouch" | "pinch" | "phonaze"

                        let session = ExperimentSession(
                            config: cfg,
                            focusTracker: focusTracker,
                            sender: { msg in
                                // EXP_STATE:* 브로드캐스트
                                connectivity.sendRaw(msg)
                            }
                        )
                        experimentSession = session
                        connectivity.setExperimentSession(session)
                        connectivity.setFocusTracker(focusTracker)

                        // 세션 시작(ready → browse)
                        session.startOrContinue()

                        // 웹 화면으로 전환
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
                        .transition(.opacity.combined(with: .scale))
                } else {
                    // 방어적 처리: 플랫폼 없음 → 선택 화면으로 복귀
                    PlatformPickerView(onPick: { platform in
                        selectedPlatform = platform
                        route = .web
                    }, onBack: { route = .disclaimer })
                }
            }
        }
        .task {
            // 앱 시작 시 연결 브로드캐스트 시작 (한 번만)
            connectivity.start()
        }
    }
}

// ---- 참고: StartView에 콜백을 손쉽게 붙일 수 있도록 기본 파라미터 제공 ---- //
// 기존 StartView 시그니처가 다르면 아래 익스텐션 대신 StartView 내부 버튼 액션에서 route 변경 처리만 해 주세요.

extension StartView {
    init(onSelectMediaBrowsing: @escaping () -> Void) {
        self.init()
        // 기존 StartView 내부의 "Media Browsing Task" 버튼에서 onSelectMediaBrowsing() 호출되도록 연결
        // 만약 기존 StartView가 수정 불가라면, 해당 버튼 액션에서 Notification을 쏘고
        // ContentView에서 .onReceive로 캐치하는 방식으로도 가능합니다.
        // 예) Notification.Name("NAV_MEDIA_BROWSING")
        // 이 초기화 편의생성자는 컴파일을 위해 제공한 예시이며,
        // 실제 StartView 구현에 맞게 버튼 액션만 연결해 주시면 됩니다.
    }
}
