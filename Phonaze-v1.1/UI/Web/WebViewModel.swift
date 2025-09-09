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
        // 필요 시 헤더 추가
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

// MARK: - WKNavigationDelegate / WKUIDelegate
extension WebViewModel: WKNavigationDelegate, WKUIDelegate {
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
        // 현재 URL 반영
        if let u = webView.url?.absoluteString { urlString = u }
        progress = 1
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // 메모리 압박 등으로 프로세스 리셋 시 재로드
        webView.reload()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        isLoading = true
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        // 필요 시 도메인 필터링/허용
        decisionHandler(.allow)
    }

    // 팝업/새 창 열기 처리
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
