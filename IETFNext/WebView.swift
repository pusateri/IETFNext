//
//  WebView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/29/22.
//

import SwiftUI
import WebKit

struct DetailView: View {
    let url: String

    var body: some View {
        WebView(urlPath: url)
    }
}

struct WebView: UIViewRepresentable {
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
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(url: "https://apple.com")
    }
}


