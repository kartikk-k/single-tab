//
//  single_tabApp.swift
//  single-tab
//
//  Created by kartik khorwal on 5/19/25.
//

import SwiftUI

@main
struct single_tabApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            // Configure the window
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            
            // Create a visual effect view for the blur
            let visualEffect = NSVisualEffectView()
            visualEffect.translatesAutoresizingMaskIntoConstraints = false
            visualEffect.material = .underWindowBackground // or .behindWindow for different effect
            visualEffect.state = .active
            visualEffect.wantsLayer = true
            visualEffect.layer?.opacity = 0.95 // Slightly opaque
            
            // Set the visual effect view as the window's content view
            if let contentView = window.contentView {
                contentView.superview?.addSubview(visualEffect, positioned: .below, relativeTo: contentView)
                NSLayoutConstraint.activate([
                    visualEffect.leadingAnchor.constraint(equalTo: contentView.superview!.leadingAnchor),
                    visualEffect.trailingAnchor.constraint(equalTo: contentView.superview!.trailingAnchor),
                    visualEffect.topAnchor.constraint(equalTo: contentView.superview!.topAnchor),
                    visualEffect.bottomAnchor.constraint(equalTo: contentView.superview!.bottomAnchor)
                ])
            }
            
            // Optional: Set window background color to clear to enhance blur
            window.backgroundColor = .clear
        }
    }
}
