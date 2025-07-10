// Phonaze-v1.1/View/SelectView.swift

import SwiftUI

// CSV 데이터 기록을 위한 구조체 정의
struct GameInteraction {
    let timestamp: TimeInterval
    let targetPanel: Int
    let selectedPanel: Int
    let wasSuccessful: Bool
    let inputMethod: String // "Direct" 또는 "iPhone"
}

struct SelectView: View {
    @EnvironmentObject var connectivity: ConnectivityManager

    // --- 기본 설정 ---
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    private let panelChangeInterval: TimeInterval = 1.0

    // --- 게임 상태 변수 ---
    @State private var gameState: GamePhase = .startScreen // 게임 단계를 관리 (시작, 진행, 결과)
    @State private var showRoundSelection = false

    // --- 라운드 및 점수 ---
    @State private var totalRounds: Int = 10
    @State private var successCount = 0
    @State private var failCount = 0
    
    // --- 시간 측정 ---
    @State private var gameStartTime: Date?
    @State private var totalGameTime: TimeInterval = 0
    
    // --- 타겟 및 입력 관리 ---
    @State private var currentTargetIndex: Int?
    @State private var hoveredIndex: Int?
    @State private var targetChangeTimer: Timer?
    
    // --- 데이터 기록 ---
    @State private var interactions: [GameInteraction] = []
    
    // 게임 단계를 나타내는 열거형
    enum GamePhase {
        case startScreen
        case playing
        case results
    }

    var body: some View {
        VStack(spacing: 20) {
            switch gameState {
            case .startScreen:
                startScreenView
            case .playing:
                gamePlayingView
            case .results:
                gameResultsView
            }
        }
        .padding(20)
        .frame(width: 400, height: 600)
        // 점수 선택 다이얼로그
        .confirmationDialog("Select Target Score", isPresented: $showRoundSelection, titleVisibility: .visible) {
            Button("10 Points") { setRoundsAndStart(10) }
            Button("15 Points") { setRoundsAndStart(15) }
            Button("20 Points") { setRoundsAndStart(20) }
        }
        // iPhone 메시지 수신
        .onChange(of: connectivity.lastReceivedMessage) { _, newMessage in
            if newMessage.hasPrefix("TAP") {
                // iPhone에서 TAP 신호를 받으면 '항상 노란 패널(타겟)'을 선택 처리
                if let target = currentTargetIndex {
                    processSelection(selectedIndex: target, via: "iPhone")
                } else {
                    print("TAP 수신, 하지만 currentTargetIndex가 nil입니다 (선택 처리 불가)")
                }
            }
        }
        .onDisappear(perform: stopGame)
    }

    // MARK: - Subviews for each GamePhase
    
    /// 1. 시작 화면 (Start Game 버튼)
    private var startScreenView: some View {
        VStack(spacing: 40) {
            Text("Select Panel Game")
                .font(.largeTitle).bold()
            
            Text("When the game starts, a panel will turn yellow. Select it using your eyes and a tap on your iPhone, or by touching it directly.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Start Game") {
                // 점수 선택 다이얼로그를 띄움
                showRoundSelection = true
            }
            .font(.title)
            .padding()
        }
    }
    
    /// 2. 게임 진행 중 화면
    private var gamePlayingView: some View {
        VStack(spacing: 20) {
            Text("Select the Yellow Panel").font(.title2).bold()
            
            Text("Score: \(successCount) / \(totalRounds)  |  Fails: \(failCount)")
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.top)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<16) { index in
                    panelView(for: index)
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    /// 3. 게임 결과 화면
    private var gameResultsView: some View {
        VStack(spacing: 25) {
            Text("Game Over!").font(.title).bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Target Score: \(totalRounds)")
                Text("Successful Selections: \(successCount)")
                Text("Failed Selections: \(failCount)")
                Text(String(format: "Total Time: %.2f seconds", totalGameTime))
            }
            .font(.headline)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            HStack(spacing: 20) {
                if let csvURL = createCSVFile() {
                    ShareLink(item: csvURL) { Label("Share Results (CSV)", systemImage: "square.and.arrow.up") }
                }
                Button("Play Again") {
                    // 모든 상태를 초기 시작 화면으로 리셋
                    resetToStartScreen()
                }
            }
            .padding(.top, 10)
        }
    }
    
    /// 공용 패널 뷰
    private func panelView(for index: Int) -> some View {
        Rectangle()
            .fill(panelColor(for: index))
            .aspectRatio(1.0, contentMode: .fit)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.3), radius: 3, x: 2, y: 2)
            .hoverEffect()
            .onHover { isHovering in
                hoveredIndex = isHovering ? index : nil
            }
            .onTapGesture {
                processSelection(selectedIndex: index, via: "Direct")
            }
    }

    // MARK: - Game Logic
    
    /// 점수를 설정하고 즉시 게임을 시작하는 함수
    private func setRoundsAndStart(_ count: Int) {
        totalRounds = count
        startGame()
    }

    private func startGame() {
        successCount = 0
        failCount = 0
        totalGameTime = 0
        gameStartTime = Date()
        interactions = []
        gameState = .playing // 게임 상태를 '진행 중'으로 변경
        
        setRandomTarget()
        
        targetChangeTimer?.invalidate()
        targetChangeTimer = Timer.scheduledTimer(withTimeInterval: panelChangeInterval, repeats: true) { _ in
            if gameState == .playing {
                failCount += 1
                setRandomTarget()
            }
        }
    }

    private func stopGame() {
        if gameState == .playing {
            if let start = gameStartTime {
                totalGameTime = Date().timeIntervalSince(start)
            }
        }
        gameState = .results
        targetChangeTimer?.invalidate()
        targetChangeTimer = nil
    }

    private func resetToStartScreen() {
        successCount = 0
        failCount = 0
        interactions = []
        currentTargetIndex = nil
        gameState = .startScreen
    }
    
    private func setRandomTarget() {
        var newTarget: Int
        repeat {
            newTarget = Int.random(in: 0..<16)
        } while newTarget == currentTargetIndex
        currentTargetIndex = newTarget
    }

    // MARK: - Input Processing
    private func processSelection(via inputMethod: String) {
        guard let selected = hoveredIndex else { return }
        processSelection(selectedIndex: selected, via: inputMethod)
    }
    
    private func processSelection(selectedIndex: Int, via inputMethod: String) {
        guard gameState == .playing, let target = currentTargetIndex, let start = gameStartTime else { return }

        let successful = (selectedIndex == target)
        
        let interaction = GameInteraction(
            timestamp: Date().timeIntervalSince(start),
            targetPanel: target,
            selectedPanel: selectedIndex,
            wasSuccessful: successful,
            inputMethod: inputMethod
        )
        interactions.append(interaction)

        if successful {
            successCount += 1
            if successCount >= totalRounds {
                stopGame() // 게임 종료
            } else {
                // 성공 시 타이머 리셋 및 즉시 다음 타겟으로
                targetChangeTimer?.fireDate = Date().addingTimeInterval(panelChangeInterval)
                setRandomTarget()
            }
        } else {
            failCount += 1
        }
    }

    // MARK: - Helpers
    private func panelColor(for index: Int) -> Color {
        if gameState == .playing && index == currentTargetIndex {
            return .yellow
        }
        return .gray.opacity(0.3)
    }
    
    private func createCSVFile() -> URL? {
        var csvString = "Timestamp(s),InputMethod,TargetPanel,SelectedPanel,WasSuccessful\n"
        
        for record in interactions {
            let line = "\(String(format: "%.4f", record.timestamp)),\(record.inputMethod),\(record.targetPanel),\(record.selectedPanel),\(record.wasSuccessful)\n"
            csvString += line
        }
        
        do {
            let fileManager = FileManager.default
            let docsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = docsDirectory.appendingPathComponent("SelectGame_Results_\(Int(Date().timeIntervalSince1970)).csv")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error creating CSV: \(error)")
            return nil
        }
    }
}
