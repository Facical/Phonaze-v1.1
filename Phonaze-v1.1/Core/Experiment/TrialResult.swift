import Foundation

struct TrialResult: Codable {
    let trialIndex: Int
    let targetID: String
    let selectedID: String
    let success: Bool
    let errorCount: Int
    let startTS: Date
    let endTS: Date

    var durationMS: Int {
        Int(endTS.timeIntervalSince(startTS) * 1000.0)
    }
}
