//
//  HistoryListView.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/19.
//

import SwiftUI

/// Main view for displaying WikiMapper browsing history
struct HistoryListView: View {
    // MARK: - Properties
    
    @Environment(WikiMapperDataService.self) private var dataService
    @Environment(SafariExtensionMonitor.self) private var extensionMonitor
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appearsActive) private var appearsActive
#if os(macOS)
    @Environment(\.openSettings) private var openSettings
#endif
    @Environment(\.openURL) private var openURL
    
    @State private var searchText = ""
    @State private var selectedDateRange: DateRange = .all
    @State private var showingExtensionGuide = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if dataService.sessions.isEmpty && false {
                NavigationStack {
                    if dataService.isLoading {
                        loadingView
                    } else {
                        emptyStateView
                    }
                }
            } else {
                NavigationSplitView {
                    sessionListView
                        .navigationTitle(Text("Browsing History"))
                        .searchable(text: $searchText, placement: .sidebar, prompt: "Search pages or URLs")
                        .refreshable {
                            await dataService.refresh()
                        }
                        .navigationSplitViewColumnWidth(ideal: 280)
                        .toolbar {
#if os(iOS)
                            toolbarContent()
#endif
                        }
                } detail: {
                    ContentUnavailableView {
                        Label("Select a Session", systemImage: "sidebar.left")
                    } description: {
                        Text("Choose a browsing session from the sidebar to view its details")
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(dataService.errorMessage != nil)) {
            Button("OK") {
                dataService.errorMessage = nil
            }
        } message: {
            if let errorMessage = dataService.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingExtensionGuide) {
            SafariExtensionGuideView()
        }
#if os(macOS)
        .onChange(of: appearsActive) { oldValue, newValue in
            if newValue {
                refresh()
            }
        }
#else
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .active {
                refresh()
            }
        }
#endif
    }
    
    
    // MARK: - Session List View
    
    private var sessionListView: some View {
        SessionsListView(
            sessions: filteredSessions,
            searchText: searchText,
            onShowSettings: showSettings
        )
    }
    
    // MARK: - Empty State View
    
    @ViewBuilder private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Browsing History", systemImage: "safari")
        } description: {
            Text("Your browsing history will appear here after visiting Wikipedia pages in Safari")
        } actions: {
            Button("Setup Safari Extension") {
                showSettings()
            }
            Button("Open Wikipedia") {
                openURL(URL(string: "https://www.wikipedia.org")!)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        ProgressView()
    }
    
    // MARK: - Computed Properties
    
    private var filteredSessions: [WikiMapperSession] {
        let sessions = dataService.sessions
        
        switch selectedDateRange {
        case .all:
            return sessions
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            return sessions.filter { $0.startDate >= today && $0.startDate < tomorrow }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
            return sessions.filter { $0.startDate >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            return sessions.filter { $0.startDate >= monthAgo }
        }
    }
    
    // MARK: - Methods
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Safari Extension Settings", systemImage: "safari") {
                    showSettings()
                }
                
                Button("Refresh", systemImage: "arrow.clockwise") {
                    refresh()
                }
                
                Button("Clear All Data", systemImage: "trash", role: .destructive) {
                    dataService.clearAllSessions()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    
    private func showSettings() {
#if os(macOS)
        openSettings()
#else
        showingExtensionGuide = true
#endif
    }
    
    private func refresh() {
        Task {
            await dataService.refresh()
            await extensionMonitor.checkExtensionStatus()
        }
    }
}


// MARK: - Supporting Types

enum DateRange: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
}

struct AdaptedGroupBox: ViewModifier {
    func body(content: Content) -> some View {
#if os(macOS)
        GroupBox {
            content
        }
#else
        content
#endif
    }
}

// MARK: - Previews

#Preview {
    HistoryListView()
        .environment(WikiMapperDataService())
        .environment(SafariExtensionMonitor())
#if os(macOS)
        .frame(width: 640, height: 480)
#endif
}
