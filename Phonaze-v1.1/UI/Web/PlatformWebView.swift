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
        VStack(spacing: 0) {
            navigationToolbar
            
            // ✅ 단순한 WebView - Vision Pro 네이티브 입력 활용
            WebView(platform: platform, model: model)
        }
        .alert("Exit Web View?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) { onBack?() }
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
        // ✅ Vision Pro에서는 순정 WKWebView로 충분합니다.
        let webView = WKWebView()
        webView.navigationDelegate = model
        webView.uiDelegate = model
        
        // ✅ 네이티브 Vision Pro 기능 활성화
        webView.allowsBackForwardNavigationGestures = true
        
        // Coordinator가 원격 제어 신호를 처리
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
    
    // ✅ 간소화된 Coordinator - iPhone의 간단한 신호만 처리
    class Coordinator: NSObject {
        weak var webView: WKWebView?
        private var cancellables = Set<AnyCancellable>()
        
        func setWebView(_ webView: WKWebView) {
            self.webView = webView
            setupRemoteControlHandlers()
        }
        
        private func setupRemoteControlHandlers() {
            // ✅ iPhone에서 오는 간단한 탭 신호 처리
            NotificationCenter.default.publisher(for: ConnectivityManager.Noti.hoverTap)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    print("📱 Received hover tap signal")
                    self?.performNativeTap()
                }
                .store(in: &cancellables)
            
            // ✅ 스크롤은 그대로 유지 (잘 작동함)
            NotificationCenter.default.publisher(for: ConnectivityManager.Noti.scrollH)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] notification in
                    guard let userInfo = notification.userInfo,
                          let dx = userInfo["dx"] as? Double else { return }
                    print("📱 Received scroll H: \(dx)")
                    let js = WebMessageBridge.scrollJS(dx: dx, dy: 0)
                    self?.webView?.evaluateJavaScript(js)
                }
                .store(in: &cancellables)
            
            NotificationCenter.default.publisher(for: ConnectivityManager.Noti.scrollV)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] notification in
                    guard let userInfo = notification.userInfo,
                          let dy = userInfo["dy"] as? Double else { return }
                    let js = WebMessageBridge.scrollJS(dx: 0, dy: dy)
                    self?.webView?.evaluateJavaScript(js)
                }
                .store(in: &cancellables)
        }
        
        // ✅ Vision Pro 네이티브 탭 - 현재 시선이 있는 곳을 자동으로 클릭
        // ✅ [수정] Vision Pro 네이티브 탭 - 단순화된 JS 실행
        private func performNativeTap() {
            guard let webView = webView else { return }
            
            let js = WebMessageBridge.nativeTapJS()
            
            webView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    print("Native tap JS error: \(error.localizedDescription)")
                }
                if let result = result {
                    print("Native tap result: \(result)")
                }
            }
        }
    }
}
