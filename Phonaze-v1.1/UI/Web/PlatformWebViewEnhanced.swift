// Phonaze-v1.1/UI/Web/PlatformWebViewEnhanced.swift

import SwiftUI
import WebKit
import Combine

struct PlatformWebViewEnhanced: View {
    let platform: StreamingPlatform?
    @StateObject private var model = WebViewModel()
    @StateObject private var tracker = UnintendedSelectionTracker()
    
    @EnvironmentObject private var connectivity: ConnectivityManager
    @EnvironmentObject private var experimentSession: ExperimentSession
    
    // Timer states
    @State private var isTimerActive = false
    @State private var timeRemaining: Int = 300 // 5 minutes in seconds
    @State private var sessionTimer: Timer?
    @State private var showTimeUpAlert = false
    @State private var showExitConfirmation = false
    
    // Tracking states
    @State private var sessionStartTime: Date?
    @State private var pageVisits: [PageVisit] = []
    @State private var interactions: [InteractionLog] = []
    
    var onBack: (() -> Void)? = nil
    var onSessionComplete: ((BrowsingSessionData) -> Void)? = nil
    
    struct PageVisit {
        let url: String
        let title: String
        let timestamp: Date
        let duration: TimeInterval?
    }
    
    struct InteractionLog {
        let type: String // "tap", "scroll", "navigation"
        let timestamp: Date
        let details: String
    }
    
    struct BrowsingSessionData {
        let platform: String
        let totalDuration: TimeInterval
        let pagesVisited: Int
        let totalInteractions: Int
        let unintendedSelections: Int
        let pageVisits: [PageVisit]
        let interactions: [InteractionLog]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced navigation toolbar with timer
            navigationToolbarWithTimer
            
            // WebView with tracking
            WebViewWithTracking(
                platform: platform,
                model: model,
                tracker: tracker,
                onInteraction: logInteraction
            )
        }
        .onAppear {
            startBrowsingSession()
        }
        .onDisappear {
            endBrowsingSession()
        }
        .alert("Time's Up!", isPresented: $showTimeUpAlert) {
            Button("OK") {
                endBrowsingSession()
                onBack?()
            }
        } message: {
            Text("Your 5-minute browsing session has ended.")
        }
        .alert("Exit Browsing Session?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                endBrowsingSession()
                onBack?()
            }
        } message: {
            Text("Are you sure you want to exit? Your session data will be saved.")
        }
    }
    
    // MARK: - Enhanced Navigation Toolbar
    
    private var navigationToolbarWithTimer: some View {
        HStack(spacing: 12) {
            // Exit button
            Button(action: { showExitConfirmation = true }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.red.opacity(0.8)))
            }
            
            // Loading indicator
            if model.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            // Page title/URL
            Text(model.pageTitle.isEmpty ? getSimplifiedURL(model.urlString) : model.pageTitle)
                .lineLimit(1)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
            
            // Timer display
            if isTimerActive {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 14))
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(timeRemaining < 60 ? .red : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(timeRemaining < 60 ? Color.red.opacity(0.2) : Color.white.opacity(0.15))
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Session Management
    
    private func startBrowsingSession() {
        sessionStartTime = Date()
        isTimerActive = true
        timeRemaining = 300
        tracker.startTracking()
        
        // Log session start
        experimentSession.log(
            kind: "browsing_session_start",
            payload: [
                "platform": platform?.rawValue ?? "unknown",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        // Start countdown timer
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // Warning at 1 minute
                if timeRemaining == 60 {
                    provideHapticFeedback()
                }
                
                // Session end
                if timeRemaining == 0 {
                    showTimeUpAlert = true
                    sessionTimer?.invalidate()
                }
            }
        }
    }
    
    private func endBrowsingSession() {
        sessionTimer?.invalidate()
        isTimerActive = false
        tracker.stopTracking()
        
        guard let startTime = sessionStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        
        // Compile session data
        let sessionData = BrowsingSessionData(
            platform: platform?.rawValue ?? "unknown",
            totalDuration: duration,
            pagesVisited: pageVisits.count,
            totalInteractions: interactions.count,
            unintendedSelections: tracker.unintendedSelections.count,
            pageVisits: pageVisits,
            interactions: interactions
        )
        
        // Log session end
        experimentSession.log(
            kind: "browsing_session_end",
            payload: [
                "platform": platform?.rawValue ?? "unknown",
                "duration": "\(Int(duration))",
                "pages_visited": "\(pageVisits.count)",
                "interactions": "\(interactions.count)",
                "unintended_selections": "\(tracker.unintendedSelections.count)"
            ]
        )
        
        // Export unintended selections
        if let csvURL = tracker.exportToCSV() {
            print("📊 Exported unintended selections: \(csvURL.lastPathComponent)")
        }
        
        // Callback with session data
        onSessionComplete?(sessionData)
    }
    
    // MARK: - Interaction Logging
    
    private func logInteraction(type: String, details: String) {
        let interaction = InteractionLog(
            type: type,
            timestamp: Date(),
            details: details
        )
        interactions.append(interaction)
        
        // Also log to experiment session
        experimentSession.log(
            kind: "browsing_interaction",
            payload: [
                "type": type,
                "details": details,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
    }
    
    private func logPageVisit(url: String, title: String) {
        // Close previous visit duration
        if !pageVisits.isEmpty {
            let lastIndex = pageVisits.count - 1
            let duration = Date().timeIntervalSince(pageVisits[lastIndex].timestamp)
            pageVisits[lastIndex] = PageVisit(
                url: pageVisits[lastIndex].url,
                title: pageVisits[lastIndex].title,
                timestamp: pageVisits[lastIndex].timestamp,
                duration: duration
            )
        }
        
        // Add new visit
        let visit = PageVisit(
            url: url,
            title: title,
            timestamp: Date(),
            duration: nil
        )
        pageVisits.append(visit)
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func getSimplifiedURL(_ urlString: String) -> String {
        if let url = URL(string: urlString), let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return urlString
    }
    
    private func provideHapticFeedback() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
    }
}

// MARK: - Enhanced WebView with Tracking

struct WebViewWithTracking: UIViewRepresentable {
    let platform: StreamingPlatform?
    let model: WebViewModel
    let tracker: UnintendedSelectionTracker
    let onInteraction: (String, String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = model
        webView.allowsBackForwardNavigationGestures = true
        
        // Set up interaction tracking
        context.coordinator.setup(webView: webView, tracker: tracker, onInteraction: onInteraction)
        
        if let platform = platform {
            model.load(platform: platform, in: webView)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let model: WebViewModel
        weak var webView: WKWebView?
        var tracker: UnintendedSelectionTracker?
        var onInteraction: ((String, String) -> Void)?
        private var cancellables = Set<AnyCancellable>()
        
        init(model: WebViewModel) {
            self.model = model
        }
        
        func setup(webView: WKWebView, tracker: UnintendedSelectionTracker, onInteraction: @escaping (String, String) -> Void) {
            self.webView = webView
            self.tracker = tracker
            self.onInteraction = onInteraction
            setupRemoteControlHandlers()
            injectTrackingScript(into: webView)
        }
        
        // Navigation delegate methods
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            model.isLoading = false
            model.canGoBack = webView.canGoBack
            model.canGoForward = webView.canGoForward
            model.pageTitle = webView.title ?? ""
            if let url = webView.url?.absoluteString {
                model.urlString = url
                onInteraction?("navigation", url)
            }
            
            // Re-inject tracking on new page
            injectTrackingScript(into: webView)
        }
        
        private func setupRemoteControlHandlers() {
            // Handle scroll events
            NotificationCenter.default.publisher(for: ConnectivityManager.Noti.scrollH)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] notification in
                    self?.tracker?.recordScroll()
                    if let dx = notification.userInfo?["dx"] as? Double {
                        self?.onInteraction?("scroll", "horizontal: \(dx)")
                    }
                }
                .store(in: &cancellables)
            
            NotificationCenter.default.publisher(for: ConnectivityManager.Noti.scrollV)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] notification in
                    self?.tracker?.recordScroll()
                    if let dy = notification.userInfo?["dy"] as? Double {
                        self?.onInteraction?("scroll", "vertical: \(dy)")
                    }
                }
                .store(in: &cancellables)
            
            // Handle tap events
            NotificationCenter.default.publisher(for: ConnectivityManager.Noti.hoverTap)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.onInteraction?("tap", "hover_tap")
                    // Check for accidental tap during scroll
                    _ = self?.tracker?.checkTapDuringScroll(elementID: nil)
                }
                .store(in: &cancellables)
        }
        
        private func injectTrackingScript(into webView: WKWebView) {
            let script = """
            (function() {
                // Track all clicks
                document.addEventListener('click', function(e) {
                    var target = e.target;
                    var info = {
                        tagName: target.tagName,
                        id: target.id || 'none',
                        className: target.className || 'none',
                        text: target.innerText ? target.innerText.substring(0, 50) : 'none'
                    };
                    console.log('Click tracked:', JSON.stringify(info));
                }, true);
                
                // Track hover events for dwell detection
                var hoverTimer = null;
                var hoveredElement = null;
                
                document.addEventListener('mouseover', function(e) {
                    hoveredElement = e.target;
                    hoverTimer = setTimeout(function() {
                        console.log('Dwell detected on:', hoveredElement.tagName);
                    }, 1500);
                }, true);
                
                document.addEventListener('mouseout', function(e) {
                    if (hoverTimer) {
                        clearTimeout(hoverTimer);
                        hoverTimer = null;
                    }
                }, true);
            })();
            """
            
            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    print("Failed to inject tracking script: \(error)")
                }
            }
        }
    }
}
