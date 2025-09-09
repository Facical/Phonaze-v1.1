// Core/Experiment/ExperimentLogger.swift
import Foundation

final class ExperimentLogger {
    private(set) var trials: [TrialResult] = []
    private(set) var totalErrors: Int = 0

    func logTrial(_ t: TrialResult) {
        trials.append(t)
        totalErrors += t.errorCount
    }

    func exportCSV(participantID: String, goalTrials: Int) -> URL? {
        var lines: [String] = []
        lines.append("participant_id,trial_index,target_id,selected_id,success,error_count,start_ts,end_ts,duration_ms")

        let fmt = ISO8601DateFormatter()
        for t in trials {
            let line = [
                participantID,
                "\(t.trialIndex)",
                t.targetID,
                t.selectedID,
                "\(t.success)",
                "\(t.errorCount)",
                fmt.string(from: t.startTS),
                fmt.string(from: t.endTS),
                "\(t.durationMS)"
            ].joined(separator: ",")
            lines.append(line)
        }

        let ts = Int(Date().timeIntervalSince1970)
        let filename = "BrowsingTask_\(participantID)_\(goalTrials)_\(ts).csv"
        return CSVWriter.write(lines: lines, filename: filename)
    }
}
