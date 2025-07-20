//
//  SessionDetailView.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/19.
//

import SwiftUI
import SafariServices

/// Detailed view for a single WikiMapper browsing session
struct SessionDetailView: View {
    // MARK: - Properties
    
    let session: WikiMapperSession
    @State private var expandedNodes: Set<Double> = []
    @State private var selectedNode: WikiMapperNode?
    @State private var searchText = ""
    
    @Environment(\.openURL) private var openURL
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Session header
            sessionHeaderView
                .padding()
                .background(backgroundColorForPlatform)
            
            // Tree view
            if filteredNodes.isEmpty && !searchText.isEmpty {
                searchEmptyStateView
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        TreeNodeView(
                            node: session.tree,
                            level: 0,
                            expandedNodes: $expandedNodes,
                            selectedNode: $selectedNode,
                            onNodeTap: handleNodeTap,
                            searchText: searchText
                        )
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(Text(session.tree.pageTitle))
        .searchable(text: $searchText, prompt: "Search pages")
        .toolbar(content: toolbarContent)
        .onAppear {
            // Expand root node by default
            expandedNodes.insert(session.tree.id)
        }
    }
    
    // MARK: - Session Header View
    
    private var sessionHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.tree.pageTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
                    Text(session.formattedStartDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    openInSafari(session.tree.data.url)
                }) {
                    Image(systemName: "safari")
                        .font(.title2)
                }
            }
            
            // Statistics
            HStack(spacing: 16) {
                StatisticView(
                    icon: "doc.text",
                    title: "Pages",
                    value: "\(session.totalPagesCount)"
                )
                
                StatisticView(
                    icon: "clock",
                    title: "Duration",
                    value: session.formattedDuration
                )
                
                StatisticView(
                    icon: "arrow.branch",
                    title: "Branches",
                    value: "\(session.tree.children.count)"
                )
                
                Spacer()
            }
            
            // URL
            Text(session.tree.shortUrl)
                .font(.caption)
                .foregroundColor(.blue)
                .lineLimit(1)
                .onTapGesture {
                    openInSafari(session.tree.data.url)
                }
        }
    }
    
    // MARK: - Search Empty State
    
    private var searchEmptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No matching pages found")
                .font(.headline)
            
            Text("Try using different search terms")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColorForPlatform: Color {
#if os(iOS)
        return Color(.systemGroupedBackground)
#elseif os(macOS)
        return Color(.controlBackgroundColor)
#endif
    }
    
    private var filteredNodes: [WikiMapperNode] {
        if searchText.isEmpty {
            return [session.tree]
        } else {
            return session.search(for: searchText)
        }
    }
    
    // MARK: - Methods
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem {
            Menu {
                Button("Expand All", systemImage: "arrow.down.right.and.arrow.up.left") {
                    expandAllNodes()
                }
                
                Button("Collapse All", systemImage: "arrow.up.left.and.arrow.down.right") {
                    collapseAllNodes()
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }
        }
    }
    
    private func handleNodeTap(_ node: WikiMapperNode) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedNodes.contains(node.id) {
                expandedNodes.remove(node.id)
            } else {
                expandedNodes.insert(node.id)
            }
        }
    }
    
    private func expandAllNodes() {
        withAnimation(.easeInOut(duration: 0.3)) {
            expandedNodes = Set(session.tree.getAllNodes().map { $0.id })
        }
    }
    
    private func collapseAllNodes() {
        withAnimation(.easeInOut(duration: 0.3)) {
            expandedNodes = [session.tree.id]
        }
    }
    
    private func openInSafari(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }
}

// MARK: - Tree Node View

/// Recursive view for displaying tree nodes
struct TreeNodeView: View {
    let node: WikiMapperNode
    let level: Int
    @Binding var expandedNodes: Set<Double>
    @Binding var selectedNode: WikiMapperNode?
    let onNodeTap: (WikiMapperNode) -> Void
    let searchText: String
    
    private var isExpanded: Bool {
        expandedNodes.contains(node.id)
    }
    
    private var hasChildren: Bool {
        !node.children.isEmpty
    }
    
    private var shouldHighlight: Bool {
        !searchText.isEmpty && (
            node.pageTitle.localizedCaseInsensitiveContains(searchText) ||
            node.data.url.localizedCaseInsensitiveContains(searchText)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Node content
            NodeRowView(
                node: node,
                level: level,
                isExpanded: isExpanded,
                hasChildren: hasChildren,
                isHighlighted: shouldHighlight,
                onTap: { onNodeTap(node) }
            )
            
            // Children (if expanded)
            if isExpanded && hasChildren {
                ForEach(node.children, id: \.id) { child in
                    TreeNodeView(
                        node: child,
                        level: level + 1,
                        expandedNodes: $expandedNodes,
                        selectedNode: $selectedNode,
                        onNodeTap: onNodeTap,
                        searchText: searchText
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// Small statistic display view
struct StatisticView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        SessionDetailView(session: WikiMapperDataService.sampleData().first!)
    }
}
