//
//  WikiMapperSession.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/19.
//

import Foundation

// MARK: - WikiMapper Session Models

/// Represents an active browsing session metadata
struct WikiMapperActiveSession: Codable, Hashable {
    let id: Double
    let tabs: [Int]
    let nodeIndex: Double
    
    /// Computed property to get Date object from session ID (timestamp)
    var startDate: Date {
        Date(timeIntervalSince1970: id / 1000.0)
    }
    
    /// Formatted start date for display
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
}

/// Represents a complete WikiMapper browsing session with its tree data
struct WikiMapperSession: Codable, Hashable, Identifiable {
    let id: Double
    let tree: WikiMapperNode
    var checked: Bool = false
    var hidden: Bool = false
    
    /// Computed property to get session start date
    var startDate: Date {
        Date(timeIntervalSince1970: id / 1000.0)
    }
    
    /// Computed property to get session end date (last navigation)
    var endDate: Date {
        let allNodes = tree.getAllNodes()
        let latestTimestamp = allNodes.map { $0.data.date }.max() ?? id
        return Date(timeIntervalSince1970: latestTimestamp / 1000.0)
    }
    
    /// Computed property to get session duration
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    /// Formatted duration string
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    /// Formatted start date for display
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
    
    /// Session title for display (root node name + date)
    var displayTitle: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: startDate)
        return "\(tree.name) - \(dateString)"
    }
    
    /// Total number of pages visited in this session
    var totalPagesCount: Int {
        tree.totalNodeCount
    }
    
    /// Get all unique URLs visited in this session
    var allUrls: [String] {
        tree.getAllNodes().map { $0.data.url }
    }
    
    /// Search within this session
    func search(for text: String) -> [WikiMapperNode] {
        tree.search(for: text)
    }
    
    /// Filter nodes by date range within this session
    func filterByDateRange(from startDate: Date, to endDate: Date) -> [WikiMapperNode] {
        tree.filterByDateRange(from: startDate, to: endDate)
    }
    
    /// Get browsing path from root to a specific node
    func getPathToNode(withId nodeId: Double) -> [WikiMapperNode]? {
        return findPath(from: tree, to: nodeId)
    }
    
    private func findPath(from node: WikiMapperNode, to targetId: Double) -> [WikiMapperNode]? {
        if node.id == targetId {
            return [node]
        }
        
        for child in node.children {
            if let path = findPath(from: child, to: targetId) {
                return [node] + path
            }
        }
        
        return nil
    }
}

/// Container for managing multiple sessions
struct WikiMapperSessionContainer: Codable {
    var sessions: [WikiMapperSession]
    
    init() {
        self.sessions = []
    }
    
    init(sessions: [WikiMapperSession]) {
        self.sessions = sessions
    }
    
    /// Add a new session
    mutating func addSession(_ session: WikiMapperSession) {
        sessions.append(session)
        sortSessionsByDate()
    }
    
    /// Remove a session by ID
    mutating func removeSession(withId sessionId: Double) {
        sessions.removeAll { $0.id == sessionId }
    }
    
    /// Get a session by ID
    func getSession(withId sessionId: Double) -> WikiMapperSession? {
        sessions.first { $0.id == sessionId }
    }
    
    /// Sort sessions by start date (newest first)
    mutating func sortSessionsByDate() {
        sessions.sort { $0.startDate > $1.startDate }
    }
    
    /// Filter sessions by date range
    func filterByDateRange(from startDate: Date, to endDate: Date) -> [WikiMapperSession] {
        sessions.filter { 
            $0.startDate >= startDate && $0.startDate <= endDate 
        }
    }
    
    /// Search across all sessions
    func search(for text: String) -> [(session: WikiMapperSession, nodes: [WikiMapperNode])] {
        var results: [(session: WikiMapperSession, nodes: [WikiMapperNode])] = []
        
        for session in sessions {
            let foundNodes = session.search(for: text)
            if !foundNodes.isEmpty {
                results.append((session: session, nodes: foundNodes))
            }
        }
        
        return results
    }
    
    /// Get total statistics
    var statistics: SessionStatistics {
        SessionStatistics(
            totalSessions: sessions.count,
            totalPages: sessions.reduce(0) { $0 + $1.totalPagesCount },
            totalDuration: sessions.reduce(0) { $0 + $1.duration },
            earliestSession: sessions.map { $0.startDate }.min(),
            latestSession: sessions.map { $0.startDate }.max()
        )
    }
}

/// Statistics about all sessions
struct SessionStatistics {
    let totalSessions: Int
    let totalPages: Int
    let totalDuration: TimeInterval
    let earliestSession: Date?
    let latestSession: Date?
    
    var formattedTotalDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .full
        return formatter.string(from: totalDuration) ?? "0 minutes"
    }
    
    var averagePagesPerSession: Double {
        totalSessions > 0 ? Double(totalPages) / Double(totalSessions) : 0
    }
    
    var averageSessionDuration: TimeInterval {
        totalSessions > 0 ? totalDuration / Double(totalSessions) : 0
    }
}

/// Extension for UserDefaults integration
extension WikiMapperSession {
    /// Create session from UserDefaults data
    static func fromUserDefaultsData(sessionId: String, data: Data) -> WikiMapperSession? {
        do {
            let tree = try JSONDecoder().decode(WikiMapperNode.self, from: data)
            guard let sessionIdDouble = Double(sessionId) else { return nil }
            return WikiMapperSession(id: sessionIdDouble, tree: tree)
        } catch {
            print("Failed to decode session data: \(error)")
            return nil
        }
    }
}
