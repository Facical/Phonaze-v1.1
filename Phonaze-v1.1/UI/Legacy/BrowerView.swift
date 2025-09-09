import SwiftUI
import WebKit

final class WebModel: ObservableObject {
    fileprivate weak var webView: WKWebView?
}

struct BrowserView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @StateObject private var model = WebModel()

    // 로컬(헤드셋 내) URL 바 상태
    @State private var urlText: String = "https://www.apple.com"
    @State private var showToolbar: Bool = true   // 필요 시 토글해서 숨김/표시

    var body: some View {
        ZStack(alignment: .top) {
            BrowserRepresentable(model: model)
                .onChange(of: connectivity.lastReceivedMessage) { msg in
                    handle(message: msg)
                }
                .onAppear {
                    // iPhone 없이도 기본 홈을 자동 로드
                    if let url = URL(string: urlText) {
                        model.webView?.load(URLRequest(url: url))
                    }
                }

            // === 간단한 툴바(주소창 + 내비) ===
            if showToolbar {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button { goBack() } label: {
                            Image(systemName: "chevron.backward")
                        }.disabled(!(model.webView?.canGoBack ?? false))

                        Button { goForward() } label: {
                            Image(systemName: "chevron.forward")
                        }.disabled(!(model.webView?.canGoForward ?? false))

                        Button { reload() } label: {
                            Image(systemName: "arrow.clockwise")
                        }

                        TextField("URL 입력 또는 검색어", text: $urlText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .onSubmit(loadFromText)
                            .textFieldStyle(.roundedBorder)

                        Button { loadFromText() } label: {
                            Image(systemName: "arrow.right.circle.fill").font(.title3)
                        }
                    }
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - 로컬(헤드셋) 내비/로드
    private func loadFromText() {
        let t = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let final: String
        if t.contains("://") {
            final = t
        } else if t.contains(" ") == false, t.contains(".") {
            final = "https://\(t)"
        } else {
            let q = t.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            final = "https://www.google.com/search?q=\(q)"
        }
        if let url = URL(string: final) {
            model.webView?.load(URLRequest(url: url))
            urlText = final
        }
    }

    private func goBack()    { if model.webView?.canGoBack == true    { model.webView?.goBack() } }
    private func goForward() { if model.webView?.canGoForward == true { model.webView?.goForward() } }
    private func reload()    { model.webView?.reload() }

    // MARK: - iPhone 원격 메시지 처리
    private func handle(message: String) {
        guard let web = model.webView else { return }

        if message.hasPrefix("WEB_URL:") {
            let u = String(message.dropFirst("WEB_URL:".count)).trimmingCharacters(in: .whitespaces)
            if let url = URL(string: u) {
                urlText = u
                web.load(URLRequest(url: url))
            }
            return
        }

        if message == "WEB_NAV:BACK"     { goBack();    return }
        if message == "WEB_NAV:FORWARD"  { goForward(); return }
        if message == "WEB_NAV:RELOAD"   { reload();    return }

        // WEB_SCROLL 처리부만 교체
        if message.hasPrefix("WEB_SCROLL:") {
            let body = message.dropFirst("WEB_SCROLL:".count)
            let parts = body.split(separator: ",")
            if parts.count == 2,
               let dx = Double(parts[0]), let dy = Double(parts[1]) {

                let sv = web.scrollView
                let cur = sv.contentOffset
                let next = CGPoint(
                    x: max(0, min(cur.x + CGFloat(dx), sv.contentSize.width  - sv.bounds.width)),
                    y: max(0, min(cur.y + CGFloat(dy), sv.contentSize.height - sv.bounds.height))
                )
                // ✅ 끊김 방지: 매 프레임 애니메이션 금지
                sv.setContentOffset(next, animated: false)
            }
            return
        }

        // WEB_TAP 처리부만 교체
        if message.hasPrefix("WEB_TAP:") {
            let body = message.dropFirst("WEB_TAP:".count)
            let parts = body.split(separator: ",")
            if parts.count == 2,
               let nx = Double(parts[0]), let ny = Double(parts[1]) {

                let js = """
                (function(){
                  var x = window.innerWidth  * \(nx);
                  var y = window.innerHeight * \(ny);
                  var el = document.elementFromPoint(x, y);
                  if(!el) return false;
                  el.focus();

                  function fire(type){
                    var evt = new MouseEvent(type, {
                      bubbles:true, cancelable:true, view:window,
                      clientX:x, clientY:y, button:0
                    });
                    el.dispatchEvent(evt);
                  }
                  fire('pointerdown'); fire('mousedown');
                  fire('pointerup');   fire('mouseup');
                  fire('click');
                  return true;
                })();
                """
                web.evaluateJavaScript(js, completionHandler: nil)
            }
            return
        }

        if message.hasPrefix("WEB_TYPE:") {
            let raw = String(message.dropFirst("WEB_TYPE:".count))
            let text = raw
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "$", with: "\\$")
                .replacingOccurrences(of: "\n", with: "\\n")

            let js = """
            (function(){
              var a = document.activeElement;
              if(!a) return;
              if(a.isContentEditable){
                a.innerText = (a.innerText || '') + `\(text)`;
              } else if(a.tagName==='INPUT' || a.tagName==='TEXTAREA'){
                a.value = (a.value || '') + `\(text)`;
                a.dispatchEvent(new Event('input', {bubbles:true}));
              }
            })();
            """
            web.evaluateJavaScript(js, completionHandler: nil)
            return
        }

        if message == "WEB_KEY:ENTER" {
            let js = """
            (function(){
              var d=document.activeElement;
              if(!d) return;
              d.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter',code:'Enter',which:13,keyCode:13,bubbles:true}));
              d.dispatchEvent(new KeyboardEvent('keyup',  {key:'Enter',code:'Enter',which:13,keyCode:13,bubbles:true}));
            })();
            """
            web.evaluateJavaScript(js, completionHandler: nil)
            return
        }
    }
}

struct BrowserRepresentable: UIViewRepresentable {
    @ObservedObject var model: WebModel

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didStartProvisionalNavigation nav: WKNavigation!) {
            print("WKWebView start -> \(webView.url?.absoluteString ?? "nil")")
        }
        func webView(_ webView: WKWebView, didFinish nav: WKNavigation!) {
            print("WKWebView finish -> \(webView.url?.absoluteString ?? "nil")")
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation nav: WKNavigation!, withError error: Error) {
            print("WKWebView fail(provisional) -> \(error.localizedDescription)")
        }
        func webView(_ webView: WKWebView, didFail nav: WKNavigation!, withError error: Error) {
            print("WKWebView fail -> \(error.localizedDescription)")
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let conf = WKWebViewConfiguration()
        conf.allowsInlineMediaPlayback = true

        let v = WKWebView(frame: .zero, configuration: conf)
        v.navigationDelegate = context.coordinator

        // MR 시각 보정
        v.isOpaque = false
        v.backgroundColor = .clear
        v.scrollView.backgroundColor = .clear

        v.allowsBackForwardNavigationGestures = true
        model.webView = v
        return v
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
