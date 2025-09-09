// Core/Experiment/Metrics.swift
import Foundation

struct TrialResult: Identifiable {
    let id = UUID()
    let trialIndex: Int
    let targetID: String
    let selectedID: String
    let success: Bool
    let errorCount: Int
    let startTS: Date
    let endTS: Date
    var durationMS: Int { Int(endTS.timeIntervalSince(startTS) * 1000.0) }
}

struct SessionSummary {
    let participantID: String
    let goalTrials: Int
    let successCount: Int
    let totalErrors: Int
    let totalDurationMS: Int
}
