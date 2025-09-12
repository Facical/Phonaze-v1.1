// Phonaze-v1.1/UI/Web/PlatformWebView.swift

import SwiftUI
import WebKit
import Combine

struct PlatformWebView: View {
    let platform: StreamingPlatform?
    @StateObject private var model = WebViewModel()
    
    @EnvironmentObject private var connectivity: ConnectivityManager
    @State private var showExitConfirmation = false
    @State private var coordinator: WebView.Coordinator?

    var onBack: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            navigationToolbar
            
            // ✅ WebView with coordinator binding
            WebView(platform: platform, model: model, coordinatorBinding: $coordinator)
                .environmentObject(connectivity)
                .onAppear {
                    // ✅ Setup notifications after coordinator is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        coordinator?.setupNotifications()
                    }
                }
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
            
            // ✅ Debug buttons
            HStack(spacing: 8) {
                // Manual tap test
                Button(action: {
                    print("🔧 Debug: Manual tap test")
                    coordinator?.performNativeTap()
                }) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Manual scroll test
                Button(action: {
                    print("🔧 Debug: Manual scroll test")
                    coordinator?.performScroll(dx: 0, dy: 100)
                }) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
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
    @EnvironmentObject var connectivity: ConnectivityManager
    @Binding var coordinatorBinding: Coordinator?
    
    init(platform: StreamingPlatform?, model: WebViewModel, coordinatorBinding: Binding<Coordinator?>) {
        self.platform = platform
        self.model = model
        self._coordinatorBinding = coordinatorBinding
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // ✅ Enhanced configuration
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        configuration.preferences = preferences
        
        // Create WebView
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = model
        webView.uiDelegate = model
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        
        // ✅ Setup coordinator
        context.coordinator.webView = webView
        
        // ✅ Bind coordinator to parent view
        DispatchQueue.main.async {
            coordinatorBinding = context.coordinator
        }
        
        // Load platform
        if let platform = platform {
            model.load(platform: platform, in: webView)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // ✅ Enhanced Coordinator
    class Coordinator: NSObject {
        weak var webView: WKWebView?
        private var cancellables = Set<AnyCancellable>()
        private var notificationObservers: [NSObjectProtocol] = []
        
        override init() {
            super.init()
            print("✅ Coordinator initialized")
        }
        
        deinit {
            cleanup()
        }
        
        func setupNotifications() {
            // ✅ Clean up any existing observers
            cleanup()
            
            print("📱 Setting up notification observers...")
            
            // ✅ Use NotificationCenter directly instead of Combine
            let hoverTapObserver = NotificationCenter.default.addObserver(
                forName: ConnectivityManager.Noti.hoverTap,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                print("📱 [NC] Received hover tap notification")
                self?.performNativeTap()
            }
            notificationObservers.append(hoverTapObserver)
            
            let scrollHObserver = NotificationCenter.default.addObserver(
                forName: ConnectivityManager.Noti.scrollH,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                if let dx = notification.userInfo?["dx"] as? Double {
                    print("📱 [NC] Received scroll H: \(dx)")
                    self?.performScroll(dx: dx, dy: 0)
                }
            }
            notificationObservers.append(scrollHObserver)
            
            let scrollVObserver = NotificationCenter.default.addObserver(
                forName: ConnectivityManager.Noti.scrollV,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                if let dy = notification.userInfo?["dy"] as? Double {
                    print("📱 [NC] Received scroll V: \(dy)")
                    self?.performScroll(dx: 0, dy: dy)
                }
            }
            notificationObservers.append(scrollVObserver)
            
            let tapObserver = NotificationCenter.default.addObserver(
                forName: ConnectivityManager.Noti.tap,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                if let nx = notification.userInfo?["nx"] as? Double,
                   let ny = notification.userInfo?["ny"] as? Double {
                    print("📱 [NC] Received tap at: (\(nx), \(ny))")
                    self?.performTapAt(normalizedX: nx, normalizedY: ny)
                } else {
                    print("📱 [NC] Received tap (no coordinates)")
                    self?.performNativeTap()
                }
            }
            notificationObservers.append(tapObserver)
            
            print("✅ Notification observers setup complete")
        }
        
        private func cleanup() {
            // Remove notification observers
            for observer in notificationObservers {
                NotificationCenter.default.removeObserver(observer)
            }
            notificationObservers.removeAll()
            
            // Cancel Combine subscriptions
            cancellables.removeAll()
        }
        
        // ✅ Public methods for testing
        func performNativeTap() {
            guard let webView = webView else {
                print("❌ No webView available")
                return
            }
            
            let js = WebMessageBridge.nativeTapJS()
            
            webView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    print("❌ Native tap error: \(error.localizedDescription)")
                } else if let result = result {
                    print("✅ Native tap result: \(result)")
                }
            }
        }
        
        func performTapAt(normalizedX: Double, normalizedY: Double) {
            guard let webView = webView else {
                print("❌ No webView available")
                return
            }
            
            // Get viewport dimensions
            let js = """
            (function() {
                var x = \(normalizedX) * window.innerWidth;
                var y = \(normalizedY) * window.innerHeight;
                var element = document.elementFromPoint(x, y);
                if (element) {
                    element.click();
                    return 'Clicked at (' + x + ', ' + y + '): ' + element.tagName;
                }
                return 'No element at (' + x + ', ' + y + ')';
            })();
            """
            
            webView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    print("❌ Tap error: \(error.localizedDescription)")
                } else if let result = result {
                    print("✅ Tap result: \(result)")
                }
            }
        }
        
        func performScroll(dx: Double, dy: Double) {
            guard let webView = webView else {
                print("❌ No webView available for scroll")
                return
            }
            
            let js = WebMessageBridge.scrollJS(dx: dx, dy: dy)
            
            webView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    print("❌ Scroll error: \(error.localizedDescription)")
                } else if let result = result as? String {
                    print("✅ Scroll result: \(result)")
                }
            }
        }
    }
}
