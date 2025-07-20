//
//  WikiMapperNode.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/19.
//

import Foundation

// MARK: - WikiMapperNode Data Models

/// Represents the data associated with a WikiMapper node
struct WikiMapperNodeData: Codable, Hashable {
    let url: String
    let date: Double  // JavaScript timestamp with decimal precision
    let sessionId: Double
    let parentId: Double?
    
    /// Computed property to get Date object from timestamp
    var dateObject: Date {
        Date(timeIntervalSince1970: date / 1000.0)
    }
    
    /// Formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateObject)
    }
}

/// Represents a single page node in the WikiMapper browsing tree
struct WikiMapperNode: Codable, Hashable, Identifiable {
    let id: Double
    let name: String
    let data: WikiMapperNodeData
    var children: [WikiMapperNode]
    
    /// Computed property to check if this is a root node
    var isRoot: Bool {
        data.parentId == nil
    }
    
    /// Computed property to get the Wikipedia page title from URL
    var pageTitle: String {
        // Extract page title from Wikipedia URL
        if data.url.contains("Special:Search?search=") {
            return name // Already formatted for search results
        } else {
            // Decode URL and replace underscores with spaces
            let components = data.url.components(separatedBy: "/")
            if let lastComponent = components.last {
                return lastComponent.removingPercentEncoding?.replacingOccurrences(of: "_", with: " ") ?? name
            }
            return name
        }
    }
    
    /// Computed property to get a short URL for display
    var shortUrl: String {
        if let url = URL(string: data.url) {
            return url.host ?? data.url
        }
        return data.url
    }
    
    /// Recursively count total number of nodes in this subtree
    var totalNodeCount: Int {
        1 + children.reduce(0) { $0 + $1.totalNodeCount }
    }
    
    /// Find a node by ID recursively
    func findNode(withId nodeId: Double) -> WikiMapperNode? {
        if id == nodeId {
            return self
        }
        
        for child in children {
            if let found = child.findNode(withId: nodeId) {
                return found
            }
        }
        
        return nil
    }
    
    /// Find a node by URL recursively
    func findNode(withUrl url: String) -> WikiMapperNode? {
        if data.url == url {
            return self
        }
        
        for child in children {
            if let found = child.findNode(withUrl: url) {
                return found
            }
        }
        
        return nil
    }
    
    /// Get all nodes in this subtree as a flat array
    func getAllNodes() -> [WikiMapperNode] {
        var nodes = [self]
        for child in children {
            nodes.append(contentsOf: child.getAllNodes())
        }
        return nodes
    }
    
    /// Get the depth level of this node (0 for root)
    func getDepth() -> Int {
        return isRoot ? 0 : 1 + (parent?.getDepth() ?? 0)
    }
    
    /// Find parent node in the complete tree (helper for navigation)
    private var parent: WikiMapperNode? {
        // This would need to be set externally when building the tree
        // or computed by searching the complete session tree
        return nil
    }
}

/// Extension to support tree manipulation
extension WikiMapperNode {
    /// Add a child node
    mutating func addChild(_ child: WikiMapperNode) {
        children.append(child)
    }
    
    /// Remove a child node by ID
    mutating func removeChild(withId childId: Double) {
        children.removeAll { $0.id == childId }
    }
    
    /// Update node name
    mutating func updateName(_ newName: String) {
        // Note: This creates a new instance since struct is immutable
        // In practice, you'd need to update the parent container
    }
}

/// Extension for search and filtering
extension WikiMapperNode {
    /// Search for nodes containing the given text in name or URL
    func search(for text: String) -> [WikiMapperNode] {
        var results: [WikiMapperNode] = []
        
        let searchText = text.lowercased()
        if name.lowercased().contains(searchText) || data.url.lowercased().contains(searchText) {
            results.append(self)
        }
        
        for child in children {
            results.append(contentsOf: child.search(for: text))
        }
        
        return results
    }
    
    /// Filter nodes by date range
    func filterByDateRange(from startDate: Date, to endDate: Date) -> [WikiMapperNode] {
        var results: [WikiMapperNode] = []
        
        if data.dateObject >= startDate && data.dateObject <= endDate {
            results.append(self)
        }
        
        for child in children {
            results.append(contentsOf: child.filterByDateRange(from: startDate, to: endDate))
        }
        
        return results
    }
}