//
//  SessionsListView.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/20.
//

import SwiftUI

/// List view for displaying browsing sessions
struct SessionsListView: View {
    let sessions: [WikiMapperSession]
    let searchText: String
    let onShowSettings: () -> Void
    
    @Environment(WikiMapperDataService.self) private var dataService
    @Environment(SafariExtensionMonitor.self) private var extensionMonitor
    
    @State private var showingSearchResults = false
    @State private var searchResults: [(session: WikiMapperSession, nodes: [WikiMapperNode])] = []
    
    var body: some View {
        List {
            if extensionMonitor.shouldShowBanner {
                Section {
                    SafariExtensionBanner {
                        onShowSettings()
                    }
                    .listRowInsets(EdgeInsets())
                    .modifier(AdaptedGroupBox())
                }
#if os(iOS)
                .listSectionSpacing(.compact)
#endif
            }
            
            Section {
                let stats = dataService.getStatistics()
                HistoryHeaderView(
                    totalSessions: stats.totalSessions,
                    totalPages: stats.totalPages,
                    averagePagesPerSession: stats.averagePagesPerSession
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            if showingSearchResults {
                HistorySearchView(searchResults: searchResults)
            } else {
                Section {
                    ForEach(sessions, id: \.id) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRowView(session: session)
                        }
                    }
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            performSearch(newValue)
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
    
}

#Preview {
    NavigationStack {
        SessionsListView(sessions: [], searchText: "", onShowSettings: {})
            .environment(WikiMapperDataService())
            .environment(SafariExtensionMonitor())
    }
}
