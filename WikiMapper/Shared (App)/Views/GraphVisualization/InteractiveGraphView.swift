//
//  InteractiveGraphView.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/20.
//

import SwiftUI
import Grape

// MARK: - Interactive Graph View

/// Core interactive graph visualization using Grape
struct InteractiveGraphView: View {
    // MARK: - Properties
    
    let nodes: [GraphNode]
    let links: [GraphLink]
    let searchText: String
    let selectedNodeId: Double?
    let highlightedNodes: Set<Double>
    let onNodeTap: (Double) -> Void
    
    @State private var graphState = ForceDirectedGraphState()
    
    // MARK: - Computed Properties
    
    private var filteredNodes: [GraphNode] {
        if searchText.isEmpty {
            return nodes
        } else {
            return nodes.filter { node in
                highlightedNodes.contains(node.id)
            }
        }
    }
    
    private var filteredLinks: [GraphLink] {
        if searchText.isEmpty {
            return links
        } else {
            // Only show links between highlighted nodes
            return links.filter { link in
                highlightedNodes.contains(link.source) && highlightedNodes.contains(link.target)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        if filteredNodes.isEmpty {
            GraphLoadingView()
        } else {
            grapeGraphView
        }
    }
    
    private var grapeGraphView: some View {
        ForceDirectedGraph(states: graphState) {
            // Create nodes using Series with text labels
            Series(filteredNodes) { node in
                AnnotationNodeMark(id: node.id, radius: nodeRadius(for: node)) {
                    nodeLabel(for: node)
                }
            }
            
            // Create links using Series with arrows
            Series(filteredLinks) { link in
                LinkMark(from: link.source, to: link.target)
            }
            .linkShape(.arrow)
            .stroke(GraphVisualizationStyles.linkColor, linkStrokeStyle)
            
        } force: {
            .manyBody(strength: -300)
            .link(originalLength: 50.0)
            .center()
            .collide()
        }
        .graphOverlay { proxy in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    handleTapGesture(at: location, with: proxy)
                }
                .withGraphDragGesture(proxy, of: Double.self) { state in
                    // Only handle drag for graph panning, not node selection
                    handleDragState(state)
                }
        }
    }
    
    
    // MARK: - Helper Methods
    
    @ViewBuilder
    private func nodeLabel(for node: GraphNode) -> some View {
        let isSelected = selectedNodeId == node.id
        let isHighlighted = highlightedNodes.contains(node.id)
        let accentColor = nodeColor(for: node)
        
        Text(node.title)
            .font(.caption)
            .foregroundStyle(.primary)
            .padding(.vertical, 4.0)
            .padding(.horizontal, 8.0)
            .background(alignment: .center) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? accentColor.opacity(0.3) : backgroundColorForLabels)
                        .shadow(radius: isSelected ? 2.5 : 1.5, y: 1.0)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isHighlighted ? .yellow : accentColor,
                            lineWidth: isHighlighted ? 3.0 : (isSelected ? 2.5 : 2.0)
                        )
                }
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func nodeRadius(for node: GraphNode) -> CGFloat {
        // Base radius for AnnotationNodeMark (affects collision detection)
        let baseRadius: CGFloat = 20
        let sizeMultiplier = node.childrenCount > 0 ? 1.3 : 1.0
        return baseRadius * sizeMultiplier
    }
    
    private func nodeColor(for node: GraphNode) -> Color {
        let isSelected = selectedNodeId == node.id
        let isHighlighted = highlightedNodes.contains(node.id)
        
        return GraphVisualizationStyles.nodeColor(
            for: node,
            isSelected: isSelected,
            isHighlighted: isHighlighted
        )
    }
    
    
    private var linkStrokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: GraphVisualizationStyles.linkStrokeWidth)
    }
    
    private func handleTapGesture(at location: CGPoint, with proxy: GraphProxy) {
        if let nodeId = proxy.node(of: Double.self, at: location) {
            // Node was tapped - trigger selection
            onNodeTap(nodeId)
        }
        // If no node was hit, the tap was on background - do nothing or close detail panel
    }
    
    private func handleDragState(_ state: GraphDragState<Double>?) {
        switch state {
        case .node(_):
            // Don't handle node selection in drag - only allow dragging for positioning
            break
        case .background(_):
            // Handle background drag for panning
            break
        case nil:
            // Drag ended
            break
        }
    }
    
    private func handleNodeTap(_ nodeId: Any) {
        if let nodeIdDouble = nodeId as? Double {
            onNodeTap(nodeIdDouble)
        }
    }
    
    private var backgroundColorForLabels: Color {
#if os(iOS)
        return Color(.systemBackground)
#elseif os(macOS)
        return Color(.controlBackgroundColor)
#endif
    }
}

// MARK: - Previews

#Preview {
    let sampleSession = WikiMapperDataService.sampleData().first!
    let graphData = GraphDataConverter.convertSession(sampleSession)
    
    InteractiveGraphView(
        nodes: graphData.nodes,
        links: graphData.links,
        searchText: "",
        selectedNodeId: nil,
        highlightedNodes: [],
        onNodeTap: { _ in }
    )
}
