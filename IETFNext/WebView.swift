//
//  WebView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/29/22.
//

import SwiftUI
import WebKit

struct WebView: View {
    @Binding var loadURL: String?

    var body: some View {
        if let loadURL = loadURL {
            WebViewRepresentable(urlPath: loadURL)
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    var urlPath: String?
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView : WKWebView , context : Context) {
        if let response = urlPath {
            if let url = URL(string: response){
                let request = URLRequest(url: url)
                  uiView.load(request)
            }
        }
    }
}
