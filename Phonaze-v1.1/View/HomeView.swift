import SwiftUI
import UIKit
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct HomeView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @EnvironmentObject var gameState: GameState
    
    @State private var showWebView: Bool = false
    @State private var webURL: URL? = nil
    @State private var selectViewID = UUID()
    
    // 현재 모드를 텍스트로 변환하는 도우미 함수
    private var modeText: String {
        switch gameState.currentInteractionMethod {
        case .directTouch:
            return "직접 터치 모드"
        case .pinch:
            return "핀치 모드"
        case .phonaze:
            return "Phonaze 모드"
        case .none:
            return "모드 선택 안됨"
        }
    }
    
    var body: some View {
        HStack(spacing: 40) {
            VStack(spacing: 20) {
                Spacer()
            }
            .frame(minWidth: 140)
            .padding(.vertical, 40)
            
            VStack(spacing: 30) {
                Text("Phonaze 게임 메뉴")
                    .font(.title).bold()
                
                // 현재 모드 표시
                Text("(\(modeText))")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                // Select 게임으로 이동
                NavigationLink(destination: SelectView().id(selectViewID)) {
                    Label("패널 선택 게임 (Select)", systemImage: "square.grid.4x3.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                }
                .simultaneousGesture(TapGesture().onEnded { selectViewID = UUID() })
                // Scroll 게임으로 이동
                NavigationLink(destination: ScrollViewGame()) {
                    Label("숫자 찾기 게임 (Scroll)", systemImage: "number.circle")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(10)
                }
                
                // --- Divider와 버튼 추가 ---
                Divider().padding(.vertical, 10)
                
                Button(action: {
                    // Phonaze 모드였다면 연결 해제
                    if gameState.currentInteractionMethod == .phonaze {
                        connectivity.disconnect()
                    }
                    // StartView로 돌아가기 신호를 true로 설정
                    gameState.shouldReturnToStart = true
                }) {
                    Label("모드 다시 선택", systemImage: "arrow.uturn.backward.circle.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
            .padding(40)
        }
        .navigationTitle("🕹️ Home") // NavigationStack 상단에 제목 표시
        .navigationBarBackButtonHidden(true) // 뒤로가기 버튼 숨기기 (선택적)
        .onAppear {
            gameState.shouldReturnToStart = false
            // 게임 상태 초기화
            gameState.resetGame()
        }
        NavigationLink(
            destination: webURL.map { WebView(url: $0) },
            isActive: $showWebView
        ) {
            EmptyView()
        }
    }
}

