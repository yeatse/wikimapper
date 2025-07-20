//
//  NodeRowView.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/19.
//

import SwiftUI

/// View for displaying an individual node in the WikiMapper tree
struct NodeRowView: View {
    // MARK: - Properties
    
    let node: WikiMapperNode
    let level: Int
    let isExpanded: Bool
    let hasChildren: Bool
    let isHighlighted: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    // MARK: - Constants
    
    private let indentationWidth: CGFloat = 20
    private let maxLevel: Int = 10
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Indentation and connection lines
                indentationView
                
                // Expand/collapse indicator
                expansionIndicator
                
                // Node content
                nodeContentView
                
                Spacer()
                
                // Timestamp
                timestampView
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(backgroundView)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0) {
            // Handle press state
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
    
    // MARK: - Indentation View
    
    private var indentationView: some View {
        HStack(spacing: 0) {
            // Draw connection lines for tree structure
            ForEach(0..<min(level, maxLevel), id: \.self) { levelIndex in
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                    .padding(.leading, indentationWidth - 0.5)
            }
        }
        .frame(width: CGFloat(min(level, maxLevel)) * indentationWidth)
    }
    
    // MARK: - Expansion Indicator
    
    private var expansionIndicator: some View {
        Group {
            if hasChildren {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(width: 12)
                    .rotationEffect(.degrees(isExpanded ? 0 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 4, height: 4)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Node Content View
    
    private var nodeContentView: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Page title
            Text(node.pageTitle)
                .font(.body)
                .fontWeight(node.isRoot ? .bold : .medium)
                .foregroundColor(node.isRoot ? .primary : .primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // URL and additional info
            HStack(spacing: 8) {
                // URL
                Text(node.shortUrl)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                // Visual separator
                if !node.isRoot {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 2, height: 2)
                    
                    // Node level indicator
                    Text("Level \(level)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Timestamp View
    
    private var timestampView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(formattedTime)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if hasChildren {
                Text("\(node.children.count)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if isHighlighted {
            return Color.yellow.opacity(0.3)
        } else if node.isRoot {
            return Color.blue.opacity(0.1)
        } else if isPressed {
            return Color.gray.opacity(0.2)
        } else {
#if os(iOS)
            return Color(.systemBackground)
#elseif os(macOS)
            return Color(.controlBackgroundColor)
#endif
        }
    }
    
    private var borderColor: Color {
        if isHighlighted {
            return Color.yellow.opacity(0.6)
        } else if node.isRoot {
            return Color.blue.opacity(0.3)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private var borderWidth: CGFloat {
        isHighlighted ? 2 : 1
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: node.data.dateObject)
    }
}

// MARK: - Enhanced Node Row View

/// Enhanced version with more detailed information
struct DetailedNodeRowView: View {
    let node: WikiMapperNode
    let level: Int
    let isExpanded: Bool
    let hasChildren: Bool
    let isHighlighted: Bool
    let onTap: () -> Void
    let onUrlTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            NodeRowView(
                node: node,
                level: level,
                isExpanded: isExpanded,
                hasChildren: hasChildren,
                isHighlighted: isHighlighted,
                onTap: onTap
            )
            
            // Detailed information (shown when highlighted or expanded)
            if isHighlighted || (hasChildren && isExpanded) {
                detailsView
                    .padding(.leading, CGFloat(level + 1) * 20 + 20)
                    .padding(.vertical, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Full URL
            Button(action: onUrlTap) {
                HStack {
                    Image(systemName: "link")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    Text(node.data.url)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Timestamp details
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Visited: \(node.data.formattedDate)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Children summary (if any)
            if hasChildren {
                HStack {
                    Image(systemName: "arrow.branch")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Contains \(node.children.count) sub-pages")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.all, 8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Compact Node Row View

/// Compact version for lists with many items
struct CompactNodeRowView: View {
    let node: WikiMapperNode
    let level: Int
    let isHighlighted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Level indicator
                Rectangle()
                    .fill(levelColor)
                    .frame(width: 3)
                    .padding(.vertical, 2)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.pageTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(formattedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Child count badge
                if !node.children.isEmpty {
                    Text("\(node.children.count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHighlighted ? Color.yellow.opacity(0.3) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var levelColor: Color {
        switch level {
        case 0: return .blue
        case 1: return .green
        case 2: return .orange
        case 3: return .purple
        default: return .gray
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: node.data.dateObject)
    }
}

// MARK: - Previews

#Preview("Standard Node Row") {
    let sampleNode = WikiMapperDataService.sampleData().first!.tree
    
    VStack {
        NodeRowView(
            node: sampleNode,
            level: 0,
            isExpanded: true,
            hasChildren: true,
            isHighlighted: false,
            onTap: { }
        )
        
        NodeRowView(
            node: sampleNode.children.first ?? sampleNode,
            level: 1,
            isExpanded: false,
            hasChildren: false,
            isHighlighted: true,
            onTap: { }
        )
    }
    .padding()
}

#Preview("Compact Node Row") {
    let sampleNode = WikiMapperDataService.sampleData().first!.tree
    
    VStack {
        CompactNodeRowView(
            node: sampleNode,
            level: 0,
            isHighlighted: false,
            onTap: { }
        )
        
        CompactNodeRowView(
            node: sampleNode.children.first ?? sampleNode,
            level: 1,
            isHighlighted: true,
            onTap: { }
        )
    }
}