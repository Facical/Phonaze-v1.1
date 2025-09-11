// Phonaze-v1.1/Core/Tracking/UnintendedSelectionTracker.swift

import Foundation
import SwiftUI

/// Tracks unintended selections during experiments
@MainActor
final class UnintendedSelectionTracker: ObservableObject {
    @Published var unintendedSelections: [UnintendedSelection] = []
    @Published var isTracking: Bool = false
    
    // Dwell detection
    private var dwellTimer: Timer?
    private var currentHoveredID: String?
    private var dwellStartTime: Date?
    private let dwellThreshold: TimeInterval = 1.5
    
    // Scroll accidental tap detection
    private var lastScrollTime: Date?
    private let scrollTapWindow: TimeInterval = 0.5
    
    struct UnintendedSelection: Codable {
        let timestamp: Date
        let type: SelectionType
        let elementID: String?
        let context: String
        let interactionMode: String
        
        enum SelectionType: String, Codable {
            case dwellTimeout = "dwell_timeout"
            case scrollAccidental = "scroll_accidental"
            case gazeDrift = "gaze_drift"
            case edgeTap = "edge_tap"
        }
    }
    
    // MARK: - Public Methods
    
    func startTracking() {
        isTracking = true
        unintendedSelections.removeAll()
        print("🎯 Started tracking unintended selections")
    }
    
    func stopTracking() {
        isTracking = false
        stopDwellTimer()
        print("🛑 Stopped tracking. Total unintended: \(unintendedSelections.count)")
    }
    
    // MARK: - Dwell Detection
    
    func startDwell(elementID: String) {
        guard isTracking else { return }
        
        currentHoveredID = elementID
        dwellStartTime = Date()
        
        dwellTimer?.invalidate()
        dwellTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.checkDwellTimeout()
        }
    }
    
    func endDwell() {
        stopDwellTimer()
        currentHoveredID = nil
        dwellStartTime = nil
    }
    
    private func checkDwellTimeout() {
        guard let startTime = dwellStartTime else { return }
        
        let dwellDuration = Date().timeIntervalSince(startTime)
        if dwellDuration >= dwellThreshold {
            recordUnintended(
                type: .dwellTimeout,
                elementID: currentHoveredID,
                context: "Excessive dwell time: \(String(format: "%.1f", dwellDuration))s"
            )
            stopDwellTimer()
        }
    }
    
    private func stopDwellTimer() {
        dwellTimer?.invalidate()
        dwellTimer = nil
    }
    
    // MARK: - Scroll Accidental Tap Detection
    
    func recordScroll() {
        lastScrollTime = Date()
    }
    
    func checkTapDuringScroll(elementID: String?) -> Bool {
        guard isTracking, let scrollTime = lastScrollTime else { return false }
        
        let timeSinceScroll = Date().timeIntervalSince(scrollTime)
        if timeSinceScroll < scrollTapWindow {
            recordUnintended(
                type: .scrollAccidental,
                elementID: elementID,
                context: "Tap during scroll: \(String(format: "%.2f", timeSinceScroll))s after scroll"
            )
            return true
        }
        return false
    }
    
    // MARK: - Gaze Drift Detection
    
    func checkGazeDrift(from oldID: String?, to newID: String?) {
        guard isTracking, oldID != nil, newID != nil, oldID != newID else { return }
        
        recordUnintended(
            type: .gazeDrift,
            elementID: newID,
            context: "Gaze shifted from \(oldID ?? "unknown") to \(newID ?? "unknown")"
        )
    }
    
    // MARK: - Edge Tap Detection
    
    func checkEdgeTap(location: CGPoint, in bounds: CGRect) -> Bool {
        guard isTracking else { return false }
        
        let edgeThreshold: CGFloat = 20
        let isEdgeTap = location.x < edgeThreshold ||
                       location.x > bounds.width - edgeThreshold ||
                       location.y < edgeThreshold ||
                       location.y > bounds.height - edgeThreshold
        
        if isEdgeTap {
            recordUnintended(
                type: .edgeTap,
                elementID: nil,
                context: "Edge tap at (\(Int(location.x)), \(Int(location.y)))"
            )
        }
        
        return isEdgeTap
    }
    
    // MARK: - Recording
    
    private func recordUnintended(type: UnintendedSelection.SelectionType, elementID: String?, context: String) {
        let selection = UnintendedSelection(
            timestamp: Date(),
            type: type,
            elementID: elementID,
            context: context,
            interactionMode: getCurrentInteractionMode()
        )
        
        unintendedSelections.append(selection)
        
        print("⚠️ Unintended selection: \(type.rawValue) - \(context)")
    }
    
    private func getCurrentInteractionMode() -> String {
        // This should be connected to actual interaction mode
        // For now, return a placeholder
        return UserDefaults.standard.string(forKey: "currentInteractionMode") ?? "unknown"
    }
    
    // MARK: - Export
    
    func exportToCSV() -> URL? {
        guard !unintendedSelections.isEmpty else { return nil }
        
        var lines: [String] = []
        lines.append("timestamp,type,element_id,context,interaction_mode")
        
        let formatter = ISO8601DateFormatter()
        for selection in unintendedSelections {
            let line = [
                formatter.string(from: selection.timestamp),
                selection.type.rawValue,
                selection.elementID ?? "none",
                "\"\(selection.context)\"",
                selection.interactionMode
            ].joined(separator: ",")
            lines.append(line)
        }
        
        let filename = "UnintendedSelections_\(Int(Date().timeIntervalSince1970)).csv"
        
        do {
            let dir = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let url = dir.appendingPathComponent(filename)
            let text = lines.joined(separator: "\n")
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to export CSV: \(error)")
            return nil
        }
    }
}

// MARK: - View Modifier for Tracking

struct UnintendedSelectionTracking: ViewModifier {
    @StateObject private var tracker = UnintendedSelectionTracker()
    let elementID: String
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering {
                    tracker.startDwell(elementID: elementID)
                } else {
                    tracker.endDwell()
                }
            }
            .environmentObject(tracker)
    }
}

extension View {
    func trackUnintendedSelection(id: String) -> some View {
        self.modifier(UnintendedSelectionTracking(elementID: id))
    }
}
