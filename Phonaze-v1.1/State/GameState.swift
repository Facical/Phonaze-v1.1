import Foundation
import SwiftUI

enum InteractionMethod {
    case directTouch
    case pinch
    case phonaze
    case none
}

enum GameMode {
    case select
    case scroll
    case none
}

enum GameType {
    case select
    case scroll
    case media     // ⬅︎ 추가: Media Browsing Task
    case none
}

final class GameState: ObservableObject {
    // Common
    @Published var currentInteractionMethod: InteractionMethod = .none
    @Published var currentMode: GameMode = .none
    @Published var currentGameType: GameType = .none
    @Published var shouldReturnToStart: Bool = false

    // Select Task
    @Published var targetCoord: (x: Int, y: Int)? = nil
    @Published var lastSelectTime: TimeInterval? = nil

    // Scroll Task
    @Published var targetNumber: Int? = nil
    @Published var lastScrollTime: TimeInterval? = nil

    // Internal timers
    private var roundStartTime: Date? = nil

    // MARK: - Select Task
    func startSelectGame(targetX: Int, targetY: Int) {
        currentGameType = .select
        currentMode = .select
        targetCoord = (x: targetX, y: targetY)
        targetNumber = nil
        lastSelectTime = nil
        roundStartTime = Date()
        print("Select Start - target (\(targetX), \(targetY))")
    }

    func completeSelectGame() {
        guard currentMode == .select, let start = roundStartTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        lastSelectTime = elapsed
        currentMode = .none
        print("Select Complete - \(String(format: "%.2f", elapsed))s")
    }

    // MARK: - Scroll Task
    func startScrollGame(targetNumber: Int) {
        currentGameType = .scroll
        currentMode = .scroll
        targetCoord = nil
        self.targetNumber = targetNumber
        lastScrollTime = nil
        roundStartTime = Date()
        print("Scroll Start - target: \(targetNumber)")
    }

    func completeScrollGame() {
        guard currentMode == .scroll, let start = roundStartTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        lastScrollTime = elapsed
        currentMode = .none
        print("Scroll Complete - \(String(format: "%.2f", elapsed))s")
    }

    // MARK: - Media Task
    func startMediaTask() {
        currentGameType = .media
        currentMode = .none
        targetCoord = nil
        targetNumber = nil
        roundStartTime = nil
        print("Media Task Start")
    }

    // MARK: - Reset
    func resetGame() {
        targetCoord = nil
        targetNumber = nil
        currentMode = .none
        // currentInteractionMethod는 유지
    }
}
