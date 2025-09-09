import Foundation

final class ExperimentLogger {
    private(set) var trials: [TrialResult] = []
    private(set) var totalErrors: Int = 0
    private(set) var eventLogs: [EventLog] = []

    // Trial
    func logTrial(_ t: TrialResult) {
        trials.append(t)
        totalErrors += t.errorCount
    }

    // Event (String:String payload 기본)
    func log(kind: String, payload: [String: String] = [:]) {
        let event = EventLog(timestamp: Date(), kind: kind, payload: payload)
        eventLogs.append(event)
    }

    // Event (Any payload 지원 – 문자열로 변환)
    func log(kind: String, payload: [String: Any]) {
        let mapped = payload.mapValues { String(describing: $0) }
        log(kind: kind, payload: mapped)
    }

    // Trials CSV
    func exportTrialsCSV(participantID: String, goalTrials: Int) -> URL? {
        var lines: [String] = []
        lines.append("participant_id,trial_index,target_id,selected_id,success,error_count,start_ts,end_ts,duration_ms")

        let fmt = ISO8601DateFormatter()
        for t in trials {
            let line = [
                participantID,
                "\(t.trialIndex)",
                csvEscape(t.targetID),
                csvEscape(t.selectedID),
                "\(t.success)",
                "\(t.errorCount)",
                fmt.string(from: t.startTS),
                fmt.string(from: t.endTS),
                "\(t.durationMS)"
            ].joined(separator: ",")
            lines.append(line)
        }

        let ts = Int(Date().timeIntervalSince1970)
        let filename = "BrowsingTrials_\(participantID)_\(goalTrials)_\(ts).csv"
        return CSVWriter.write(lines: lines, filename: filename)
    }

    // Events CSV (선택)
    func exportEventsCSV(participantID: String) -> URL? {
        var lines: [String] = []
        lines.append("participant_id,timestamp,kind,payload_json")

        let fmt = ISO8601DateFormatter()
        for e in eventLogs {
            let json = (try? jsonString(e.payload)) ?? "{}"
            let line = [
                participantID,
                fmt.string(from: e.timestamp),
                csvEscape(e.kind),
                csvEscape(json)
            ].joined(separator: ",")
            lines.append(line)
        }

        let ts = Int(Date().timeIntervalSince1970)
        let filename = "BrowsingEvents_\(participantID)_\(ts).csv"
        return CSVWriter.write(lines: lines, filename: filename)
    }

    // MARK: - Helpers
    private func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return s
    }

    private func jsonString(_ dict: [String: String]) throws -> String {
        let d = try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
        return String(data: d, encoding: .utf8) ?? "{}"
    }
}

struct EventLog: Codable {
    let timestamp: Date
    let kind: String
    let payload: [String: String]
}
