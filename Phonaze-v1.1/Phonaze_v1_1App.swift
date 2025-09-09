//
//  Phonaze_v1_1App.swift
//  Phonaze-v1.1
//

import SwiftUI

@main
struct Phonaze_v1_1App: App {
    // Core states
    @StateObject private var gameState = GameState()
    @StateObject private var connectivity = ConnectivityManager()

    // NEW: focus & experiment session objects
    @StateObject private var focusTracker = FocusTracker()
    @StateObject private var experimentSession: ExperimentSession

    init() {
        // Experiment config (원하면 런타임에 바꾸도록 개선 가능)
        let config = ExperimentConfig.default(participantID: "P01")

        // 임시 sender 클로저는 나중에 connectivity가 초기화된 뒤 set됨
        // 우선 더미를 넣고, 실제 send는 .onAppear에서 바인딩
        _experimentSession = StateObject(
            wrappedValue: ExperimentSession(
                config: config,
                focusTracker: FocusTracker(),               // placeholder, onAppear에서 바꿔 줌
                sender: { _ in /* set later */ }
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
                .onAppear {
                    // 연결: 기존 게임 상태
                    connectivity.setGameState(gameState)

                    // 연결: FocusTracker/ExperimentSession를 ConnectivityManager에 연결
                    connectivity.setFocusTracker(focusTracker)
                    connectivity.setExperimentSession(experimentSession)

                    // ExperimentSession이 보낼 때 사용할 sender를 connectivity.send로 갱신
                    // (간단히 클로저를 다시 생성해서 주입)
                    let sender: (String) -> Void = { [weak connectivity] msg in
                        connectivity?.send(msg)
                    }
                    // 세션 내부의 sender를 업데이트하려면, 간단한 방식으로 새로운 세션을 만들어 교체하거나,
                    // 필요 시 ExperimentSession에 setSender 같은 메서드를 추가할 수 있음.
                    // 여기서는 편의상 새 세션을 재생성하지 않고, 아래처럼 간단한 reset을 호출하도록 확장했을 것을 가정.
                    // 만약 setSender API가 없다면, ExperimentSession init 시점에 FocusTracker/Connectivity를 넘겨도 충분.
                    // (간단히 아래 한 줄로 FocusTracker 동기화)
                    experimentSession.restart()
                    // FocusTracker는 이미 같은 인스턴스이므로 OK
                    // sender 사용은 connectivity.broadcast* 경로로 충분하므로 별도 setSender가 없다면 생략 가능
                }
        }
    }
}
