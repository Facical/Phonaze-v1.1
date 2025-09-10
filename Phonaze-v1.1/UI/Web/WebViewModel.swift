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
        webView.load(req)
    }

    func load(platform: StreamingPlatform, in webView: WKWebView) {
        load(urlString: platform.urlString, in: webView)
    }

    func reload(_ webView: WKWebView) {
        webView.reload()
    }

    func goBack(_ webView: WKWebView) {
        if webView.canGoBack { webView.goBack() }
    }

    func goForward(_ webView: WKWebView) {
        if webView.canGoForward { webView.goForward() }
    }
}

// MARK: - WKNavigationDelegate
extension WebViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        progress = 0
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        pageTitle = webView.title ?? ""
        if let u = webView.url?.absoluteString { urlString = u }
        progress = 1
        
        // Inject enhancement script after page load
        let enhanceScript = """
        (function() {
            // Remove blocking overlays
            document.querySelectorAll('[class*="overlay"], [class*="modal-backdrop"]').forEach(function(el) {
                if (el.style.pointerEvents !== 'none') {
                    el.style.pointerEvents = 'none';
                }
            });
            
            // Make video controls accessible
            document.querySelectorAll('video').forEach(function(video) {
                video.setAttribute('controls', 'true');
            });
            
            // Fix close buttons
            document.querySelectorAll('[aria-label*="close"], [aria-label*="Close"], button[class*="close"]').forEach(function(btn) {
                btn.style.pointerEvents = 'auto';
                btn.style.zIndex = '999999';
            });
        })();
        """
        webView.evaluateJavaScript(enhanceScript, completionHandler: nil)
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
        completionHandler()
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}
