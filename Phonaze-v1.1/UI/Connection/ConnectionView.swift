import SwiftUI

struct ConnectionView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    
    // HomeView로 이동을 위한 상태 변수
    @State private var navigateToHome = false

    var body: some View {
        VStack(spacing: 20) {
            if connectivity.isConnected {
                // 연결 성공 시
                Image(systemName: "iphone.gen3.radiowaves.left.and.right.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                Text("iPhone 연결 성공!")
                    .font(.largeTitle)
                Text("잠시 후 게임 메뉴로 이동합니다.")
                    .font(.title2)
            } else {
                // 연결 대기 중
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                Text("iPhone을 연결해주세요...")
                    .font(.largeTitle)
                    .padding(.top, 30)
                Text("iPhone 앱에서 'Vision Pro에 연결' 버튼을 눌러주세요.")
                    .font(.headline)
            }
        }
        .padding(50)
        .navigationBarHidden(true)
        .onChange(of: connectivity.isConnected) { isConnected in
            // isConnected 상태가 true로 변경되면, 2초 후에 navigateToHome을 true로 설정
            if isConnected {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.navigateToHome = true
                }
            }
        }
        // HomeView로의 네비게이션 링크
        .navigationDestination(isPresented: $navigateToHome) {
            HomeView()
        }
    }
}
