import SwiftUI
import WebKit
import Combine

struct PlatformWebView: View {
    let platform: StreamingPlatform?
    @StateObject private var model = WebViewModel()
    @State private var webView = WKWebView(frame: .zero)

    @EnvironmentObject private var connectivity: ConnectivityManager
    @State private var notiCancellables = Set<AnyCancellable>()

    var body: some View {
        ZStack(alignment: .top) {
            WebViewContainer(webView: $webView, model: model)
                .ignoresSafeArea()

            HStack(spacing: 12) {
                Button(action: { model.goBack(webView) }) { Image(systemName: "chevron.left") }
                    .disabled(!model.canGoBack)
                Button(action: { model.goForward(webView) }) { Image(systemName: "chevron.right") }
                    .disabled(!model.canGoForward)
                Button(action: { model.reload(webView) }) { Image(systemName: "arrow.clockwise") }

                Text(model.pageTitle.isEmpty ? model.urlString : model.pageTitle)
                    .lineLimit(1)
                    .font(.callout)
                    .opacity(0.8)
                Spacer()
                if model.isLoading {
                    ProgressView().scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            configureWebView(webView)
            if let p = platform {
                model.load(urlString: p.urlString, in: webView)
            } else if model.urlString.isEmpty {
                model.load(urlString: StreamingPlatform.youtube.urlString, in: webView)
            }
            installNotificationBridges()
        }
        .onChange(of: connectivity.lastReceivedMessage) { _, new in
            handleLegacyWebMessage(new)
        }
    }

    private func configureWebView(_ webView: WKWebView) {
        let conf = webView.configuration
        conf.allowsInlineMediaPlayback = true
        conf.mediaTypesRequiringUserActionForPlayback = []
        conf.defaultWebpagePreferences.preferredContentMode = .mobile
        webView.navigationDelegate = model
        webView.uiDelegate = model
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.bounces = true
        webView.scrollView.decelerationRate = .normal
    }

    private func installNotificationBridges() {
        NotificationCenter.default.publisher(for: Notification.Name("EXP_SCROLL_H"))
            .sink { note in
                guard let dx = note.userInfo?["dx"] as? Double else { return }
                let js = WebMessageBridge.scrollJS(dx: dx, dy: 0)
                webView.evaluateJavaScript(js, completionHandler: nil)
            }.store(in: &notiCancellables)

        NotificationCenter.default.publisher(for: Notification.Name("EXP_SCROLL_V"))
            .sink { note in
                guard let dy = note.userInfo?["dy"] as? Double else { return }
                let js = WebMessageBridge.scrollJS(dx: 0, dy: dy)
                webView.evaluateJavaScript(js, completionHandler: nil)
            }.store(in: &notiCancellables)

        NotificationCenter.default.publisher(for: Notification.Name("EXP_TAP"))
            .sink { note in
                guard
                    let nx = note.userInfo?["nx"] as? Double,
                    let ny = note.userInfo?["ny"] as? Double
                else { return }
                let js = WebMessageBridge.clickJS(nx: nx, ny: ny)
                webView.evaluateJavaScript(js, completionHandler: nil)
            }.store(in: &notiCancellables)
    }

    private func handleLegacyWebMessage(_ message: String) {
        guard message.hasPrefix("WEB_") else { return }
        if message.hasPrefix("WEB_SCROLL:") {
            let body = String(message.dropFirst("WEB_SCROLL:".count))
            let parts = body.split(separator: ",")
            if parts.count == 2,
               let dx = Double(parts[0].trimmingCharacters(in: .whitespaces)),
               let dy = Double(parts[1].trimmingCharacters(in: .whitespaces)) {
                let js = WebMessageBridge.scrollJS(dx: dx, dy: dy)
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        } else if message.hasPrefix("WEB_TAP:") {
            let body = String(message.dropFirst("WEB_TAP:".count))
            let parts = body.split(separator: ",")
            if parts.count == 2,
               let nx = Double(parts[0].trimmingCharacters(in: .whitespaces)),
               let ny = Double(parts[1].trimmingCharacters(in: .whitespaces)) {
                let js = WebMessageBridge.clickJS(nx: nx, ny: ny)
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }
    }
}

private struct WebViewContainer: UIViewRepresentable {
    @Binding var webView: WKWebView
    let model: WebViewModel
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
