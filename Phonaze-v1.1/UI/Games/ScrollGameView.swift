import SwiftUI

struct ScrollGameView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @EnvironmentObject var enhancedLogger: EnhancedExperimentLogger
    @EnvironmentObject var unintendedTracker: UnintendedSelectionTracker
    var onBack: (() -> Void)? = nil  // Add back callback
    
    let numbers = Array(1...50)
    
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isRemoteScrolling: Bool = false
    @State private var recentlyUpdatedCenter: Bool = false
    @State private var scoreGoal: Int? = nil
    @State private var score: Int = 0
    @State private var gameOver: Bool = false
    @State private var centerCheckTask: DispatchWorkItem?
    @State private var targetNumber: Int? = nil
    @State private var startTime: Date? = nil
    @State private var gameTime: Double = 0.0
    @State private var scrollDistance: Double = 0
    @State private var scrollEvents: Int = 0
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Header
            if let onBack {
                NavigationHeader(
                    title: "Scroll Task",
                    showBackButton: true,
                    onBack: onBack
                )
            }
            
            // Game Content
            VStack(spacing: 20) {
                if let goal = scoreGoal {
                    if gameOver {
                        gameOverView(goal: goal)
                    } else {
                        gameContentView(goal: goal)
                    }
                } else {
                    startView
                }
            }
            .padding()
            .frame(maxHeight: .infinity)
        }
        .background(Color.black.opacity(0.9))
        .onChange(of: connectivity.lastReceivedMessage) { _, newMessage in
            processMessage(newMessage)
        }
    }
}

// MARK: - Subviews
extension ScrollGameView {
    
    private var startView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Select Score Goal")
                .font(.title).bold()
            
            Text("Choose how many points you need to finish the game.")
                .foregroundColor(.secondary)
            
            Button("Game Start") {
                showGoalSelectionAlert()
            }
            .font(.title3)
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    private func gameContentView(goal: Int) -> some View {
        VStack(spacing: 10) {
            Text("ScrollView (VisionOS)")
                .font(.title).bold()
            
            Text("Score: \(score) / \(goal)")
                .font(.headline)
                .foregroundColor(.blue)
            
            if let target = targetNumber {
                Text("Target: \(target)")
                    .font(.title3)
                    .padding(8)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(.red)
            }
            
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        LazyVStack(spacing: 15) {
                            ForEach(numbers, id: \.self) { num in
                                Text("\(num)")
                                    .font(.title3)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(targetBackground(num: num))
                                    .cornerRadius(8)
                                    .id(num)
                                    .background(
                                        GeometryReader { itemGeo in
                                            Color.clear
                                                .onAppear {
                                                    checkCenter(num, itemGeo, geo, goal)
                                                }
                                                .onChange(of: itemGeo.frame(in: .named("visionScroll"))) { _, _ in
                                                    checkCenter(num, itemGeo, geo, goal)
                                                }
                                        }
                                    )
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .onAppear {
                            scrollProxy = proxy
                        }
                    }
                }
                .coordinateSpace(name: "visionScroll")
            }
            .frame(height: 250)
            
            Spacer()
        }
        .onAppear {
            startGame(goal: goal)
        }
    }
    
    private func gameOverView(goal: Int) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Game Over!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.red)
            
            Text("Final Score: \(score) / \(goal)")
                .font(.headline)
            
            Text(String(format: "Total Time : %.2f seconds", gameTime))
                .font(.headline)
                .foregroundColor(.blue)
            
            Button("Play Again") {
                resetGame()
            }
            .font(.title3)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding(30)
    }
}

// MARK: - Internal Logic (unchanged)
extension ScrollGameView {
    
    private func processMessage(_ message: String) {
        if message.hasPrefix("SCROLL_SELECT:") {
            if let data = message.split(separator: ":").last,
               let number = Int(data.trimmingCharacters(in: .whitespacesAndNewlines)) {
                scrollToNumber(number)
                if let target = targetNumber, target == number {
                    handleScored()
                }
            }
        }
    }
    
    private func startGame(goal: Int) {
        if startTime == nil {
            startTime = Date()
            generateNewTarget()
            score = 0
            gameOver = false
        }
    }
    
    private func showGoalSelectionAlert() {
        let alert = UIAlertController(title: "Select Task Score",
                                      message: "Pick total points to finish",
                                      preferredStyle: .alert)
        
        let fiveAction = UIAlertAction(title: "5 points", style: .default) { _ in
            scoreGoal = 5
        }
        let tenAction = UIAlertAction(title: "10 points", style: .default) { _ in
            scoreGoal = 10
        }
        let fifteenAction = UIAlertAction(title: "15 points", style: .default) { _ in
            scoreGoal = 15
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(fiveAction)
        alert.addAction(tenAction)
        alert.addAction(fifteenAction)
        alert.addAction(cancelAction)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(alert, animated: true, completion: nil)
        }
    }
    
    private func scrollToNumber(_ number: Int) {
        guard let proxy = scrollProxy else { return }
        guard numbers.contains(number) else { return }
        
        isRemoteScrolling = true
        withAnimation(.easeInOut(duration: 0.5)) {
            proxy.scrollTo(number, anchor: .center)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isRemoteScrolling = false
        }
    }
    
    private func checkCenter(_ num: Int,
                             _ itemGeo: GeometryProxy,
                             _ containerGeo: GeometryProxy,
                             _ goal: Int) {
        guard !isRemoteScrolling, !gameOver else { return }
        
        let frame = itemGeo.frame(in: .named("visionScroll"))
        let centerY = containerGeo.size.height / 2
        
        let tolerance: CGFloat = 20
        if (frame.midY > centerY - tolerance) && (frame.midY < centerY + tolerance) {
            
            if recentlyUpdatedCenter { return }
            recentlyUpdatedCenter = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                recentlyUpdatedCenter = false
            }
            
            centerCheckTask?.cancel()
            let task = DispatchWorkItem {
                if let target = targetNumber, target == num {
                    handleScored()
                }
            }
            centerCheckTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
        }
        unintendedTracker.recordScroll()
        scrollEvents += 1
    }
    
    private func handleScored() {
        score += 1
        if let goal = scoreGoal, score >= goal {
            endGame()
        } else {
            generateNewTarget()
        }
    }
    
    private func endGame() {
        gameOver = true
        if let start = startTime {
            gameTime = Date().timeIntervalSince(start)
            
            // Enhanced logging
            let metrics = EnhancedExperimentLogger.ScrollMetrics(
                interactionMode: getCurrentInteractionMode(),
                startTime: start,
                endTime: Date(),
                totalScrollDistance: scrollDistance,
                scrollEvents: scrollEvents,
                targetTokens: scoreGoal ?? 0,
                foundTokens: score,
                missedTokens: (scoreGoal ?? 0) - score,
                falsePositives: 0,
                averageScrollSpeed: scrollEvents > 0 ? scrollDistance / Double(scrollEvents) : 0
            )
            enhancedLogger.logScrollMetrics(metrics)
        }
    }
    
    private func generateNewTarget() {
        let rand = Int.random(in: 3...48)
        targetNumber = rand
    }
    
    private func resetGame() {
        scoreGoal = nil
        score = 0
        gameOver = false
        targetNumber = nil
        gameTime = 0
        startTime = nil
    }
    
    private func targetBackground(num: Int) -> Color {
        if let target = targetNumber, target == num {
            return Color.red.opacity(0.3)
        } else {
            return Color.green.opacity(0.2)
        }
    }
}
