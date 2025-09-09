// Core/Focus/FocusSmoothing.swift
import Foundation

/// Debounce-like stabilizer: an ID becomes "stable" only if it stays the same for `stableAfter`.
final class FocusSmoother {
    private var pendingID: String?
    private var pendingSince: Date?
    private let stableAfter: TimeInterval

    init(stableAfter: TimeInterval = 0.2) {
        self.stableAfter = stableAfter
    }

    /// Returns a "stable" id if the candidate remained unchanged longer than threshold.
    func feed(candidate: String?) -> String? {
        guard let id = candidate else {
            pendingID = nil; pendingSince = nil
            return nil
        }
        if pendingID != id {
            pendingID = id
            pendingSince = Date()
            return nil
        } else {
            guard let since = pendingSince else { return nil }
            if Date().timeIntervalSince(since) >= stableAfter {
                return id
            }
            return nil
        }
    }

    func reset() {
        pendingID = nil
        pendingSince = nil
    }
}
