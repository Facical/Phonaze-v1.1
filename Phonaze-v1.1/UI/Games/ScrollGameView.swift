import SwiftUI

struct ScrollGameView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    
    // 스크롤할 숫자 (1~50)
    let numbers = Array(1...50)
    
    // 스크롤 위치 제어
    @State private var scrollProxy: ScrollViewProxy?
    
    // 양방향 스크롤 동기화
    @State private var isRemoteScrolling: Bool = false
    
    // 중앙 감지 중복 방지
    @State private var recentlyUpdatedCenter: Bool = false
    
    // Target score for the game (choose from 5, 10, 15)
    @State private var scoreGoal: Int? = nil
    
    // 현재 점수
    @State private var score: Int = 0
    
    // 게임 종료 여부
    @State private var gameOver: Bool = false
    
    // 0.5초 동안 중앙 유지 확인용
    @State private var centerCheckTask: DispatchWorkItem?
    
    // 목표 숫자
    @State private var targetNumber: Int? = nil
    
    // 시간 측정용
    @State private var startTime: Date? = nil
    @State private var gameTime: Double = 0.0
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            
            if let goal = scoreGoal {
                // If target is already selected => game in progress
                if gameOver {
                    gameOverView(goal: goal)
                } else {
                    gameContentView(goal: goal)
                }
                
            } else {
                // Haven't set score goal yet => start screen
                startView
            }
        }
        .padding()
        // iPhone → Vision: SCROLL_SELECT
        .onChange(of: connectivity.lastReceivedMessage) { newMessage in
            processMessage(newMessage)
        }
    }
}

// MARK: - Subviews
extension ScrollGameView {
    
    /// Screen before selecting score goal => only "Game Start" button
    private var startView: some View {
        VStack(spacing: 30) {
            Text("Select Score Goal")
                .font(.title).bold()
            
            Text("Choose how many points you need to finish the game.")
                .foregroundColor(.secondary)
            
            Button("Game Start") {
                // Alert (or Sheet) to select from 5/10/15
                showGoalSelectionAlert()
            }
            .font(.title3)
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
    
    /// Actual game scroll screen
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
            
            // Scroll area (shows approximately 7 items)
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
                                                .onChange(of: itemGeo.frame(in: .named("visionScroll"))) { _ in
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
            // Game start initialization
            startGame(goal: goal)
        }
    }
    
    /// Game over screen
    private func gameOverView(goal: Int) -> some View {
        VStack(spacing: 20) {
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
        }
        .padding(30)
    }
}

// MARK: - Internal Logic
extension ScrollGameView {
    
    /// iPhone -> Vision
    private func processMessage(_ message: String) {
        if message.hasPrefix("SCROLL_SELECT:") {
            if let data = message.split(separator: ":").last,
               let number = Int(data.trimmingCharacters(in: .whitespacesAndNewlines)) {
                scrollToNumber(number)
                // iPhone already determined center => immediate score processing
                if let target = targetNumber, target == number {
                    handleScored()
                }
            }
        }
    }
    
    /// Game start (set score goal)
    private func startGame(goal: Int) {
        // Prevent duplication as onAppear may be called every time
        if startTime == nil {
            // Actual game start time
            startTime = Date()
            // Generate first target
            generateNewTarget()
            score = 0
            gameOver = false
        }
    }
    
    /// Goal selection alert (5, 10, 15)
    private func showGoalSelectionAlert() {
        // In SwiftUI, use Alert + .confirmationDialog, or .sheet
        // Here's an Alert example
        // (Can be changed to .confirmationDialog etc. according to project needs)
        
        let alert = UIAlertController(title: "Select Task Score",
                                      message: "Pick total points to finish",
                                      preferredStyle: .alert)
        
        // Three actions
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
        
        // Display Alert using UIKit approach
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(alert, animated: true, completion: nil)
        }
    }
    
    /// Scroll to specific number (remote scroll)
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
    
    /// Detect number near center while directly scrolling on Vision
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
            
            // Process score after 0.5 seconds
            centerCheckTask?.cancel()
            let task = DispatchWorkItem {
                if let target = targetNumber, target == num {
                    handleScored()
                }
            }
            centerCheckTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
        }
    }
    
    /// Score +1 when target is hit
    private func handleScored() {
        score += 1
        if let goal = scoreGoal, score >= goal {
            endGame()
        } else {
            generateNewTarget()
        }
    }
    
    /// Game end -> calculate time
    private func endGame() {
        gameOver = true
        if let start = startTime {
            gameTime = Date().timeIntervalSince(start)
        }
    }
    
    /// New target number
    private func generateNewTarget() {
        let rand = Int.random(in: 3...48)
        targetNumber = rand
    }
    
    /// Game reset -> return to score selection screen
    private func resetGame() {
        // Set scoreGoal to nil to return to startView
        scoreGoal = nil
        score = 0
        gameOver = false
        targetNumber = nil
        gameTime = 0
        startTime = nil
    }
    
    /// Red background if target number, green otherwise
    private func targetBackground(num: Int) -> Color {
        if let target = targetNumber, target == num {
            return Color.red.opacity(0.3)
        } else {
            return Color.green.opacity(0.2)
        }
    }
}
