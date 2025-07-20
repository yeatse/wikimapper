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
@Observable
class SafariExtensionMonitor {
    var isExtensionEnabled = true
    var isChecking = false
    var shouldShowBanner = false
    var lastCheckTime: Date?
    
    private let extensionBundleIdentifier = "com.ptmccarthy.WikiMapper.Extension"
    
    init() {
        Task {
            await checkExtensionStatus()
        }
    }
    
    // MARK: - Public Methods
    
    func checkExtensionStatus() async {
        guard !isChecking else { return }
        
        isChecking = true
        defer {
            isChecking = false
        }
        
        let result: Bool
#if os(macOS)
        let state = try? await SFSafariExtensionManager.stateOfSafariExtension(withIdentifier: extensionBundleIdentifier)
        result = state?.isEnabled ?? false
#else
        // On iOS, check indirectly by looking for WikiMapper data
        try? await Task.sleep(for: .milliseconds(500))

        let userDefaults = UserDefaults(suiteName: "group.wikimapper.storage") ?? UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let hasData = allKeys.contains { key in
            key.hasPrefix("wikimapper_")
        }
        result = hasData
#endif
        
        let wasEnabled = isExtensionEnabled
        isExtensionEnabled = result
        lastCheckTime = .now
        
        if !isExtensionEnabled && (wasEnabled || lastCheckTime == nil) {
            shouldShowBanner = true
        }
    }
    
    func dismissBanner() {
        shouldShowBanner = false
    }
    
    func forceShowBanner() {
        shouldShowBanner = true
    }
}

// MARK: - Extension Status Banner

/// Non-blocking banner view for extension status
struct SafariExtensionBanner: View {
    @Environment(SafariExtensionMonitor.self) var monitor
    
    var action: () -> Void
    
    var body: some View {
        if monitor.shouldShowBanner && !monitor.isExtensionEnabled {
            bannerContent
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: monitor.shouldShowBanner)
        }
    }
    
    private var bannerContent: some View {
        GroupBox {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Safari Extension Not Enabled")
                        .font(.subheadline.weight(.medium))
                    
                    Text("Tap here to learn how to enable the extension to start tracking browsing history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button {
                    monitor.dismissBanner()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .onTapGesture {
                action()
            }
        }
    }
}

#Preview {
    SafariExtensionBanner {}
        .environment(SafariExtensionMonitor())
}
