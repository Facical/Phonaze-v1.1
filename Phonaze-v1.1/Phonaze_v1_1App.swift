import SwiftUI

@main
struct Phonaze_v1_1App: App {
    // Core states
    @StateObject private var gameState = GameState()
    @StateObject private var connectivity = ConnectivityManager()

    // Focus & ExperimentSession를 "같은 인스턴스"로 초기화
    @StateObject private var focusTracker: FocusTracker
    @StateObject private var experimentSession: ExperimentSession

    init() {
        // 1) 공용 FocusTracker 생성
        let ft = FocusTracker()
        _focusTracker = StateObject(wrappedValue: ft)

        // 2) 실험 기본 설정
        let config = ExperimentConfig.default(participantID: "P01")

        // 3) sender는 일단 더미로 넣고, onAppear에서 진짜 경로 주입
        _experimentSession = StateObject(
            wrappedValue: ExperimentSession(
                config: config,
                focusTracker: ft,
                sender: { _ in }
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // environment objects
                .environmentObject(connectivity)
                .environmentObject(gameState)
                .environmentObject(focusTracker)
                .environmentObject(experimentSession)
                .task {
                    // 광고 시작
                    connectivity.start()
                }
                .onAppear {
                    // 연결: 상태 객체들 연결
                    connectivity.setGameState(gameState)
                    connectivity.setFocusTracker(focusTracker)
                    connectivity.setExperimentSession(experimentSession)

                    // 🔹 ExperimentSession → ConnectivityManager 로 브로드캐스트 경로 지정
                    experimentSession.setSender { [weak connectivity] msg in
                        connectivity?.sendRaw(msg)
                    }
                }
        }
    }
}
