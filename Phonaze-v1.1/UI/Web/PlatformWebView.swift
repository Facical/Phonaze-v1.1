// Phonaze-v1.1/UI/Web/PlatformWebView.swift

import SwiftUI
import WebKit
import Combine

struct PlatformWebView: View {
    let platform: StreamingPlatform?
    @StateObject private var model = WebViewModel()
    
    @EnvironmentObject private var connectivity: ConnectivityManager
    
    @State private var showExitConfirmation = false

    var onBack: (() -> Void)? = nil

    var body: some View {
        // ✅ [수정] ZStack을 VStack으로 변경하여 뷰가 겹치지 않게 합니다.
        VStack(spacing: 0) {
            // 1. 상단에 툴바를 먼저 배치합니다.
            navigationToolbar
            
            // 2. 그 아래에 WebView를 배치합니다.
            WebView(platform: platform, model: model)
        }
        .alert("Exit Web View?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                onBack?()
            }
        } message: {
            Text("Are you sure you want to exit?")
        }
    }
    
    private var navigationToolbar: some View {
        HStack(spacing: 12) {
            Button(action: { showExitConfirmation = true }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.red.opacity(0.8)))
            }
            
            if model.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            Text(model.pageTitle.isEmpty ? getSimplifiedURL(model.urlString) : model.pageTitle)
                .lineLimit(1)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        // ✅ [수정] VStack으로 변경했으므로, 불필요한 상단 여백(.padding(.top, 50))을 제거하고
        // 배경(.background)을 추가하여 UI를 완성합니다.
        .background(.ultraThinMaterial)
    }
    
    private func getSimplifiedURL(_ urlString: String) -> String {
        if let url = URL(string: urlString), let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return urlString
    }
}


// MARK: - WebView Representable
struct WebView: UIViewRepresentable {
    let platform: StreamingPlatform?
    let model: WebViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        // ✅ [수정] Vision Pro에서는 순정 WKWebView로 충분합니다.
        let webView = WKWebView()
        webView.navigationDelegate = model
        webView.uiDelegate = model
        
        // Coordinator가 WebView를 제어할 수 있도록 참조를 전달합니다.
        context.coordinator.setWebView(webView)

        if let platform = platform {
            model.load(platform: platform, in: webView)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // ✅ [수정] Coordinator가 아이폰의 원격 제어 신호를 처리합니다.
    class Coordinator: NSObject {
        weak var webView: WKWebView?
        private var cancellables = Set<AnyCancellable>()
        
        func setWebView(_ webView: WKWebView) {
            self.webView = webView
            setupRemoteControlHandlers()
        }

        // ConnectivityManager로부터 오는 Notification을 받아 WebView를 제어합니다.
        private func setupRemoteControlHandlers() {
            NotificationCenter.default.publisher(for: InteractionNoti.tap)
                .receive(on: DispatchQueue.main) 
                .sink { [weak self] notification in
                    guard let userInfo = notification.userInfo,
                          let nx = userInfo["nx"] as? Double,
                          let ny = userInfo["ny"] as? Double else { return }
                    
                    let js = WebMessageBridge.clickJS(nx: nx, ny: ny)
                    self?.webView?.evaluateJavaScript(js)
                }
                .store(in: &cancellables)
            
            NotificationCenter.default.publisher(for: InteractionNoti.scrollH)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] notification in
                    guard let userInfo = notification.userInfo,
                          let dx = userInfo["dx"] as? Double else { return }
                    let js = WebMessageBridge.scrollJS(dx: dx, dy: 0)
                    self?.webView?.evaluateJavaScript(js)
                }
                .store(in: &cancellables)

            NotificationCenter.default.publisher(for: InteractionNoti.scrollV)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] notification in
                    guard let userInfo = notification.userInfo,
                          let dy = userInfo["dy"] as? Double else { return }
                    let js = WebMessageBridge.scrollJS(dx: 0, dy: dy)
                    self?.webView?.evaluateJavaScript(js)
                }
                .store(in: &cancellables)
            NotificationCenter.default.publisher(for: ConnectivityManager.Noti.hoverTap)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    print("PlatformWebView: Executing hoverClickJS")
                    let js = WebMessageBridge.hoverClickJS()
                    self?.webView?.evaluateJavaScript(js) { result, error in
                        if let error = error {
                            print("HoverClick JS error: \(error)")
                        } else {
                            print("HoverClick JS executed successfully")
                        }
                    }
                }
                .store(in: &cancellables)
            
        }
    }
}
