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
    
    @EnvironmentObject private var dataService: WikiMapperDataService
    @EnvironmentObject private var extensionMonitor: SafariExtensionMonitor
    @State private var searchText = ""
    @State private var selectedDateRange: DateRange = .all
    @State private var showingSearchResults = false
    @State private var searchResults: [(session: WikiMapperSession, nodes: [WikiMapperNode])] = []
    @State private var showingExtensionGuide = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with statistics
                if !dataService.sessions.isEmpty {
                    headerView
                        .padding()
                        .background(backgroundColorForPlatform)
                }
                
#if os(macOS)
                // Search field for macOS
                if !dataService.sessions.isEmpty {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search pages or URLs", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
#endif
                
                // Main content
                if dataService.isLoading && dataService.sessions.isEmpty {
                    loadingView
                } else if dataService.sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .navigationTitle("Browsing History")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search pages or URLs")
            .onChange(of: searchText) { _, newValue in
                performSearch(newValue)
            }
            .toolbar(content: toolbarContent)
#elseif os(macOS)
            // On macOS, we'll handle search differently to avoid toolbar conflicts
            .onChange(of: searchText) { _, newValue in
                performSearch(newValue)
            }
#endif
            .refreshable {
                await dataService.refresh()
            }
        }
        .overlay(alignment: .top) {
            SafariExtensionBanner(monitor: extensionMonitor)
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
            if showingSearchResults {
                searchResultsSection
            } else {
                sessionsSection
            }
        }
        .listStyle(PlainListStyle())
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
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "safari")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Browsing History")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Your browsing history will appear here after visiting Wikipedia pages in Safari")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                if !extensionMonitor.isExtensionEnabled {
                    Button("Setup Safari Extension") {
                        showingExtensionGuide = true
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Refresh") {
                    Task {
                        await dataService.refresh()
                        extensionMonitor.checkExtensionStatus()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading browsing history...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColorForPlatform: Color {
#if os(iOS)
        return Color(.systemGroupedBackground)
#elseif os(macOS)
        return Color(.controlBackgroundColor)
#endif
    }
    
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
        ToolbarItem(placement: toolbarPlacement) {
            Menu {
                Button("Safari Extension Settings", systemImage: "safari") {
                    showingExtensionGuide = true
                }
                
                Divider()
                
                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task {
                        await dataService.refresh()
                        extensionMonitor.checkExtensionStatus()
                    }
                }
                
                Button("Check Extension Status", systemImage: "checkmark.shield") {
                    extensionMonitor.checkExtensionStatus()
                }
                
                Divider()
                
                Button("Clear All Data", systemImage: "trash", role: .destructive) {
                    dataService.clearAllSessions()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    private var toolbarPlacement: ToolbarItemPlacement {
#if os(iOS)
        return .topBarTrailing
#elseif os(macOS)
        return .automatic
#endif
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
        .environmentObject(WikiMapperDataService())
        .environmentObject(SafariExtensionMonitor())
}
