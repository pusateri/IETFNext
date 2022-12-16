//
//  WebView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/29/22.
//

import SwiftUI
import WebKit


extension WKWebView {
    func load(_ url: URL) {
        let request = URLRequest(url: url)
        load(request)
    }
}

struct WebView: UIViewRepresentable {
    @Binding var url: URL?
    @Binding var html: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.dataDetectorTypes = [.link]

        return WKWebView(frame: .zero, configuration:webConfiguration)
    }

    func updateUIView(_ uiView : WKWebView , context : Context) {
        uiView.navigationDelegate = context.coordinator
        if html.count != 0 {
            uiView.loadHTMLString(html, baseURL: nil)
        } else if let url = url {
            uiView.load(url)
        }
    }

    class Coordinator : NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // open all links not described here in Safari
            if (url.host == "datatracker.ietf.org" &&
                    (url.path.starts(with: "/meeting") || url.path.starts(with: "/doc/html/"))) ||
                (url.host == "www.ietf.org") ||
                (url.scheme == "about") {
                decisionHandler(.allow)
                return
            }
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}
