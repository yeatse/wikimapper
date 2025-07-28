//
//  GraphVisualizationStyles.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/20.
//

import SwiftUI

// MARK: - Graph Styling Configuration

/// Configuration and styling utilities for graph visualization
struct GraphVisualizationStyles {
    // MARK: - Constants
    
    static let nodeRadius: CGFloat = 8
    static let rootNodeRadius: CGFloat = 12
    static let linkStrokeWidth: CGFloat = 2
    
    // MARK: - Color Schemes
    
    private static let levelColors: [Color] = [
        .blue,      // Level 0 (root)
        .green,     // Level 1
        .orange,    // Level 2
        .purple,    // Level 3
        .red,       // Level 4
        .pink,      // Level 5
        .cyan,      // Level 6
        .indigo     // Level 7+
    ]
    
    // MARK: - Node Styling
    
    /// Get node color based on state and level
    static func nodeColor(for node: GraphNode, isSelected: Bool, isHighlighted: Bool) -> Color {
        if isHighlighted {
            return .yellow
        }
        
        if isSelected {
            return .primary
        }
        
        if node.isRoot {
            return .blue
        }
        
        let colorIndex = min(node.level, levelColors.count - 1)
        return levelColors[colorIndex]
    }
    
    /// Get node size based on type and children count
    static func nodeSize(for node: GraphNode) -> CGFloat {
        let baseSize = node.isRoot ? rootNodeRadius : nodeRadius
        let sizeMultiplier = node.childrenCount > 0 ? 1.2 : 1.0
        return baseSize * sizeMultiplier
    }
    
    /// Get stroke color for node
    static func strokeColor(for node: GraphNode, isSelected: Bool, isHighlighted: Bool) -> Color {
        if isSelected {
            return .primary
        }
        return nodeColor(for: node, isSelected: false, isHighlighted: isHighlighted).opacity(0.8)
    }
    
    /// Get stroke width for node
    static func strokeWidth(for node: GraphNode, isSelected: Bool) -> CGFloat {
        if isSelected {
            return 3
        }
        return node.isRoot ? 2 : 1
    }
    
    /// Get link color
    static var linkColor: Color {
        return Color.secondary.opacity(0.4)
    }
    
    // MARK: - Platform Colors
    
    /// Get background color for current platform
    static var backgroundColorForPlatform: Color {
#if os(iOS)
        return Color(.systemGroupedBackground)
#elseif os(macOS)
        return Color(.controlBackgroundColor)
#endif
    }
}

// MARK: - Loading View

/// Loading state view for graph visualization
struct GraphLoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
            }
            
            VStack(spacing: 8) {
                Text("Building Graph Visualization")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Converting session data to interactive graph...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GraphVisualizationStyles.backgroundColorForPlatform)
    }
}

// MARK: - Previews

#Preview("Loading View") {
    GraphLoadingView()
}
