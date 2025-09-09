import SwiftUI

struct ScrollViewGame: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    
    // 스크롤할 숫자 (1~50)
    let numbers = Array(1...50)
    
    // 스크롤 위치 제어
    @State private var scrollProxy: ScrollViewProxy?
    
    // 양방향 스크롤 동기화
    @State private var isRemoteScrolling: Bool = false
    
    // 중앙 감지 중복 방지
    @State private var recentlyUpdatedCenter: Bool = false
    
    // 게임 목표 점수 (5, 10, 15 중 선택)
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
                // 이미 목표를 선택했다면 => 게임 진행
                if gameOver {
                    gameOverView(goal: goal)
                } else {
                    gameContentView(goal: goal)
                }
                
            } else {
                // 아직 점수 Goal을 정하지 않음 => 시작 화면
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
extension ScrollViewGame {
    
    /// 아직 점수 목표 선택 전 => "게임 시작" 버튼만 있는 화면
    private var startView: some View {
        VStack(spacing: 30) {
            Text("Select Score Goal")
                .font(.title).bold()
            
            Text("Choose how many points you need to finish the game.")
                .foregroundColor(.secondary)
            
            Button("Game Start") {
                // 알림창(또는 Sheet 등)으로 5/10/15 중 선택
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
    
    /// 실제 게임 스크롤 화면
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
            
            // 스크롤 영역 (대략 7개 표시)
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
            // 게임 시작 초기화
            startGame(goal: goal)
        }
    }
    
    /// 게임 종료 화면
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
extension ScrollViewGame {
    
    /// iPhone -> Vision
    private func processMessage(_ message: String) {
        if message.hasPrefix("SCROLL_SELECT:") {
            if let data = message.split(separator: ":").last,
               let number = Int(data.trimmingCharacters(in: .whitespacesAndNewlines)) {
                scrollToNumber(number)
                // iPhone에서 이미 중앙이라 판단 => 즉시 점수 처리
                if let target = targetNumber, target == number {
                    handleScored()
                }
            }
        }
    }
    
    /// 게임 시작(점수 골 설정)
    private func startGame(goal: Int) {
        // 매번 onAppear가 호출될 수 있으므로, 중복 방지
        if startTime == nil {
            // 실제 게임 시작 시간
            startTime = Date()
            // 첫 목표 생성
            generateNewTarget()
            score = 0
            gameOver = false
        }
    }
    
    /// Goal 선택 알림창 (5, 10, 15)
    private func showGoalSelectionAlert() {
        // SwiftUI에선 간단히 Alert + .confirmationDialog, or .sheet
        // 여기서는 .alert 예시
        // (프로젝트 상황에 맞춰 .confirmationDialog 등으로 바꿀 수 있음)
        
        let alert = UIAlertController(title: "Select Task Score",
                                      message: "Pick total points to finish",
                                      preferredStyle: .alert)
        
        // 세 가지 액션
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
        
        // UIKit 방식으로 Alert 표시
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(alert, animated: true, completion: nil)
        }
    }
    
    /// 특정 숫자로 스크롤 (원격 스크롤)
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
    
    /// Vision 직접 스크롤 중, 중앙 근처 숫자 감지
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
            
            // 0.5초 후 점수 처리
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
    
    /// 목표를 맞추었을 때 점수 +1
    private func handleScored() {
        score += 1
        if let goal = scoreGoal, score >= goal {
            endGame()
        } else {
            generateNewTarget()
        }
    }
    
    /// 게임 종료 -> 시간 계산
    private func endGame() {
        gameOver = true
        if let start = startTime {
            gameTime = Date().timeIntervalSince(start)
        }
    }
    
    /// 새 목표 숫자
    private func generateNewTarget() {
        let rand = Int.random(in: 3...48)
        targetNumber = rand
    }
    
    /// 게임 리셋 -> 다시 점수 선택 화면
    private func resetGame() {
        // 점수Goal을 nil로 해서, startView로 돌아감
        scoreGoal = nil
        score = 0
        gameOver = false
        targetNumber = nil
        gameTime = 0
        startTime = nil
    }
    
    /// 목표 숫자면 빨간 배경, 아니면 초록
    private func targetBackground(num: Int) -> Color {
        if let target = targetNumber, target == num {
            return Color.red.opacity(0.3)
        } else {
            return Color.green.opacity(0.2)
        }
    }
}
