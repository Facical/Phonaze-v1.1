import SwiftUI

struct StartView: View {
    // GameState를 환경 객체로 받아옴
    @EnvironmentObject var gameState: GameState
    
    // HomeView로 넘어갈지 결정하는 상태 변수
    @State private var navigateToHome = false
    // ConnectionView로 넘어갈지 결정하는 상태 변수
    @State private var navigateToConnection = false

    var body: some View {
        VStack(spacing: 40) {
            Text("상호작용 모드를 선택하세요")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 50)

            // 1. 직접 터치 모드 버튼
            Button(action: {
                // 게임 상태에 모드 저장
                gameState.currentInteractionMethod = .directTouch
                // HomeView로 이동 트리거
                navigateToHome = true
            }) {
                Label("직접 터치 (Direct Touch)", systemImage: "hand.point.up.left.fill")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: 400)
                    .background(Color.orange.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }

            // 2. Pinch 모드 버튼
            Button(action: {
                gameState.currentInteractionMethod = .pinch
                navigateToHome = true
            }) {
                Label("핀치 (Pinch)", systemImage: "hand.pinch.fill")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: 400)
                    .background(Color.purple.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }

            // 3. Phonaze 모드 버튼
            Button(action: {
                gameState.currentInteractionMethod = .phonaze
                // ConnectionView로 이동 트리거
                navigateToConnection = true
            }) {
                Label("Phonaze (시선 + 스마트폰)", systemImage: "iphone.and.arrow.forward")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: 400)
                    .background(Color.cyan.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
        }
        .padding(50)
        // NavigationLink를 사용해 화면 전환 구현
        .navigationDestination(isPresented: $navigateToHome) {
            HomeView()
        }
        .navigationDestination(isPresented: $navigateToConnection) {
            ConnectionView()
        }
        .navigationBarHidden(true) // 시작 화면에서는 네비게이션 바를 숨김
    }
}

#Preview(windowStyle: .volumetric) {
    // 프리뷰에서도 NavigationStack과 EnvironmentObject를 설정해줘야 합니다.
    NavigationStack {
        StartView()
            .environmentObject(GameState())
            .environmentObject(ConnectivityManager())
    }
}
