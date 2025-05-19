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

struct URLTextField: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search files", text: $text)
                .font(.system(size: 14))
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(8)
        .frame(maxWidth: 500)
        .onSubmit {
            onSubmit()
        }
    }
}

struct URLBarView: View {
    @Binding var urlString: String
    var onNavigate: (String) -> Void

    @State private var tempURL: String = ""

    var body: some View {
        HStack(spacing: 8) {
            URLTextField(text: $tempURL) {
                navigate()
            }
        }
        .padding(2)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            tempURL = urlString
        }
    }

    private func navigate() {
        var formatted = tempURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !formatted.hasPrefix("http://") && !formatted.hasPrefix("https://") {
            formatted = "https://" + formatted
        }
        onNavigate(formatted)
    }
}

struct ContentView: View {
    @State private var urlString = "https://www.google.com"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                URLBarView(urlString: $urlString) { newURL in
                    urlString = newURL
                }
                Spacer()
            }
            .padding(6)
            .background(.thinMaterial)
            
            BrowserView(urlString: $urlString)
                .opacity(0.6)
                .background(.ultraThinMaterial)
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.clear) // Ensure content view is transparent
    }
}
