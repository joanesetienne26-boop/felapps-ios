import SwiftUI
import WebKit

@main
struct FelappApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            // Keep the web app inside the safe area so nothing hides
            // under the notch/status bar or the home indicator.
            WebViewContainer()
        }
    }
}

struct WebViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        // Lock the page to the device width and stop pinch/auto zoom,
        // so content never spills off the right edge.
        let viewportJS = """
        (function(){var m=document.querySelector('meta[name=viewport]');
        if(!m){m=document.createElement('meta');m.name='viewport';document.head.appendChild(m);}
        m.content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
        document.documentElement.style.webkitTextSizeAdjust='100%';})();
        """
        configuration.userContentController.addUserScript(
            WKUserScript(source: viewportJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = AppConfig.enableSwipeNavigation
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.delegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        if let url = URL(string: AppConfig.webUrl) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }
}

final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Loaded; nothing to do for now.
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { nil }
}
