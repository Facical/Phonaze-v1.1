// Phonaze-v1.1/UI/Games/SelectGameView.swift

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
    @EnvironmentObject var enhancedLogger: EnhancedExperimentLogger
    @EnvironmentObject var unintendedTracker: UnintendedSelectionTracker
        
    var onBack: (() -> Void)? = nil

    // --- Basic Settings ---
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    // --- Game State Variables ---
    @State private var gameState: GamePhase = .startScreen
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
    @State private var hoveredIndex: Int?  // ✅ 현재 시선이 머무는 패널
    @State private var hasSelectedCurrentTarget = false
    
    // --- Data Recording ---
    @State private var interactions: [GameInteraction] = []
    
    enum GamePhase {
        case startScreen
        case playing
        case results
    }

    var body: some View {
        VStack(spacing: 0) {
            // Navigation Header
            if let onBack {
                NavigationHeader(
                    title: "Select Panel Game",
                    showBackButton: true,
                    onBack: onBack
                )
            }
            
            // Game Content
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
            .frame(maxWidth: 400, maxHeight: .infinity)
        }
        .background(Color.black.opacity(0.9))
        .confirmationDialog("Select Target Score", isPresented: $showRoundSelection, titleVisibility: .visible) {
            Button("10 Points") { setRoundsAndStart(10) }
            Button("15 Points") { setRoundsAndStart(15) }
            Button("20 Points") { setRoundsAndStart(20) }
        }
        .onChange(of: connectivity.lastReceivedMessage) { _, newMessage in
            if newMessage.hasPrefix("TAP") {
                handleTapFromiPhone()
            }
        }
        .onDisappear(perform: stopGame)
    }

    // MARK: - Subviews
    
    private var startScreenView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Select Panel Game")
                .font(.largeTitle).bold()
            
            Text("When the game starts, a panel will turn yellow. Select it using your eyes and a tap on your iPhone, or by touching it directly.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Start Game") {
                showRoundSelection = true
            }
            .font(.title)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            
            Spacer()
        }
    }
    
    private var gamePlayingView: some View {
        VStack(spacing: 20) {
            Text("Select the Yellow Panel").font(.title2).bold()
            
            Text("Score: \(successCount) / \(totalRounds)  |  Fails: \(failCount)")
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.top)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<16) { index in
                    panelView(for: index)
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    private var gameResultsView: some View {
        VStack(spacing: 25) {
            Spacer()
            
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
                    ShareLink(item: csvURL) {
                        Label("Share Results (CSV)", systemImage: "square.and.arrow.up")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                Button("Play Again") {
                    resetToStartScreen()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    private func panelView(for index: Int) -> some View {
        Rectangle()
            .fill(panelColor(for: index))
            .aspectRatio(1.0, contentMode: .fit)
            .cornerRadius(8)
            .trackUnintendedSelection(id: "panel_\(index)")
            .frame(width: 100, height: 100)
            .shadow(color: .black.opacity(0.3), radius: 3, x: 2, y: 2)
            .hoverEffect()
            .onHover { isHovering in
                if isHovering {
                    hoveredIndex = index
                    unintendedTracker.startDwell(elementID: "panel_\(index)")
                } else {
                    if hoveredIndex == index {
                        hoveredIndex = nil
                    }
                    unintendedTracker.endDwell()
                }
            }
            .onTapGesture {
                if !unintendedTracker.checkTapDuringScroll(elementID: "panel_\(index)") {
                    processSelection(selectedIndex: index, via: "Direct")
                }
            }
    }

    // MARK: - iPhone Tap Handling (핵심 수정)
    
    private func handleTapFromiPhone() {
        guard gameState == .playing else { return }
        
        // ✅ 실제로 보고 있는 패널 사용 (hoveredIndex)
        if let hovered = hoveredIndex {
            processSelection(selectedIndex: hovered, via: "iPhone")
        } else {
            // ✅ 아무것도 보고 있지 않으면 실패 처리
            failCount += 1
            print("TAP received but no panel is hovered - counting as fail")
            
            // 실패 기록
            if let target = currentTargetIndex, let start = gameStartTime {
                let interaction = GameInteraction(
                    timestamp: Date().timeIntervalSince(start),
                    targetPanel: target,
                    selectedPanel: -1,  // -1 = no selection
                    wasSuccessful: false,
                    inputMethod: "iPhone"
                )
                interactions.append(interaction)
            }
            
            // 다음 타겟으로
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                setRandomTarget()
            }
        }
    }

    // MARK: - Game Logic
    
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
        gameState = .playing
        hasSelectedCurrentTarget = false
        hoveredIndex = nil
        setRandomTarget()
    }

    private func stopGame() {
        if gameState == .playing {
            if let start = gameStartTime {
                totalGameTime = Date().timeIntervalSince(start)
                
                // Enhanced logging
                let metrics = EnhancedExperimentLogger.TaskMetrics(
                    taskType: "selection",
                    interactionMode: getCurrentInteractionMode(),
                    startTime: start,
                    endTime: Date(),
                    completionTime: totalGameTime,
                    targetCount: totalRounds,
                    successCount: successCount,
                    errorCount: failCount,
                    unintendedSelections: unintendedTracker.unintendedSelections.count,
                    accuracy: Double(successCount) / Double(max(1, totalRounds))
                )
                enhancedLogger.logTaskMetrics(metrics)
            }
        }
        gameState = .results
    }

    private func resetToStartScreen() {
        successCount = 0
        failCount = 0
        interactions = []
        currentTargetIndex = nil
        hasSelectedCurrentTarget = false
        hoveredIndex = nil
        gameState = .startScreen
    }
    
    private func setRandomTarget() {
        var newTarget: Int
        repeat {
            newTarget = Int.random(in: 0..<16)
        } while newTarget == currentTargetIndex
        currentTargetIndex = newTarget
        hasSelectedCurrentTarget = false
    }

    private func processSelection(selectedIndex: Int, via inputMethod: String) {
        guard gameState == .playing,
              let target = currentTargetIndex,
              let start = gameStartTime,
              !hasSelectedCurrentTarget
        else { return }

        let successful = (selectedIndex == target)
        
        let interaction = GameInteraction(
            timestamp: Date().timeIntervalSince(start),
            targetPanel: target,
            selectedPanel: selectedIndex,
            wasSuccessful: successful,
            inputMethod: inputMethod
        )
        interactions.append(interaction)

        hasSelectedCurrentTarget = true
        
        if successful {
            successCount += 1
            if successCount >= totalRounds {
                // Task 완료
                let metrics = EnhancedExperimentLogger.TaskMetrics(
                    taskType: "selection",
                    interactionMode: inputMethod,
                    startTime: start,
                    endTime: Date(),
                    completionTime: Date().timeIntervalSince(start),
                    targetCount: totalRounds,
                    successCount: successCount,
                    errorCount: failCount,
                    unintendedSelections: unintendedTracker.unintendedSelections.count,
                    accuracy: Double(successCount) / Double(totalRounds)
                )
                enhancedLogger.logTaskMetrics(metrics)
                stopGame()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    setRandomTarget()
                }
            }
        } else {
            failCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                setRandomTarget()
            }
        }
    }

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
