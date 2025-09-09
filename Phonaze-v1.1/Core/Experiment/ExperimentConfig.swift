// Core/Experiment/ExperimentConfig.swift
import Foundation

struct ExperimentConfig {
    var participantID: String
    var goalTrials: Int = 10

    /// Optional pre-defined target sequence (item IDs). If empty, UI can generate.
    var targetSequence: [String] = []

    static func `default`(participantID: String) -> ExperimentConfig {
        ExperimentConfig(participantID: participantID, goalTrials: 10, targetSequence: [])
    }
}
