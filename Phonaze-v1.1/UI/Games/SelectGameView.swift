// Phonaze-v1.1/View/SelectView.swift

import SwiftUI

// CSV 데이터 기록을 위한 구조체 정의
struct GameInteraction {
    let timestamp: TimeInterval
    let targetPanel: Int
    let selectedPanel: Int
    let wasSuccessful: Bool
    let inputMethod: String // "Direct" or "iPhone"
}

struct SelectGameView: View {
    @EnvironmentObject var connectivity: ConnectivityManager

    // --- Basic Settings ---
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    private let panelChangeInterval: TimeInterval = 1.0

    // --- Game State Variables ---
    @State private var gameState: GamePhase = .startScreen // Manages game phases (start, playing, results)
    @State private var showRoundSelection = false

    // --- Round and Score ---
    @State private var totalRounds: Int = 10
    @State private var successCount = 0
    @State private var failCount = 0
    
    // --- Time Measurement ---
    @State private var gameStartTime: Date?
    @State private var totalGameTime: TimeInterval = 0
    
    // --- Target and Input Management ---
    @State private var currentTargetIndex: Int?
    @State private var hoveredIndex: Int?
    @State private var targetChangeTimer: Timer?
    
    // --- Data Recording ---
    @State private var interactions: [GameInteraction] = []
    
    // Enumeration representing game phases
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
        // Score selection dialog
        .confirmationDialog("Select Target Score", isPresented: $showRoundSelection, titleVisibility: .visible) {
            Button("10 Points") { setRoundsAndStart(10) }
            Button("15 Points") { setRoundsAndStart(15) }
            Button("20 Points") { setRoundsAndStart(20) }
        }
        // Receive iPhone message
        .onChange(of: connectivity.lastReceivedMessage) { _, newMessage in
            if newMessage.hasPrefix("TAP") {
                // When receiving TAP signal from iPhone, always process selection of yellow panel (target)
                if let target = currentTargetIndex {
                    processSelection(selectedIndex: target, via: "iPhone")
                } else {
                    print("Received TAP, but currentTargetIndex is nil (cannot process selection)")
                }
            }
        }
        .onDisappear(perform: stopGame)
    }

    // MARK: - Subviews for each GamePhase
    
    /// 1. Start screen (Start Game button)
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
                // Show score selection dialog
                showRoundSelection = true
            }
            .font(.title)
            .padding()
        }
    }
    
    /// 2. Game in progress screen
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
    
    /// 3. Game results screen
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
    
    /// Common panel view
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
    
    /// Function to set score and start game immediately
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
        gameState = .playing // Change game state to 'in progress'
        
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
                stopGame() // End game
            } else {
                // On success, reset timer and immediately move to next target
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
