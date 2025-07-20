//
//  WikiMapperApp.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/19.
//

import SwiftUI

@main
struct WikiMapperApp: App {
    @StateObject private var dataService = WikiMapperDataService()
    @StateObject private var extensionMonitor = SafariExtensionMonitor()
    
    var body: some Scene {
        WindowGroup {
            HistoryListView()
                .environmentObject(dataService)
                .environmentObject(extensionMonitor)
        }
#if os(macOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 640, height: 480)
#endif
        
#if os(macOS)
        MenuBarExtra("WikiMapper", systemImage: "safari") {
            WikiMapperMenuBarView()
                .environmentObject(dataService)
                .environmentObject(extensionMonitor)
        }
        .menuBarExtraStyle(.window)
#endif
    }
}