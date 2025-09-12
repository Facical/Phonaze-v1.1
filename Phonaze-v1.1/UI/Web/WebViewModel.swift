// Phonaze-v1.1/UI/Web/WebViewModel.swift

import Foundation
import WebKit

final class WebViewModel: NSObject, ObservableObject {
    @Published var urlString: String = ""
    @Published var pageTitle: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var progress: Double = 0

    // MARK: - Load/Navigation
    func load(urlString: String, in webView: WKWebView) {
        self.urlString = urlString
        guard let url = URL(string: urlString) else { return }
        var req = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        
        // Netflix/YouTube용 User-Agent 설정 (모바일 버전 방지)
        if urlString.contains("netflix.com") || urlString.contains("youtube.com") {
            req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        }
        
        webView.load(req)
    }

    func load(platform: StreamingPlatform, in webView: WKWebView) {
        load(urlString: platform.urlString, in: webView)
    }
}

// MARK: - WKNavigationDelegate
extension WebViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        progress = 0
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        pageTitle = webView.title ?? ""
        if let u = webView.url?.absoluteString {
            urlString = u
        }
        progress = 1
        
        // ✅ 페이지 로드 완료 시 시선 추적 스크립트 주입
        injectGazeTrackingScript(into: webView)
        
        // 디버깅용 - 1초 후 hover 상태 확인
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkHoverState(in: webView)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        print("Navigation failed: \(error.localizedDescription)")
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        isLoading = true
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    // MARK: - Script Injection
    
    private func injectGazeTrackingScript(into webView: WKWebView) {
        let script = WebMessageBridge.enableGazeTrackingJS()
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Failed to inject gaze tracking: \(error.localizedDescription)")
            } else {
                print("✅ Gaze tracking script injected successfully")
                if let result = result {
                    print("   Result: \(result)")
                }
            }
        }
        
        // ✅ Netflix/YouTube 특별 처리 - self.urlString 사용
        if self.urlString.contains("netflix.com") || self.urlString.contains("youtube.com") {
            injectStreamingPlatformFixes(into: webView)
        }
    }
    
    // ✅ 스트리밍 플랫폼 특별 처리 메서드 추가
    private func injectStreamingPlatformFixes(into webView: WKWebView) {
        let script = """
        (function() {
            console.log('Applying streaming platform fixes');
            
            // Netflix 특별 처리
            if (window.location.hostname.includes('netflix.com')) {
                // 비디오 플레이어 컨트롤 개선
                var style = document.createElement('style');
                style.textContent = `
                    .watch-video--player-view button,
                    .watch-video--player-view a {
                        min-width: 60px !important;
                        min-height: 60px !important;
                    }
                    
                    /* 썸네일 호버 개선 */
                    .title-card-container {
                        transition: transform 0.2s ease !important;
                    }
                    
                    .title-card-container:hover {
                        transform: scale(1.05) !important;
                        z-index: 10 !important;
                    }
                `;
                document.head.appendChild(style);
            }
            
            // YouTube 특별 처리
            if (window.location.hostname.includes('youtube.com')) {
                // 모바일 레이아웃 방지
                Object.defineProperty(navigator, 'userAgent', {
                    get: function() { 
                        return 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15'; 
                    }
                });
                
                // 비디오 컨트롤 개선
                var style = document.createElement('style');
                style.textContent = `
                    .ytp-chrome-controls button {
                        min-width: 48px !important;
                        min-height: 48px !important;
                    }
                    
                    /* 비디오 썸네일 호버 개선 */
                    ytd-thumbnail:hover {
                        outline: 3px solid rgba(0, 122, 255, 0.5) !important;
                        outline-offset: 2px !important;
                    }
                    
                    /* 버튼 클릭 영역 확대 */
                    ytd-button-renderer {
                        padding: 8px !important;
                    }
                `;
                document.head.appendChild(style);
            }
            
            return 'Platform fixes applied';
        })();
        """
        
        webView.evaluateJavaScript(script) { result, error in
            if error == nil {
                print("✅ Streaming platform fixes applied")
            } else {
                print("❌ Failed to apply platform fixes: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    private func checkHoverState(in webView: WKWebView) {
        let script = WebMessageBridge.debugHoverStateJS()
        
        webView.evaluateJavaScript(script) { result, error in
            if let resultString = result as? String {
                print("🔍 Current hover state: \(resultString)")
            }
        }
    }
}

// MARK: - WKUIDelegate
extension WebViewModel: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("JS Alert: \(message)")
        completionHandler()
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        print("JS Confirm: \(message)")
        completionHandler(true)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        print("JS Prompt: \(prompt)")
        completionHandler(defaultText)
    }
}
