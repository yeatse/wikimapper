//
//  WikiMapperMenuBarView.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/19.
//

import SwiftUI

#if os(macOS)
/// Menu bar content view for macOS
struct WikiMapperMenuBarView: View {
    @EnvironmentObject private var dataService: WikiMapperDataService
    @EnvironmentObject private var extensionMonitor: SafariExtensionMonitor
    @State private var showingExtensionGuide = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "safari")
                    .foregroundColor(.blue)
                Text("WikiMapper")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Extension Status
            HStack {
                Image(systemName: extensionMonitor.isExtensionEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(extensionMonitor.isExtensionEnabled ? .green : .red)
                Text("Extension Status")
                Spacer()
                Text(extensionMonitor.isExtensionEnabled ? "Enabled" : "Disabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Quick Stats
            if !dataService.sessions.isEmpty {
                let stats = dataService.getStatistics()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Sessions:")
                        Spacer()
                        Text("\(stats.totalSessions)")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Pages:")
                        Spacer()
                        Text("\(stats.totalPages)")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Avg Pages:")
                        Spacer()
                        Text(String(format: "%.1f", stats.averagePagesPerSession))
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                }
                .padding(.vertical, 4)
            }
            
            Divider()
            
            // Action Buttons
            VStack(spacing: 6) {
                Button("Safari Extension Settings") {
                    showingExtensionGuide = true
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Refresh Data") {
                    Task {
                        await dataService.refresh()
                        extensionMonitor.checkExtensionStatus()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Check Extension Status") {
                    extensionMonitor.checkExtensionStatus()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                Button("Clear All Data", role: .destructive) {
                    dataService.clearAllSessions()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
            
            // Open Main Window Button
            Button("Open Main Window") {
                NSApp.activate(ignoringOtherApps: true)
                // Bring existing window to front or create new one
                for window in NSApp.windows {
                    if window.title == "WikiMapper" || window.contentView?.subviews.first is NSHostingView<HistoryListView> {
                        window.makeKeyAndOrderFront(nil)
                        return
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button("Quit WikiMapper") {
                NSApp.terminate(nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(width: 280)
        .sheet(isPresented: $showingExtensionGuide) {
            SafariExtensionGuideView()
        }
    }
}

#Preview {
    WikiMapperMenuBarView()
        .environmentObject(WikiMapperDataService())
        .environmentObject(SafariExtensionMonitor())
}
#endif