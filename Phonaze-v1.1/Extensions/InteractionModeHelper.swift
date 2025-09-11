// Phonaze-v1.1/Extensions/InteractionModeHelper.swift

import Foundation
import SwiftUI

/// Helper extension to get current interaction mode
extension View {
    func getCurrentInteractionMode() -> String {
        // Check if we can get it from UserDefaults or Environment
        if let mode = UserDefaults.standard.string(forKey: "currentInteractionMode") {
            return mode
        }
        
        // Default fallback
        return "directTouch"
    }
}

// Global function for use in ScrollGameView
func getCurrentInteractionMode() -> String {
    if let mode = UserDefaults.standard.string(forKey: "currentInteractionMode") {
        return mode
    }
    return "directTouch"
}

// Store interaction mode when changed
func setCurrentInteractionMode(_ mode: InteractionMode) {
    UserDefaults.standard.set(mode.rawValue, forKey: "currentInteractionMode")
}
