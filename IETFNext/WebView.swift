//
//  WebView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/29/22.
//

import SwiftUI
import WebKit

#if os(macOS)
struct WebView: NSViewRepresentable {
    @Binding var html: String
    @Binding var fileURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateNSView(_ nsView : WKWebView , context : Context) {
        nsView.navigationDelegate = context.coordinator
        if html.count != 0 {
            nsView.loadHTMLString(html, baseURL: nil)
            html = ""
        } else if let url = fileURL {
            nsView.loadFileURL(url, allowingReadAccessTo:url)
            fileURL = nil
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
                (url.scheme == "file") ||
                (url.scheme == "about") {
                decisionHandler(.allow)
                return
            }
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}
#else
struct WebView: UIViewRepresentable {
    @Binding var html: String
    @Binding var fileURL: URL?

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
            html = ""
        } else if let url = fileURL {
            uiView.loadFileURL(url, allowingReadAccessTo:url)
            fileURL = nil
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
                (url.scheme == "file") ||
                (url.scheme == "about") {
                decisionHandler(.allow)
                return
            }
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}
#endif
