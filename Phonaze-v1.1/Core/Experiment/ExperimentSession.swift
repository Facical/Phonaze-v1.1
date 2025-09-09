import Foundation
import Combine

/// Drives the media browsing task: start -> browse/select -> (play) -> next/end
final class ExperimentSession: ObservableObject {
    enum Phase: String { case idle, ready, browse, select, play, end }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var currentTrialIndex: Int = 0
    @Published private(set) var targetID: String? = nil
    @Published private(set) var successCount: Int = 0
    @Published private(set) var errorCount: Int = 0

    let config: ExperimentConfig
    let logger = ExperimentLogger()
    private let focusTracker: FocusTracker

    /// ConnectivityManager.sendRaw(EXP_STATE:*)에 연결되는 브로드캐스트 클로저
    private var sendState: (String) -> Void

    // timers
    private var trialStartTS: Date?
    private var cancellables = Set<AnyCancellable>()

    init(config: ExperimentConfig, focusTracker: FocusTracker, sender: @escaping (String) -> Void) {
        self.config = config
        self.focusTracker = focusTracker
        self.sendState = sender
    }

    // 🔹 App/Content에서 나중에 보낼 경로를 바꿀 수 있도록 허용
    func setSender(_ sender: @escaping (String) -> Void) {
        self.sendState = sender
    }

    // MARK: - Public logging forwarders (ConnectivityManager에서 호출)
    func log(kind: String, payload: [String: String] = [:]) { logger.log(kind: kind, payload: payload) }
    func log(kind: String, payload: [String: Any])        { logger.log(kind: kind, payload: payload) }

    // MARK: Flow controls
    func startOrContinue() {
        guard phase == .idle || phase == .end else { return }
        successCount = 0
        errorCount = 0
        currentTrialIndex = 0
        phase = .ready

        logger.log(kind: "session_begin", payload: [
            "taskType": config.taskType,
            "platform": config.platform ?? "unknown",
            "interactionMode": config.interactionMode,
            "goalTrials": "\(config.goalTrials)"
        ])

        broadcastPhase(.ready)
        nextTrial()
    }

    func nextTrial() {
        guard phase == .ready || phase == .select || phase == .play || phase == .browse else { return }
        if successCount >= config.goalTrials { finishSession(); return }

        let nextTarget = pickNextTargetID()
        targetID = nextTarget
        currentTrialIndex += 1
        errorCount = 0
        trialStartTS = Date()

        logger.log(kind: "trial_begin", payload: [
            "trialIndex": "\(currentTrialIndex)",
            "targetID": nextTarget ?? "nil"
        ])

        broadcastPhase(.browse)
        if let t = nextTarget { broadcastTarget(t) }
    }

    func confirmSelectionWithCurrentFocus() {
        guard phase == .browse || phase == .select else { return }
        let focused = focusTracker.currentFocusedID
        guard let tgt = targetID, let sel = focused, let start = trialStartTS else {
            logger.log(kind: "trial_select_ignored", payload: ["reason": "missing_target_or_focus_or_startTS"])
            return
        }

        let success = (tgt == sel)
        let end = Date()
        let result = TrialResult(trialIndex: currentTrialIndex,
                                 targetID: tgt,
                                 selectedID: sel,
                                 success: success,
                                 errorCount: errorCount,
                                 startTS: start,
                                 endTS: end)
        logger.logTrial(result)

        if success {
            successCount += 1
            logger.log(kind: "trial_success", payload: [
                "trialIndex": "\(currentTrialIndex)", "targetID": tgt, "selectedID": sel
            ])
            broadcastPhase(.play)
        } else {
            errorCount += 1
            logger.log(kind: "trial_error", payload: [
                "trialIndex": "\(currentTrialIndex)", "targetID": tgt, "selectedID": sel, "errorCount": "\(errorCount)"
            ])
            broadcastError(errorCount)
        }
        broadcastScore(successCount, config.goalTrials)
    }

    func restart() {
        phase = .idle
        targetID = nil
        successCount = 0
        errorCount = 0
        currentTrialIndex = 0
        trialStartTS = nil
        logger.log(kind: "session_restart")
        broadcastPhase(.idle)
    }

    func cancel() {
        phase = .end
        logger.log(kind: "session_cancel")
        broadcastPhase(.end)
        _ = exportCSV()
    }

    // MARK: Export
    @discardableResult
    func exportCSV(exportEvents: Bool = false) -> (URL?, URL?) {
        let trialsURL = logger.exportTrialsCSV(participantID: config.participantID, goalTrials: config.goalTrials)
        let eventsURL = exportEvents ? logger.exportEventsCSV(participantID: config.participantID) : nil
        return (trialsURL, eventsURL)
    }

    // MARK: Helpers
    private func pickNextTargetID() -> String? {
        if !config.targetSequence.isEmpty {
            let idx = (currentTrialIndex) % config.targetSequence.count
            return config.targetSequence[idx]
        }
        return nil
    }

    private func finishSession() {
        phase = .end
        logger.log(kind: "session_end", payload: [
            "successCount": "\(successCount)",
            "goalTrials": "\(config.goalTrials)"
        ])
        broadcastPhase(.end)
        _ = exportCSV()
    }

    // MARK: Broadcast bridges
    private func broadcastPhase(_ p: EXPPhase) { sendState(EXPMessage.statePhase(p)) }
    private func broadcastTarget(_ id: String) { sendState(EXPMessage.stateTarget(id)) }
    private func broadcastScore(_ n: Int, _ goal: Int) { sendState(EXPMessage.stateScore(n, goal)) }
    private func broadcastError(_ c: Int) { sendState(EXPMessage.stateError(c)) }
}
