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
    @State private var visualizationMode: VisualizationMode = .tree
    
    @Environment(\.openURL) private var openURL
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Session header
            sessionHeaderView
                .padding()
                .background(backgroundColorForPlatform)
            
            // Content view based on visualization mode
            Group {
                switch visualizationMode {
                case .tree:
                    treeVisualizationView
                case .graph:
                    graphVisualizationView
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
    
    // MARK: - Visualization Mode
    
    enum VisualizationMode: CaseIterable {
        case tree
        case graph
        
        var displayName: String {
            switch self {
            case .tree: return "Tree"
            case .graph: return "Graph"
            }
        }
        
        var iconName: String {
            switch self {
            case .tree: return "list.bullet.indent"
            case .graph: return "point.3.connected.trianglepath.dotted"
            }
        }
    }
    
    // MARK: - Tree Visualization View
    
    @ViewBuilder
    private var treeVisualizationView: some View {
        if filteredNodes.isEmpty && !searchText.isEmpty {
            searchEmptyStateView
        } else {
            VStack(spacing: 0) {
                // Tree controls header
                treeControlsHeader
                
                // Tree content
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
    }
    
    // MARK: - Tree Controls Header
    
    private var treeControlsHeader: some View {
        HStack {
            Text("Tree View")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: expandAllNodes) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.caption)
                        Text("Expand All")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button(action: collapseAllNodes) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption)
                        Text("Collapse All")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(backgroundColorForPlatform)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    // MARK: - Graph Visualization View
    
    @ViewBuilder
    private var graphVisualizationView: some View {
        if filteredNodes.isEmpty && !searchText.isEmpty {
            searchEmptyStateView
        } else {
            GrapeSessionVisualizationView(
                session: session,
                searchText: searchText
            )
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
            // Visualization mode picker
            Picker("Visualization Mode", selection: $visualizationMode) {
                ForEach(VisualizationMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
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
