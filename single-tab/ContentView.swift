//
//  ContentView.swift
//  single-tab
//
//  Created by kartik khorwal on 5/19/25.
//


import SwiftUI
import WebKit

// Utility extension to get the key window
extension NSApplication {
    static var keyWindow: NSWindow? {
        return NSApplication.shared.windows.first { $0.isKeyWindow }
    }
}

struct BrowserView: NSViewRepresentable {
    @Binding var urlString: String
    @Binding var isLoading: Bool
    let onURLChange: (String) -> Void // Callback for URL changes

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.navigationDelegate = context.coordinator
        // Add KVO observer for URL changes
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.url), options: [.new], context: nil)
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
        Coordinator(urlString: $urlString, isLoading: $isLoading, onURLChange: onURLChange)
    }

    func cleanup(nsView: WKWebView, coordinator: Coordinator) {
        nsView.removeObserver(coordinator, forKeyPath: #keyPath(WKWebView.url))
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var urlString: Binding<String>
        var isLoading: Binding<Bool>
        let onURLChange: (String) -> Void

        init(urlString: Binding<String>, isLoading: Binding<Bool>, onURLChange: @escaping (String) -> Void) {
            self.urlString = urlString
            self.isLoading = isLoading
            self.onURLChange = onURLChange
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == #keyPath(WKWebView.url), let webView = object as? WKWebView, let newURL = webView.url?.absoluteString {
                DispatchQueue.main.async {
                    self.urlString.wrappedValue = newURL
                    self.onURLChange(newURL) // Notify parent of URL change
                }
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading.wrappedValue = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading.wrappedValue = false
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated else {
                decisionHandler(.allow)
                return
            }

            // Inject JavaScript to check if the clicked link has target="_blank"
            let js = """
            (function() {
                const allTargetElemnts = document.getElementsByTagName('a')

                for (const targetElement of allTargetElemnts) {
                    targetElement.target = '_self'
                }
            })();
            """

            webView.evaluateJavaScript(js) { (result, error) in
                if let href = result as? String, !href.isEmpty {
                    // Link has target="_blank", update urlString and cancel external navigation
                    DispatchQueue.main.async {
                        self.urlString.wrappedValue = href
                        self.onURLChange(href)
                    }
                    decisionHandler(.cancel)
                } else {
                    // Normal link navigation, allow it
                    decisionHandler(.allow)
                }
            }
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
            TextField("Enter URL or search", text: $text)
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
    @Binding var isPinned: Bool
    var onNavigate: (String) -> Void
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?

    @State private var tempURL: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { onBack?() }) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .opacity(0.7)

            Button(action: { onForward?() }) {
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

            Button(action: {
                isPinned.toggle()
                if let window = NSApplication.keyWindow {
                    window.level = isPinned ? .floating : .normal
                }
            }) {
                Image(systemName: isPinned ? "pin.fill" : "pin.slash")
            }
            .buttonStyle(.plain)
            .opacity(0.8)
        }
        .onChange(of: urlString) { newValue in
            tempURL = newValue // Sync tempURL with urlString
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
    @State private var isPinned = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                URLBarView(
                    urlString: $urlString,
                    isLoading: $isLoading,
                    isPinned: $isPinned,
                    onNavigate: { newURL in
                        updateHistory(newURL)
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

            BrowserView(
                urlString: $urlString,
                isLoading: $isLoading,
                onURLChange: { newURL in
                    updateHistory(newURL) // Track every URL change
                }
            )
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
                        if let currentURL = URL(string: urlString) {
                            urlString = "about:blank"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                urlString = currentURL.absoluteString
                            }
                        }
                        return nil
                    }
                }
                return event
            }
        }
    }

    private func updateHistory(_ newURL: String) {
        // Avoid duplicate entries for the same URL
        if urlHistory.last != newURL {
            if currentIndex == urlHistory.count - 1 {
                urlHistory.append(newURL)
            } else {
                urlHistory = Array(urlHistory.prefix(currentIndex + 1)) + [newURL]
            }
            currentIndex = urlHistory.count - 1
        }
        urlString = newURL
    }
}
