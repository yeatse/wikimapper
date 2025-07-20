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
    @State private var showingSearchResults = false
    @State private var searchResults: [(session: WikiMapperSession, nodes: [WikiMapperNode])] = []
    @State private var showingExtensionGuide = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if dataService.sessions.isEmpty {
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
                        .onChange(of: searchText) { _, newValue in
                            performSearch(newValue)
                        }
                        .refreshable {
                            await dataService.refresh()
                        }
                        .navigationSplitViewColumnWidth(ideal: 240)
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
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            let stats = dataService.getStatistics()
            
            HStack {
                StatCard(
                    title: "Sessions",
                    value: "\(stats.totalSessions)",
                    icon: "folder"
                )
                
                StatCard(
                    title: "Pages",
                    value: "\(stats.totalPages)",
                    icon: "doc"
                )
                
                StatCard(
                    title: "Avg Pages",
                    value: String(format: "%.1f", stats.averagePagesPerSession),
                    icon: "chart.bar"
                )
            }
            
            if let lastUpdate = dataService.lastUpdateTime {
                Text("Last updated: \(lastUpdate.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Session List View
    
    private var sessionListView: some View {
        List {
            SafariExtensionBanner {
                showSettings()
            }
            
            if showingSearchResults {
                searchResultsSection
            } else {
                sessionsSection
            }
        }
    }
    
    private var sessionsSection: some View {
        ForEach(filteredSessions, id: \.id) { session in
            NavigationLink(destination: SessionDetailView(session: session)) {
                SessionRowView(session: session)
            }
        }
    }
    
    private var searchResultsSection: some View {
        Section {
            ForEach(searchResults, id: \.session.id) { result in
                VStack(alignment: .leading, spacing: 8) {
                    NavigationLink(destination: SessionDetailView(session: result.session)) {
                        SessionRowView(session: result.session)
                    }
                    
                    // Show matching nodes
                    ForEach(result.nodes.prefix(3), id: \.id) { node in
                        HStack {
                            Image(systemName: "arrow.turn.down.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(node.pageTitle)
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Text(node.shortUrl)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.leading, 20)
                    }
                    
                    if result.nodes.count > 3 {
                        Text("\(result.nodes.count - 3) more matches...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }
                }
            }
        } header: {
            Text("Search Results (\(searchResults.count) sessions)")
        }
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
    
    private func performSearch(_ query: String) {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showingSearchResults = false
            searchResults = []
        } else {
            searchResults = dataService.search(for: query)
            showingSearchResults = true
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

// MARK: - Supporting Views

/// Individual session row view
struct SessionRowView: View {
    let session: WikiMapperSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.tree.pageTitle)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(session.formattedStartDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(session.totalPagesCount) pages")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    
                    Text(session.formattedDuration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Show first few pages in the session
            if session.tree.children.count > 0 {
                HStack {
                    Text("Path:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    let pathText = ([session.tree.pageTitle] + session.tree.children.prefix(2).map { $0.pageTitle }).joined(separator: " → ")
                    
                    Text(pathText + (session.tree.children.count > 2 ? " ..." : ""))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Statistics card view
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    private var cardBackgroundColor: Color {
#if os(iOS)
        return Color(.secondarySystemBackground)
#elseif os(macOS)
        return Color(.controlColor)
#endif
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Supporting Types

enum DateRange: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
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
