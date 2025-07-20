//
//  HistoryHeaderView.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/20.
//

import SwiftUI

/// Header view displaying statistics for browsing history
struct HistoryHeaderView: View {
    let totalSessions: Int
    let totalPages: Int
    let averagePagesPerSession: Double
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Sessions",
                value: "\(totalSessions)",
                icon: "folder",
                color: .blue
            )
            
            StatCard(
                title: "Pages",
                value: "\(totalPages)",
                icon: "doc.text",
                color: .green
            )
            
            StatCard(
                title: "Avg Pages",
                value: String(format: "%.1f", averagePagesPerSession),
                icon: "chart.bar.fill",
                color: .orange
            )
        }
    }
}

/// Statistics card view
struct StatCard: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
#if os(macOS)
        .background(.fill.quaternary, in: .rect(cornerRadius: 12))
#else
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
#endif
    }
}

#Preview {
    HistoryHeaderView(
        totalSessions: 5,
        totalPages: 42,
        averagePagesPerSession: 8.4
    )
    .padding()
}
