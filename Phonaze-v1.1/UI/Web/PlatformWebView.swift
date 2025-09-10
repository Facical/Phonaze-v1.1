import SwiftUI
import WebKit
import Combine

struct PlatformWebView: View {
    let platform: StreamingPlatform?
    @StateObject private var model = WebViewModel()
    
    @EnvironmentObject private var connectivity: ConnectivityManager
    @EnvironmentObject private var focusTracker: FocusTracker
    @EnvironmentObject private var experimentSession: ExperimentSession
    
    @State private var notiCancellables = Set<AnyCancellable>()
    @State private var showExitConfirmation = false
    @State private var currentMode: InteractionMode = .directTouch

    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Web View - Full screen
            WebView(
                platform: platform,
                model: model,
                onBack: onBack
            )
            .ignoresSafeArea() // Full screen web view
            
            // Navigation toolbar overlay - positioned at top
            VStack {
                navigationToolbar
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea(.container, edges: .top) // Extend to top edge
                Spacer()
            }
        }
        .onAppear {
            setupMessageHandlers()
        }
        .onChange(of: connectivity.lastReceivedMessage) { _, msg in
            handleLegacyMessage(msg)
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
            // Exit button
            Button(action: { showExitConfirmation = true }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.red.opacity(0.8)))
            }
            
            // Page title or URL
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
            
            // Mode indicator
            HStack(spacing: 4) {
                Image(systemName: currentMode == .phonaze ? "iphone" :
                                 currentMode == .pinch ? "hand.pinch" : "hand.tap")
                    .font(.system(size: 12))
                Text(currentMode == .phonaze ? "Phone" :
                     currentMode == .pinch ? "Pinch" : "Touch")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.blue.opacity(0.8)))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .padding(.top, 50) // Account for Dynamic Island/notch
    }
    
    private func setupMessageHandlers() {
        NotificationCenter.default.publisher(for: Notification.Name("InteractionModeChanged"))
            .sink { note in
                if let mode = note.object as? InteractionMode {
                    currentMode = mode
                }
            }.store(in: &notiCancellables)
    }
    
    private func handleLegacyMessage(_ message: String) {
        // Handle iPhone remote control messages
        guard message.hasPrefix("WEB_") else { return }
        
        // Post notification for WebView to handle
        NotificationCenter.default.post(
            name: Notification.Name("RemoteWebCommand"),
            object: nil,
            userInfo: ["message": message]
        )
    }
    
    private func getSimplifiedURL(_ urlString: String) -> String {
        if let url = URL(string: urlString),
           let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return urlString
    }
}

// MARK: - Native WebView with proper interaction
struct WebView: UIViewRepresentable {
    let platform: StreamingPlatform?
    let model: WebViewModel
    var onBack: (() -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        // Create configuration
        let config = WKWebViewConfiguration()
        
        // Enable JavaScript
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Media settings
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Content mode
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // Process pool for better performance
        config.processPool = WKProcessPool()
        
        // User content controller for JavaScript injection
        let userContentController = WKUserContentController()
        
        // Add user scripts for better interaction
        let interactionScript = """
        (function() {
            // Improve touch handling
            document.addEventListener('touchstart', function() {}, {passive: false});
            
            // Make all interactive elements more responsive
            var style = document.createElement('style');
            style.innerHTML = `
                a, button, input, textarea, select, [onclick], [role="button"] {
                    -webkit-tap-highlight-color: rgba(0,0,0,0.1);
                    cursor: pointer;
                }
                input, textarea {
                    -webkit-user-select: text;
                    user-select: text;
                }
                * {
                    -webkit-touch-callout: none;
                    -webkit-user-select: none;
                }
                input, textarea {
                    -webkit-user-select: text !important;
                    -webkit-touch-callout: default !important;
                }
            `;
            document.head.appendChild(style);
            
            // Fix modal/overlay interactions
            document.addEventListener('click', function(e) {
                // Force click through to underlying elements
                if (e.target.classList.contains('overlay') || 
                    e.target.classList.contains('modal-backdrop')) {
                    e.stopPropagation();
                }
            }, true);
            
            // Ensure forms are interactive
            document.querySelectorAll('input, textarea').forEach(function(el) {
                el.addEventListener('focus', function() {
                    this.removeAttribute('readonly');
                    this.removeAttribute('disabled');
                });
            });
            
            // Fix viewport for better interaction
            var viewport = document.querySelector('meta[name="viewport"]');
            if (!viewport) {
                viewport = document.createElement('meta');
                viewport.name = 'viewport';
                document.head.appendChild(viewport);
            }
            viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
        })();
        """
        
        let userScript = WKUserScript(
            source: interactionScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(userScript)
        config.userContentController = userContentController
        
        // Create web view with configuration
        let webView = WKWebView(frame: .zero, configuration: config)
        
        // Set delegates
        webView.navigationDelegate = model
        webView.uiDelegate = model
        
        // Configure web view properties
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.isMultipleTouchEnabled = true
        webView.scrollView.alwaysBounceVertical = false
        
        // Set user agent for better compatibility
        webView.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        
        // Load initial URL
        if let platform = platform {
            model.load(platform: platform, in: webView)
        }
        
        // Store reference for coordinator
        context.coordinator.webView = webView
        
        // Listen for remote commands
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleRemoteCommand(_:)),
            name: Notification.Name("RemoteWebCommand"),
            object: nil
        )
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        weak var webView: WKWebView?
        
        // MARK: - Remote Commands
        @objc func handleRemoteCommand(_ notification: Notification) {
            guard let message = notification.userInfo?["message"] as? String,
                  let webView = webView else { return }
            
            if message.hasPrefix("WEB_NAV:") {
                let cmd = String(message.dropFirst("WEB_NAV:".count))
                switch cmd {
                case "BACK": webView.goBack()
                case "FORWARD": webView.goForward()
                case "RELOAD": webView.reload()
                default: break
                }
            } else if message.hasPrefix("WEB_URL:") {
                let urlString = String(message.dropFirst("WEB_URL:".count))
                if let url = URL(string: urlString) {
                    webView.load(URLRequest(url: url))
                }
            } else if message.hasPrefix("WEB_SCROLL:") {
                let body = String(message.dropFirst("WEB_SCROLL:".count))
                let parts = body.split(separator: ",")
                if parts.count == 2,
                   let dx = Double(parts[0].trimmingCharacters(in: .whitespaces)),
                   let dy = Double(parts[1].trimmingCharacters(in: .whitespaces)) {
                    let js = "window.scrollBy(\(dx), \(dy));"
                    webView.evaluateJavaScript(js, completionHandler: nil)
                }
            } else if message.hasPrefix("WEB_TAP:") {
                let body = String(message.dropFirst("WEB_TAP:".count))
                let parts = body.split(separator: ",")
                if parts.count == 2,
                   let nx = Double(parts[0].trimmingCharacters(in: .whitespaces)),
                   let ny = Double(parts[1].trimmingCharacters(in: .whitespaces)) {
                    let js = """
                    (function() {
                        var x = window.innerWidth * \(nx);
                        var y = window.innerHeight * \(ny);
                        var element = document.elementFromPoint(x, y);
                        if (element) {
                            element.click();
                            if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
                                element.focus();
                            }
                        }
                    })();
                    """
                    webView.evaluateJavaScript(js, completionHandler: nil)
                }
            }
        }
    }
}
