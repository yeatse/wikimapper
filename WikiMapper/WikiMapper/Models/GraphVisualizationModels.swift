//
//  GraphVisualizationModels.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/20.
//

import Foundation

// MARK: - Graph Data Models

/// Node data structure for Grape visualization
struct GraphNode: Identifiable, Equatable {
    let id: Double
    let title: String
    let url: String
    let date: Date
    let isRoot: Bool
    let level: Int
    let childrenCount: Int
    
    init(from node: WikiMapperNode, level: Int = 0) {
        self.id = node.id
        self.title = node.pageTitle
        self.url = node.data.url
        self.date = node.data.dateObject
        self.isRoot = node.isRoot
        self.level = level
        self.childrenCount = node.children.count
    }
}

/// Link data structure for Grape visualization
struct GraphLink: Identifiable {
    let id: String
    let source: Double
    let target: Double
    
    init(from parent: WikiMapperNode, to child: WikiMapperNode) {
        self.source = parent.id
        self.target = child.id
        self.id = "\(parent.id)-\(child.id)"
    }
}

// MARK: - Graph Data Converter

/// Utility for converting WikiMapper data to graph format
struct GraphDataConverter {
    /// Convert WikiMapper session to graph data
    static func convertSession(_ session: WikiMapperSession) -> (nodes: [GraphNode], links: [GraphLink]) {
        var allNodes: [GraphNode] = []
        var allLinks: [GraphLink] = []
        
        func processNode(_ node: WikiMapperNode, level: Int) {
            let graphNode = GraphNode(from: node, level: level)
            allNodes.append(graphNode)
            
            // Process children and create links
            for child in node.children {
                let link = GraphLink(from: node, to: child)
                allLinks.append(link)
                processNode(child, level: level + 1)
            }
        }
        
        processNode(session.tree, level: 0)
        return (nodes: allNodes, links: allLinks)
    }
    
    /// Filter nodes based on search criteria
    static func filterNodes(_ nodes: [GraphNode], searchText: String) -> Set<Double> {
        if searchText.isEmpty {
            return []
        }
        
        return Set(nodes.compactMap { node in
            if node.title.localizedCaseInsensitiveContains(searchText) ||
               node.url.localizedCaseInsensitiveContains(searchText) {
                return node.id
            }
            return nil
        })
    }
}