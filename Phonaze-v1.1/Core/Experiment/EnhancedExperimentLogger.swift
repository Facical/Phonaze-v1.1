// Phonaze-v1.1/Core/Experiment/EnhancedExperimentLogger.swift

import Foundation

/// Enhanced logger for experiment data collection
@MainActor
final class EnhancedExperimentLogger: ObservableObject {
    
    // MARK: - Data Structures
    
    struct TaskMetrics: Codable {
        let taskType: String
        let interactionMode: String
        let startTime: Date
        let endTime: Date
        let completionTime: TimeInterval
        let targetCount: Int
        let successCount: Int
        let errorCount: Int
        let unintendedSelections: Int
        let accuracy: Double
        
        var durationMS: Int {
            Int(completionTime * 1000)
        }
    }
    
    struct ScrollMetrics: Codable {
        let taskType: String = "scroll"
        let interactionMode: String
        let startTime: Date
        let endTime: Date
        let totalScrollDistance: Double
        let scrollEvents: Int
        let targetTokens: Int
        let foundTokens: Int
        let missedTokens: Int
        let falsePositives: Int
        let averageScrollSpeed: Double
    }
    
    struct BrowsingMetrics: Codable {
        let platform: String
        let interactionMode: String
        let sessionDuration: TimeInterval
        let pagesVisited: Int
        let totalClicks: Int
        let totalScrolls: Int
        let unintendedSelections: Int
        let videoPlays: Int
        let searchQueries: Int
        let navigationActions: Int
    }
    
    struct InteractionEvent: Codable {
        let timestamp: Date
        let eventType: String
        let interactionMode: String
        let targetID: String?
        let selectedID: String?
        let coordinates: CGPoint?
        let metadata: [String: String]
    }
    
    // MARK: - Properties
    
    @Published private var taskMetrics: [TaskMetrics] = []
    @Published private var scrollMetrics: [ScrollMetrics] = []
    @Published private var browsingMetrics: [BrowsingMetrics] = []
    @Published private var interactionEvents: [InteractionEvent] = []
    private var currentSessionID: String = ""
    
    init() {
        generateSessionID()
    }
    
    // MARK: - Session Management
    
    private func generateSessionID() {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        currentSessionID = "S\(timestamp)_\(random)"
    }
    
    // MARK: - Logging Methods
    
    func logTaskMetrics(_ metrics: TaskMetrics) {
        taskMetrics.append(metrics)
        print("📊 Task logged: \(metrics.taskType) - Accuracy: \(String(format: "%.1f%%", metrics.accuracy * 100))")
    }
    
    func logScrollMetrics(_ metrics: ScrollMetrics) {
        scrollMetrics.append(metrics)
        print("📊 Scroll logged: Found \(metrics.foundTokens)/\(metrics.targetTokens) tokens")
    }
    
    func logBrowsingMetrics(_ metrics: BrowsingMetrics) {
        browsingMetrics.append(metrics)
        print("📊 Browsing logged: \(metrics.platform) - \(metrics.pagesVisited) pages in \(Int(metrics.sessionDuration))s")
    }
    
    func logInteraction(
        type: String,
        targetID: String? = nil,
        selectedID: String? = nil,
        coordinates: CGPoint? = nil,
        mode: String,
        metadata: [String: String] = [:]
    ) {
        let event = InteractionEvent(
            timestamp: Date(),
            eventType: type,
            interactionMode: mode,
            targetID: targetID,
            selectedID: selectedID,
            coordinates: coordinates,
            metadata: metadata
        )
        interactionEvents.append(event)
    }
    
    // MARK: - Export Methods
    
    func exportAllData(participantID: String) -> [URL] {
        var exportedURLs: [URL] = []
        
        if let url = exportTaskMetrics(participantID: participantID) {
            exportedURLs.append(url)
        }
        
        if let url = exportScrollMetrics(participantID: participantID) {
            exportedURLs.append(url)
        }
        
        if let url = exportBrowsingMetrics(participantID: participantID) {
            exportedURLs.append(url)
        }
        
        if let url = exportInteractionEvents(participantID: participantID) {
            exportedURLs.append(url)
        }
        
        if let url = exportSummaryReport(participantID: participantID) {
            exportedURLs.append(url)
        }
        
        return exportedURLs
    }
    
    private func exportTaskMetrics(participantID: String) -> URL? {
        guard !taskMetrics.isEmpty else { return nil }
        
        var lines: [String] = []
        lines.append("session_id,participant_id,task_type,interaction_mode,start_time,end_time,duration_ms,targets,successes,errors,unintended,accuracy")
        
        let formatter = ISO8601DateFormatter()
        
        for metric in taskMetrics {
            let line = [
                currentSessionID,
                participantID,
                metric.taskType,
                metric.interactionMode,
                formatter.string(from: metric.startTime),
                formatter.string(from: metric.endTime),
                "\(metric.durationMS)",
                "\(metric.targetCount)",
                "\(metric.successCount)",
                "\(metric.errorCount)",
                "\(metric.unintendedSelections)",
                String(format: "%.3f", metric.accuracy)
            ].joined(separator: ",")
            lines.append(line)
        }
        
        return saveCSV(lines: lines, filename: "TaskMetrics_\(participantID)_\(currentSessionID).csv")
    }
    
    private func exportScrollMetrics(participantID: String) -> URL? {
        guard !scrollMetrics.isEmpty else { return nil }
        
        var lines: [String] = []
        lines.append("session_id,participant_id,interaction_mode,start_time,end_time,scroll_distance,scroll_events,target_tokens,found_tokens,missed_tokens,false_positives,avg_scroll_speed")
        
        let formatter = ISO8601DateFormatter()
        
        for metric in scrollMetrics {
            let line = [
                currentSessionID,
                participantID,
                metric.interactionMode,
                formatter.string(from: metric.startTime),
                formatter.string(from: metric.endTime),
                String(format: "%.1f", metric.totalScrollDistance),
                "\(metric.scrollEvents)",
                "\(metric.targetTokens)",
                "\(metric.foundTokens)",
                "\(metric.missedTokens)",
                "\(metric.falsePositives)",
                String(format: "%.2f", metric.averageScrollSpeed)
            ].joined(separator: ",")
            lines.append(line)
        }
        
        return saveCSV(lines: lines, filename: "ScrollMetrics_\(participantID)_\(currentSessionID).csv")
    }
    
    private func exportBrowsingMetrics(participantID: String) -> URL? {
        guard !browsingMetrics.isEmpty else { return nil }
        
        var lines: [String] = []
        lines.append("session_id,participant_id,platform,interaction_mode,duration_s,pages_visited,clicks,scrolls,unintended,video_plays,searches,navigations")
        
        for metric in browsingMetrics {
            let line = [
                currentSessionID,
                participantID,
                metric.platform,
                metric.interactionMode,
                String(format: "%.1f", metric.sessionDuration),
                "\(metric.pagesVisited)",
                "\(metric.totalClicks)",
                "\(metric.totalScrolls)",
                "\(metric.unintendedSelections)",
                "\(metric.videoPlays)",
                "\(metric.searchQueries)",
                "\(metric.navigationActions)"
            ].joined(separator: ",")
            lines.append(line)
        }
        
        return saveCSV(lines: lines, filename: "BrowsingMetrics_\(participantID)_\(currentSessionID).csv")
    }
    
    private func exportInteractionEvents(participantID: String) -> URL? {
        guard !interactionEvents.isEmpty else { return nil }
        
        var lines: [String] = []
        lines.append("session_id,participant_id,timestamp,event_type,interaction_mode,target_id,selected_id,x_coord,y_coord,metadata")
        
        let formatter = ISO8601DateFormatter()
        
        for event in interactionEvents {
            let metadataJSON = (try? JSONSerialization.data(withJSONObject: event.metadata)) ?? Data()
            let metadataString = String(data: metadataJSON, encoding: .utf8) ?? "{}"
            
            let line = [
                currentSessionID,
                participantID,
                formatter.string(from: event.timestamp),
                event.eventType,
                event.interactionMode,
                event.targetID ?? "none",
                event.selectedID ?? "none",
                event.coordinates.map { String(format: "%.1f", $0.x) } ?? "null",
                event.coordinates.map { String(format: "%.1f", $0.y) } ?? "null",
                "\"\(metadataString.replacingOccurrences(of: "\"", with: "\\\""))\""
            ].joined(separator: ",")
            lines.append(line)
        }
        
        return saveCSV(lines: lines, filename: "InteractionEvents_\(participantID)_\(currentSessionID).csv")
    }
    
    private func exportSummaryReport(participantID: String) -> URL? {
        var lines: [String] = []
        lines.append("=== EXPERIMENT SUMMARY REPORT ===")
        lines.append("Session ID: \(currentSessionID)")
        lines.append("Participant: \(participantID)")
        lines.append("Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short))")
        lines.append("")
        
        // Task Summary
        if !taskMetrics.isEmpty {
            lines.append("SELECTION TASKS:")
            for metric in taskMetrics {
                lines.append("  - \(metric.taskType) (\(metric.interactionMode)): \(metric.successCount)/\(metric.targetCount) correct, \(metric.errorCount) errors, \(String(format: "%.1f", metric.completionTime))s")
            }
            lines.append("")
        }
        
        // Scroll Summary
        if !scrollMetrics.isEmpty {
            lines.append("SCROLL TASKS:")
            for metric in scrollMetrics {
                lines.append("  - \(metric.interactionMode): Found \(metric.foundTokens)/\(metric.targetTokens) tokens, \(metric.falsePositives) false positives")
            }
            lines.append("")
        }
        
        // Browsing Summary
        if !browsingMetrics.isEmpty {
            lines.append("BROWSING SESSIONS:")
            for metric in browsingMetrics {
                lines.append("  - \(metric.platform) (\(metric.interactionMode)): \(metric.pagesVisited) pages, \(metric.totalClicks) clicks, \(metric.unintendedSelections) unintended")
            }
            lines.append("")
        }
        
        // Statistics
        lines.append("OVERALL STATISTICS:")
        let totalUnintended = taskMetrics.reduce(0) { $0 + $1.unintendedSelections } +
                            browsingMetrics.reduce(0) { $0 + $1.unintendedSelections }
        lines.append("  - Total Unintended Selections: \(totalUnintended)")
        lines.append("  - Total Interaction Events: \(interactionEvents.count)")
        
        let filename = "Summary_\(participantID)_\(currentSessionID).txt"
        return saveText(lines: lines, filename: filename)
    }
    
    // MARK: - File Saving
    
    private func saveCSV(lines: [String], filename: String) -> URL? {
        let text = lines.joined(separator: "\n")
        return saveFile(text: text, filename: filename)
    }
    
    private func saveText(lines: [String], filename: String) -> URL? {
        let text = lines.joined(separator: "\n")
        return saveFile(text: text, filename: filename)
    }
    
    private func saveFile(text: String, filename: String) -> URL? {
        do {
            let dir = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let url = dir.appendingPathComponent(filename)
            try text.write(to: url, atomically: true, encoding: .utf8)
            print("📁 Saved: \(filename)")
            return url
        } catch {
            print("❌ Failed to save \(filename): \(error)")
            return nil
        }
    }
}
