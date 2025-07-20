//
//  WikiMapperApp.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/19.
//

import SwiftUI

@main
struct WikiMapperApp: App {
    @State private var dataService = WikiMapperDataService()
    @State private var extensionMonitor = SafariExtensionMonitor()
    
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    
    var body: some Scene {
        WindowGroup {
            HistoryListView()
                .environment(dataService)
                .environment(extensionMonitor)
        }
        .defaultSize(width: 800, height: 600)
        .commands {
            CommandGroup(after: .saveItem) {
                Divider()
                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task {
                        await dataService.refresh()
                        await extensionMonitor.checkExtensionStatus()
                    }
                }
                
                Button("Clear All Data", systemImage: "trash", role: .destructive) {
                    dataService.clearAllSessions()
                }
            }
        }
#if os(macOS)
        Settings {
            SafariExtensionGuideView()
                .environment(extensionMonitor)
        }
        .defaultSize(width: 480, height: 600)
#endif
    }
}
