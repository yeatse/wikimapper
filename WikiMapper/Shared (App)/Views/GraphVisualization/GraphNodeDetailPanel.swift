//
//  GraphNodeDetailPanel.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/20.
//

import SwiftUI

/// Detailed information panel for a selected graph node
struct GraphNodeDetailPanel: View {
    // MARK: - Properties
    
    let node: GraphNode
    let nodeColor: Color
    let onOpenURL: (String) -> Void
    let onDismiss: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            urlSection
            statisticsSection
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(nodeColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Color indicator
            Circle()
                .fill(nodeColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(node.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(formatDate(node.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            actionButtons
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                onOpenURL(node.url)
            }) {
                Label("Open", systemImage: "safari")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - URL Section
    
    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("URL")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Text(node.url)
                .font(.caption)
                .foregroundColor(.blue)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .onTapGesture {
                    onOpenURL(node.url)
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        HStack(spacing: 20) {
            StatisticItem(
                title: "Level",
                value: "\(node.level)",
                icon: "arrow.down.forward"
            )
            
            if node.childrenCount > 0 {
                StatisticItem(
                    title: "Children",
                    value: "\(node.childrenCount)",
                    icon: "arrow.branch"
                )
            }
            
            if node.isRoot {
                StatisticItem(
                    title: "Type",
                    value: "Root",
                    icon: "house",
                    valueColor: .blue
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Statistic Item

/// Individual statistic display item
struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(valueColor == .primary ? .secondary : valueColor)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(valueColor)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    let sampleNode = GraphNode(
        from: WikiMapperDataService.sampleData().first!.tree
    )
    
    GraphNodeDetailPanel(
        node: sampleNode,
        nodeColor: .blue,
        onOpenURL: { _ in },
        onDismiss: { }
    )
    .padding()
}