//
//  SessionRowView.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/20.
//

import SwiftUI

/// Individual session row view
struct SessionRowView: View {
    let session: WikiMapperSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.tree.pageTitle)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(session.formattedStartDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(session.totalPagesCount) pages")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    
                    Text(session.formattedDuration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if session.tree.children.count > 0 {
                HStack {
                    Text("Path:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    let pathText = ([session.tree.pageTitle] + session.tree.children.prefix(2).map { $0.pageTitle }).joined(separator: " → ")
                    
                    Text(pathText + (session.tree.children.count > 2 ? " ..." : ""))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}