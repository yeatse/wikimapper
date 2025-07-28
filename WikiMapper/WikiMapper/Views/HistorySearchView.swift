//
//  HistorySearchView.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/20.
//

import SwiftUI

/// Search results section for browsing history
struct HistorySearchView: View {
    let searchResults: [(session: WikiMapperSession, nodes: [WikiMapperNode])]
    
    var body: some View {
        Section {
            ForEach(searchResults, id: \.session.id) { result in
                VStack(alignment: .leading, spacing: 8) {
                    NavigationLink(destination: SessionDetailView(session: result.session)) {
                        SessionRowView(session: result.session)
                    }
                    
                    ForEach(result.nodes.prefix(3), id: \.id) { node in
                        SearchResultNodeView(node: node)
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
}

/// Individual search result node view
struct SearchResultNodeView: View {
    let node: WikiMapperNode
    
    var body: some View {
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
}

#Preview {
    List {
        HistorySearchView(searchResults: [])
    }
}