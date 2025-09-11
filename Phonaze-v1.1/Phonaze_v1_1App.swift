import SwiftUI

@main
struct Phonaze_v1_1App: App {
    // Core states
    @StateObject private var gameState = GameState()
    @StateObject private var connectivity = ConnectivityManager()
    @StateObject private var focusTracker: FocusTracker
    @StateObject private var experimentSession: ExperimentSession
    @StateObject private var enhancedLogger = EnhancedExperimentLogger()
    @Environment(\.scenePhase) var scenePhase  // VisionOS 호환

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
                .environmentObject(enhancedLogger)
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
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        exportAllData()
                    }
                }
        }
    }
    private func exportAllData() {
        let participantID = UserDefaults.standard.string(forKey: "participantID") ?? "P01"
        let urls = enhancedLogger.exportAllData(participantID: participantID)
        print("📊 Exported \(urls.count) data files")
    }
}
