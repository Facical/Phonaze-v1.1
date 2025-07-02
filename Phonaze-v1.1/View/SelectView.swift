//
//  SelectView.swift
//  Phonaze
//
//  Created by 강형준 on 3/18/25.
//

import SwiftUI

struct SelectView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var connectivity: ConnectivityManager
    
    // 4x4 그리드
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    
    // 게임 상태
    @State private var isGameActive = false
    @State private var currentRound = 0
    @State private var successCount = 0
    @State private var failCount = 0
    @State private var targetChangeTimer: Timer?
    @State private var gameStartTime: Date?
    @State private var totalGameTime: TimeInterval = 0
    @State private var showResults = false
    
    // **사용자가 선택한 라운드 수** (10 / 15 / 20)
    @State private var totalRounds: Int = 0
    
    // 목표 패널 좌표
    @State private var currentTarget: (x: Int, y: Int)?
    
    // 패널 변경 간격(초)
    private let panelChangeInterval: TimeInterval = 1.0
    
    // **라운드 선택 dialog** 표시 여부
    @State private var showRoundSelection = false
    
    var body: some View {
        VStack(spacing: 20) {
            if showResults {
                gameResultsView
            } else {
                gameContentView
            }
        }
        .padding(20)
        .frame(width: 300, height: 550)
        .onChange(of: connectivity.lastReceivedMessage) { _, newMessage in
            if newMessage.hasPrefix("SELECT:") {
                // SELECT 메시지 처리
                processSelectMessage(newMessage)
            }
        }
        .onDisappear {
            // 뷰가 사라질 때 타이머 정리
            stopGame()
        }
        // **라운드 선택 Dialog**
        .confirmationDialog("Select total rounds", isPresented: $showRoundSelection) {
            Button("10 Rounds") { chooseRounds(10) }
            Button("15 Rounds") { chooseRounds(15) }
            Button("20 Rounds") { chooseRounds(20) }
        }
    }
    
    // MARK: - 게임 진행/결과 화면
    private var gameContentView: some View {
        VStack(spacing: 20) {
            Text("Select Panel Task").font(.title2).bold()
            
            // 게임 상태 표시
            if isGameActive {
                // totalRounds가 0이 아니라면 실제 라운드 진행
                Text("Round: \(currentRound)/\(totalRounds) | Score: \(successCount)")
                    .foregroundColor(.blue)
                    .bold()
            }
            
            Spacer(minLength: 15)
            
            // 4x4 Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<16) { index in
                    let row = index / 4
                    let col = index % 4
                    
                    ZStack {
                        Rectangle()
                            .fill(panelColor(row: row, col: col))
                            .aspectRatio(1.0, contentMode: .fit)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 2, y: 2)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white.opacity(0.3), .clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleTap(row: row, col: col)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            
            Spacer(minLength: 20)
            
            // 게임 컨트롤 버튼
            if isGameActive {
                Text("Select the highlighted panel!")
                    .foregroundStyle(.green)
            } else {
                // 아직 게임 중이 아니면 "Start Game" 버튼
                Button(action: {
                    // **라운드 선택 Dialog** 표시
                    showRoundSelection = true
                }) {
                    Text("Start Game")
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // 게임 결과 화면
    private var gameResultsView: some View {
        VStack(spacing: 25) {
            Text("Game Results").font(.title).bold()
            
            resultStatsView
            
            Button(action: resetGame) {
                Text("Play Again")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
    }
    
    // 게임 결과 통계 부분
    private var resultStatsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Total Rounds: \(totalRounds)")
                .font(.headline)
            
            Text("Total Attempts: \(successCount + failCount)")
                .font(.subheadline)
            
            successRateView
            failureRateView
            
            Text(String(format: "Total Time: %.2f seconds", totalGameTime))
                .font(.headline)
            
            if successCount > 0 {
                Text(String(format: "Average Response Time: %.2f seconds", totalGameTime / Double(successCount)))
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var successRateView: some View {
        let successRate = calculateSuccessRate()
        return Text("Success: \(successCount) (\(successRate)%)")
            .foregroundColor(.green)
    }
    
    private var failureRateView: some View {
        let failureRate = calculateFailureRate()
        return Text("Failure: \(failCount) (\(failureRate)%)")
            .foregroundColor(.red)
    }
    
    // MARK: - 계산 함수
    private func calculateSuccessRate() -> Int {
        guard totalRounds > 0 else { return 0 }
        return Int(Double(successCount) / Double(totalRounds) * 100)
    }
    
    private func calculateFailureRate() -> Int {
        guard totalRounds > 0 else { return 0 }
        return Int(Double(failCount) / Double(totalRounds) * 100)
    }
    
    // MARK: - 라운드 선택 처리
    private func chooseRounds(_ rounds: Int) {
        // 사용자가 10/15/20 중 하나를 골랐을 때
        totalRounds = rounds
        startGame()  // 실제 게임 로직 시작
    }
    
    // MARK: - 게임 제어
    /// 실제 게임 시작 (라운드 수는 totalRounds에 저장됨)
    private func startGame() {
        // 게임 상태 초기화
        guard totalRounds > 0 else {
            // 혹시라도 선택 안 된 경우
            return
        }
        
        currentRound = 0
        successCount = 0
        failCount = 0
        showResults = false
        gameStartTime = Date()
        
        // 게임 활성화
        isGameActive = true
        
        // 첫 목표 패널
        setRandomTarget()
        
        // 타이머 시작 (패널 주기적 변경)
        targetChangeTimer?.invalidate()
        targetChangeTimer = Timer.scheduledTimer(withTimeInterval: panelChangeInterval, repeats: true) { _ in
            if isGameActive {
                setRandomTarget()
            }
        }
    }
    
    /// 게임 종료
    private func stopGame() {
        isGameActive = false
        targetChangeTimer?.invalidate()
        targetChangeTimer = nil
        
        // 총 게임 시간 계산
        if let startTime = gameStartTime {
            totalGameTime = Date().timeIntervalSince(startTime)
        }
        print("게임 종료: \(successCount)/\(totalRounds) 성공")
    }
    
    /// 게임 리셋
    private func resetGame() {
        // 다시 초기 화면으로
        showResults = false
        currentTarget = nil
        totalRounds = 0
        isGameActive = false
    }
    
    /// 랜덤 목표 패널 설정
    private func setRandomTarget() {
        let randomRow = Int.random(in: 0...3)
        let randomCol = Int.random(in: 0...3)
        currentTarget = (x: randomRow, y: randomCol)
        print("새 목표 패널: (\(randomRow), \(randomCol))")
        
        // 라운드 진행
        currentRound += 1
        if currentRound > totalRounds {
            stopGame()
            showResults = true
        }
    }
    
    /// 패널 색상 결정
    private func panelColor(row: Int, col: Int) -> Color {
        if let target = currentTarget, target.x == row, target.y == col {
            return Color.blue.opacity(0.7)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    /// 탭 처리
    private func handleTap(row: Int, col: Int) {
        guard isGameActive else {
            print("Game not active")
            return
        }
        
        guard let target = currentTarget else {
            print("No current target")
            return
        }
        
        if row == target.x && col == target.y {
            successCount += 1
            print("Correct panel (\(row),\(col)) => successCount=\(successCount)")
        } else {
            failCount += 1
            print("Wrong panel => failCount=\(failCount)")
        }
        
        // 게임 종료는 setRandomTarget() 내부에서 라운드가 넘어가면 처리
    }
    
    /// 외부(SELECT:) 메시지 처리
    private func processSelectMessage(_ message: String) {
        print("메시지 수신: \(message)")
        
        if !isGameActive {
            // 게임이 비활성화 => 라운드 선택? or 바로 startGame?
            // 여기서는 "startGame()" 해 버리거나 무시
            chooseRounds(10) // 예: 기본 10 라운드로 바로 시작
            return
        }
        
        // SELECT:0.125,0.375 -> (row,col)
        if let messageData = message.split(separator: ":").last {
            let parts = messageData.split(separator: ",")
            if parts.count == 2,
               let xRatio = Double(parts[0]),
               let yRatio = Double(parts[1]) {
                let col = Int(min(3, xRatio * 4))
                let row = Int(min(3, yRatio * 4))
                handleTap(row: row, col: col)
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    SelectView()
}
