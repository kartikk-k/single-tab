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
    @Binding var isLoading: Bool

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
        if let url = URL(string: urlString),
           nsView.url?.absoluteString != url.absoluteString {
            nsView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(urlString: $urlString, isLoading: $isLoading)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var urlString: Binding<String>
        var isLoading: Binding<Bool>

        init(urlString: Binding<String>, isLoading: Binding<Bool>) {
            self.urlString = urlString
            self.isLoading = isLoading
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading.wrappedValue = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.urlString.wrappedValue = webView.url?.absoluteString ?? ""
                self.isLoading.wrappedValue = false
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow main frame navigations, even for new domains
            decisionHandler(.allow)
        }
    }
}

struct URLTextField: View {
    @Binding var text: String
    var onSubmit: () -> Void
    @FocusState var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search files", text: $text)
                .font(.system(size: 14))
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
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
    @Binding var isLoading: Bool
    var onNavigate: (String) -> Void
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?

    @State private var tempURL: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8){
            Button(action: {
                onBack?()
            }) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .opacity(0.7)
            
            Button(action: {
                onForward?()
            }) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .opacity(0.7)
            
            HStack(spacing: 8) {
                URLTextField(text: $tempURL, onSubmit: {
                    navigate()
                })
                .focused($isFocused)
            }
            .padding(2)
            .background(.ultraThickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            ProgressView()
                .scaleEffect(0.5)
                .padding(.leading, 6)
                .opacity(isLoading ? 1 : 0)
        }
        .onChange(of: urlString) { newValue in
            tempURL = newValue
        }
        .onAppear {
            tempURL = urlString
        }
    }

    private func navigate() {
        var formatted = tempURL.trimmingCharacters(in: .whitespacesAndNewlines)

        let shouldSearch = formatted.contains(" ") || !formatted.contains(".")

        if shouldSearch {
            let escaped = formatted.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let searchURL = "https://www.google.com/search?q=\(escaped)"
            onNavigate(searchURL)
        } else {
            if !formatted.hasPrefix("http://") && !formatted.hasPrefix("https://") {
                formatted = "https://" + formatted
            }
            onNavigate(formatted)
        }
    }
}

struct ContentView: View {
    @State private var urlString = "https://www.google.com"
    @State private var urlHistory: [String] = ["https://www.google.com"]
    @State private var currentIndex: Int = 0
    @State private var isLoading = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                URLBarView(
                    urlString: $urlString,
                    isLoading: $isLoading,
                    onNavigate: { newURL in
                        // If navigating to a new URL, update history
                        if currentIndex == urlHistory.count - 1 {
                            urlHistory.append(newURL)
                        } else {
                            urlHistory = Array(urlHistory.prefix(currentIndex + 1)) + [newURL]
                        }
                        currentIndex = urlHistory.count - 1
                        urlString = newURL
                    },
                    onBack: {
                        guard currentIndex > 0 else { return }
                        currentIndex -= 1
                        urlString = urlHistory[currentIndex]
                    },
                    onForward: {
                        guard currentIndex < urlHistory.count - 1 else { return }
                        currentIndex += 1
                        urlString = urlHistory[currentIndex]
                    }
                )
                .focused($focused)

                Spacer()
            }
            .padding(6)
            .background(.thinMaterial)

            BrowserView(urlString: $urlString, isLoading: $isLoading)
                .opacity(0.6)
                .background(.ultraThinMaterial)
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.clear)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if event.modifierFlags.contains(.command) {
                    if event.charactersIgnoringModifiers == "l" {
                        DispatchQueue.main.async {
                            focused = true
                        }
                        return nil
                    }
                    if event.charactersIgnoringModifiers == "r" {
                        urlString = urlHistory[currentIndex]
                        return nil
                    }
                }
                return event
            }
        }
    }
}
