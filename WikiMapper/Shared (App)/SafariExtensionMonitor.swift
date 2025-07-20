//
//  SafariExtensionMonitor.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/20.
//

import SwiftUI
import Combine

#if os(macOS)
import SafariServices
#endif

/// Service for monitoring Safari extension state
@MainActor
class SafariExtensionMonitor: ObservableObject {
    @Published var isExtensionEnabled = false
    @Published var isChecking = false
    @Published var shouldShowBanner = false
    @Published var lastCheckTime: Date?
    
    private let extensionBundleIdentifier = "com.ptmccarthy.WikiMapper.Extension"
    private var appStateSubscription: AnyCancellable?
    
    init() {
        setupAppStateMonitoring()
        checkExtensionStatus()
    }
    
    // MARK: - Public Methods
    
    func checkExtensionStatus() {
        guard !isChecking else { return }
        
        isChecking = true
        
#if os(macOS)
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { [weak self] state, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let wasEnabled = self.isExtensionEnabled
                self.isExtensionEnabled = state?.isEnabled ?? false
                self.isChecking = false
                self.lastCheckTime = Date()
                
                // Show banner if extension was disabled or is still disabled after first check
                if !self.isExtensionEnabled && (wasEnabled || self.lastCheckTime == nil) {
                    self.shouldShowBanner = true
                }
            }
        }
#else
        // On iOS, check indirectly by looking for WikiMapper data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let userDefaults = UserDefaults(suiteName: "group.wikimapper.storage") ?? UserDefaults.standard
            let allKeys = userDefaults.dictionaryRepresentation().keys
            let hasData = allKeys.contains { key in
                key.hasPrefix("wikimapper_")
            }
            
            let wasEnabled = self.isExtensionEnabled
            self.isExtensionEnabled = hasData
            self.isChecking = false
            self.lastCheckTime = Date()
            
            // Show banner if no data found (likely extension not enabled)
            if !hasData && !wasEnabled {
                self.shouldShowBanner = true
            }
        }
#endif
    }
    
    func dismissBanner() {
        shouldShowBanner = false
    }
    
    func forceShowBanner() {
        shouldShowBanner = true
    }
    
    // MARK: - Private Methods
    
    private func setupAppStateMonitoring() {
#if os(iOS)
        // Monitor app lifecycle
        appStateSubscription = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    // Delay slightly to ensure app is fully active
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    self?.checkExtensionStatus()
                }
            }
#elseif os(macOS)
        // Monitor app lifecycle
        appStateSubscription = NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    // Delay slightly to ensure app is fully active
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    self?.checkExtensionStatus()
                }
            }
#endif
    }
    
    deinit {
        appStateSubscription?.cancel()
    }
}

// MARK: - Extension Status Banner

/// Non-blocking banner view for extension status
struct SafariExtensionBanner: View {
    @ObservedObject var monitor: SafariExtensionMonitor
    @State private var showingGuide = false
    
    var body: some View {
        if monitor.shouldShowBanner && !monitor.isExtensionEnabled {
            bannerContent
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: monitor.shouldShowBanner)
        }
    }
    
    private var bannerContent: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Safari Extension Not Enabled")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Tap here to learn how to enable the extension to start tracking browsing history")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                monitor.dismissBanner()
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(bannerBackgroundColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture {
            showingGuide = true
        }
        .sheet(isPresented: $showingGuide) {
            SafariExtensionGuideView()
        }
    }
    
    private var bannerBackgroundColor: Color {
#if os(iOS)
        return Color(.systemBackground)
#elseif os(macOS)
        return Color(.controlBackgroundColor)
#endif
    }
}

// MARK: - View Extension

extension View {
    func safariExtensionBanner(_ monitor: SafariExtensionMonitor) -> some View {
        VStack(spacing: 0) {
            SafariExtensionBanner(monitor: monitor)
            self
        }
    }
}