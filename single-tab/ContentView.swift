//
//  ContentView.swift
//  single-tab
//
//  Created by kartik khorwal on 5/19/25.
//

import SwiftUI
import WebKit

struct BrowserView: NSViewRepresentable {
    @Binding var urlString: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if let url = URL(string: urlString), nsView.url?.absoluteString != url.absoluteString {
            nsView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {}
}

struct ContentView: View {
    @State private var urlString = "https://www.google.com"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Enter URL", text: $urlString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onSubmit {
                        if let url = URL(string: urlString) {
                            urlString = url.absoluteString
                        }
                    }

                Button("Go") {
                    if let url = URL(string: urlString) {
                        urlString = url.absoluteString
                    }
                }
                .padding(.trailing)
            }
            .background(.ultraThinMaterial) // Optional: Light material for URL bar
            
            BrowserView(urlString: $urlString)
            .opacity(0.6)
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.clear) // Ensure content view is transparent
    }
}

