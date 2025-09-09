// Core/Experiment/Metrics.swift
import Foundation

struct SessionSummary {
    let participantID: String
    let goalTrials: Int
    let successCount: Int
    let totalErrors: Int
    let totalDurationMS: Int
}
