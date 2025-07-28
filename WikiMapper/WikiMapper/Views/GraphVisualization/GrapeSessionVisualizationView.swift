//
//  GrapeSessionVisualizationView.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/20.
//

import SwiftUI

// MARK: - Main Visualization View

/// Main entry point for session graph visualization
struct GrapeSessionVisualizationView: View {
    // MARK: - Properties
    
    let session: WikiMapperSession
    @State private var nodes: [GraphNode] = []
    @State private var links: [GraphLink] = []
    @State private var selectedNode: GraphNode?
    @State private var searchText: String
    @State private var highlightedNodes: Set<Double> = []
    
    @Environment(\.openURL) private var openURL
    
    // MARK: - Initialization
    
    init(session: WikiMapperSession, searchText: String = "") {
        self.session = session
        self._searchText = State(initialValue: searchText)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            if nodes.isEmpty {
                GraphLoadingView()
            } else {
                InteractiveGraphView(
                    nodes: nodes,
                    links: links,
                    searchText: searchText,
                    selectedNodeId: selectedNode?.id,
                    highlightedNodes: highlightedNodes,
                    onNodeTap: handleNodeTap
                )
            }
            
            // Node details panel
            if let selectedNode = selectedNode {
                GraphNodeDetailPanel(
                    node: selectedNode,
                    nodeColor: GraphVisualizationStyles.nodeColor(
                        for: selectedNode,
                        isSelected: true,
                        isHighlighted: highlightedNodes.contains(selectedNode.id)
                    ),
                    onOpenURL: openInSafari,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.selectedNode = nil
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            loadGraphData()
        }
        .onChange(of: searchText) { oldValue, newValue in
            updateHighlightedNodes()
        }
        .animation(.easeInOut(duration: 0.3), value: selectedNode)
    }
    
    // MARK: - Data Management
    
    private func loadGraphData() {
        let graphData = GraphDataConverter.convertSession(session)
        self.nodes = graphData.nodes
        self.links = graphData.links
        updateHighlightedNodes()
    }
    
    private func updateHighlightedNodes() {
        highlightedNodes = GraphDataConverter.filterNodes(nodes, searchText: searchText)
    }
    
    // MARK: - Interaction Handlers
    
    private func handleNodeTap(_ nodeId: Double) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if let node = nodes.first(where: { $0.id == nodeId }) {
                selectedNode = selectedNode?.id == nodeId ? nil : node
            }
        }
    }
    
    private func openInSafari(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        GrapeSessionVisualizationView(
            session: WikiMapperDataService.sampleData().first!
        )
        .navigationTitle("Session Graph")
    }
}