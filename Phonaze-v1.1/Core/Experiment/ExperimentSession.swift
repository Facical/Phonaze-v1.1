// Core/Experiment/ExperimentSession.swift
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
    private let logger = ExperimentLogger()
    private let focusTracker: FocusTracker
    private let sendState: (String) -> Void // generic sender from ConnectivityManager

    // timers
    private var trialStartTS: Date?
    private var cancellables = Set<AnyCancellable>()

    init(config: ExperimentConfig, focusTracker: FocusTracker, sender: @escaping (String) -> Void) {
        self.config = config
        self.focusTracker = focusTracker
        self.sendState = sender
    }

    // MARK: Flow controls (called from ConnectivityManager or UI)
    func startOrContinue() {
        guard phase == .idle || phase == .end else { return }
        successCount = 0
        errorCount = 0
        currentTrialIndex = 0
        phase = .ready
        broadcastPhase(.ready)
        nextTrial()
    }

    func nextTrial() {
        guard phase == .ready || phase == .select || phase == .play || phase == .browse else { return }
        if successCount >= config.goalTrials {
            finishSession()
            return
        }

        // Choose next target
        let nextTarget = pickNextTargetID()
        targetID = nextTarget
        currentTrialIndex += 1
        errorCount = 0 // per-trial
        trialStartTS = Date()

        broadcastPhase(.browse)
        if let t = nextTarget { broadcastTarget(t) }
    }

    func confirmSelectionWithCurrentFocus() {
        guard phase == .browse || phase == .select else { return }
        let focused = focusTracker.currentFocusedID
        guard let tgt = targetID, let sel = focused, let start = trialStartTS else {
            // nothing to compare
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
            broadcastPhase(.play) // UI may transition to Player
            // UI 측에서 재생 후 iPhone이 NEXT를 보낼 수 있음
        } else {
            // wrong selection → increment error and stay in trial
            errorCount += 1
            broadcastError(errorCount)
            // phase remains browse/select
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
        broadcastPhase(.idle)
    }

    func cancel() {
        phase = .end
        broadcastPhase(.end)
        // Optionally export immediately
        _ = exportCSV()
    }

    // MARK: Export
    @discardableResult
    func exportCSV() -> URL? {
        logger.exportCSV(participantID: config.participantID, goalTrials: config.goalTrials)
    }

    // MARK: Helpers
    private func pickNextTargetID() -> String? {
        if !config.targetSequence.isEmpty {
            let idx = (currentTrialIndex) % config.targetSequence.count
            return config.targetSequence[idx]
        }
        // If not provided, UI can set a target later; return nil for now.
        // Alternatively, generate a placeholder ID:
        return nil
    }

    private func finishSession() {
        phase = .end
        broadcastPhase(.end)
        _ = exportCSV()
    }

    // MARK: Broadcast bridges
    private func broadcastPhase(_ p: EXPPhase) {
        sendState(EXPMessage.statePhase(p))
    }
    private func broadcastTarget(_ id: String) {
        sendState(EXPMessage.stateTarget(id))
    }
    private func broadcastScore(_ n: Int, _ goal: Int) {
        sendState(EXPMessage.stateScore(n, goal))
    }
    private func broadcastError(_ c: Int) {
        sendState(EXPMessage.stateError(c))
    }
}
