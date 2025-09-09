// Core/Focus/FocusTracker.swift
import Foundation
import Combine

/// Global focus tracking used by Media UI and ExperimentSession.
final class FocusTracker: ObservableObject {
    @Published private(set) var currentFocusedID: String? = nil

    private let smoother = FocusSmoother(stableAfter: 0.2)
    private var cancellables = Set<AnyCancellable>()

    /// Call from UI hover/focus callbacks.
    func updateCandidate(id: String?) {
        if let stable = smoother.feed(candidate: id) {
            if stable != currentFocusedID {
                currentFocusedID = stable
            }
        }
    }

    func forceSet(id: String?) {
        smoother.reset()
        currentFocusedID = id
    }
}
