//
//  GameState.swift
//  Phonaze
//
//  Created by 강형준 on 3/18/25.
//

// Models/GameState.swift
import Foundation

/// 게임 모드 열거형 (Select 패널 찾기 또는 Scroll 숫자 찾기)
enum GameMode {
    case select    // 16개 패널 중 올바른 패널 선택 게임
    case scroll    // 스크롤 숫자 찾기 게임
    case none      // 대기 상태 or 게임 미선택
}

class GameState: ObservableObject {
    // 현재 게임 모드 및 목표 (UI 갱신을 위해 퍼블리시드)
    @Published var currentMode: GameMode = .none
    @Published var targetCoord: (x: Int, y: Int)? = nil   // Select 게임에서 목표 패널 좌표
    @Published var targetNumber: Int? = nil              // Scroll 게임에서 목표 숫자
    @Published var lastSelectTime: TimeInterval? = nil   // 최근 Select 게임 완료 시간 (초)
    @Published var lastScrollTime: TimeInterval? = nil   // 최근 Scroll 게임 완료 시간 (초)
    
    // 내부에서 사용할 시작 시간
    private var roundStartTime: Date? = nil
    
    /// iPhone으로부터 Select 게임 좌표를 받았을 때 호출 – 게임 시작 설정
    func startSelectGame(targetX: Int, targetY: Int) {
        currentMode = .select
        targetCoord = (x: targetX, y: targetY)
        targetNumber = nil
        lastSelectTime = nil  // 이전 기록 초기화 (원하면 누적 저장 가능)
        // 라운드 시작 시간 기록
        roundStartTime = Date()
        print("Select 게임 시작 - 목표 패널: (\(targetX), \(targetY)), 시간 측정 시작")
    }
    
    /// iPhone으로부터 Scroll 게임 숫자를 받았을 때 호출 – 게임 시작 설정
    func startScrollGame(targetNumber: Int) {
        currentMode = .scroll
        targetCoord = nil
        self.targetNumber = targetNumber
        lastScrollTime = nil
        roundStartTime = Date()
        print("Scroll 게임 시작 - 목표 숫자: \(targetNumber), 시간 측정 시작")
    }
    
    /// 사용자가 올바른 패널을 선택했을 때 호출
    func completeSelectGame() {
        guard currentMode == .select, let start = roundStartTime else { return }
        // 현재 시간과 시작 시간 차이를 초 단위로 기록
        let elapsed = Date().timeIntervalSince(start)
        lastSelectTime = elapsed
        print("Select 게임 완료 - 경과 시간: \(String(format: "%.2f", elapsed))초")
        // 다음 라운드를 위해 현재 모드 리셋하거나 유지 (여기서는 .none으로 리셋)
        currentMode = .none
    }
    
    /// 사용자가 올바른 숫자를 선택했을 때 호출
    func completeScrollGame() {
        guard currentMode == .scroll, let start = roundStartTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        lastScrollTime = elapsed
        print("Scroll 게임 완료 - 경과 시간: \(String(format: "%.2f", elapsed))초")
        currentMode = .none
    }
}
