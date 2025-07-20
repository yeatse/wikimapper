//
//  WikiMapperDataService.swift
//  WikiMapper
//
//  Created by Claude on 2025/7/19.
//

import Foundation
import Combine

/// Service for managing WikiMapper data from UserDefaults
@MainActor
class WikiMapperDataService: ObservableObject {
    // MARK: - Published Properties
    
    @Published var sessions: [WikiMapperSession] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    private let keyPrefix = "wikimapper_"
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        // Use the shared UserDefaults suite that matches SafariWebExtensionHandler
        self.userDefaults = UserDefaults(suiteName: "group.wikimapper.storage") ?? UserDefaults.standard
        
        // Start monitoring for changes
        startMonitoring()
        
        // Load initial data
        Task {
            await loadSessions()
        }
    }
    
    deinit {
        // Note: stopMonitoring() is called from deinit, so we need to handle this properly
        // Since deinit runs on the actor that owns the instance, this should be safe
        refreshTimer?.invalidate()
        refreshTimer = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Load all sessions from UserDefaults
    func loadSessions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedSessions = try await loadSessionsFromStorage()
            sessions = loadedSessions.sorted { $0.startDate > $1.startDate }
            lastUpdateTime = Date()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            print("WikiMapper DataService Error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh data manually
    func refresh() async {
        await loadSessions()
    }
    
    /// Get a specific session by ID
    func getSession(withId sessionId: Double) -> WikiMapperSession? {
        sessions.first { $0.id == sessionId }
    }
    
    /// Search across all sessions
    func search(for query: String) -> [(session: WikiMapperSession, nodes: [WikiMapperNode])] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        var results: [(session: WikiMapperSession, nodes: [WikiMapperNode])] = []
        
        for session in sessions {
            let foundNodes = session.search(for: query)
            if !foundNodes.isEmpty {
                results.append((session: session, nodes: foundNodes))
            }
        }
        
        return results
    }
    
    /// Filter sessions by date range
    func filterSessions(from startDate: Date, to endDate: Date) -> [WikiMapperSession] {
        sessions.filter { session in
            session.startDate >= startDate && session.startDate <= endDate
        }
    }
    
    /// Get statistics for all sessions
    func getStatistics() -> SessionStatistics {
        SessionStatistics(
            totalSessions: sessions.count,
            totalPages: sessions.reduce(0) { $0 + $1.totalPagesCount },
            totalDuration: sessions.reduce(0) { $0 + $1.duration },
            earliestSession: sessions.map { $0.startDate }.min(),
            latestSession: sessions.map { $0.startDate }.max()
        )
    }
    
    /// Clear all sessions (for testing/reset purposes)
    func clearAllSessions() {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix(keyPrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
        userDefaults.synchronize()
        
        Task {
            await loadSessions()
        }
    }
    
    // MARK: - Private Methods
    
    /// Load sessions from UserDefaults storage
    private func loadSessionsFromStorage() async throws -> [WikiMapperSession] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: WikiMapperError.serviceUnavailable)
                    return
                }
                
                do {
                    let sessions = try self.parseSessionsFromUserDefaults()
                    continuation.resume(returning: sessions)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Parse sessions from UserDefaults
    private func parseSessionsFromUserDefaults() throws -> [WikiMapperSession] {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        var sessions: [WikiMapperSession] = []
        
        for key in allKeys {
            if key.hasPrefix(keyPrefix) {
                let sessionKey = String(key.dropFirst(keyPrefix.count))
                
                // Skip non-numeric session keys (like tabStatus, activeSessions)
                guard let sessionId = Double(sessionKey) else {
                    continue
                }
                
                guard let data = userDefaults.data(forKey: key) else {
                    continue
                }
                
                do {
                    let tree = try JSONDecoder().decode(WikiMapperNode.self, from: data)
                    let session = WikiMapperSession(id: sessionId, tree: tree)
                    sessions.append(session)
                } catch {
                    print("Failed to decode session \(sessionKey): \(error)")
                    // Continue with other sessions even if one fails
                }
            }
        }
        
        return sessions
    }
    
    /// Start monitoring UserDefaults for changes
    private func startMonitoring() {
        // Set up a timer to periodically check for updates
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.loadSessions()
            }
        }
        
        // Also monitor UserDefaults changes
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: userDefaults,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.loadSessions()
            }
        }
    }
    
    /// Stop monitoring
    private func stopMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Error Types

enum WikiMapperError: LocalizedError {
    case serviceUnavailable
    case dataCorrupted(String)
    case parsingFailed(String)
    case storageUnavailable
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "WikiMapper data service is unavailable"
        case .dataCorrupted(let details):
            return "Data is corrupted: \(details)"
        case .parsingFailed(let details):
            return "Failed to parse data: \(details)"
        case .storageUnavailable:
            return "Storage is not available"
        }
    }
}

// MARK: - Extensions

extension WikiMapperDataService {
    /// Get sample data for testing/preview purposes
    static func sampleData() -> [WikiMapperSession] {
        let sampleNodeData = WikiMapperNodeData(
            url: "https://en.wikipedia.org/wiki/Boston",
            date: Date().timeIntervalSince1970 * 1000,
            sessionId: Date().timeIntervalSince1970 * 1000,
            parentId: nil
        )
        
        let childNodeData = WikiMapperNodeData(
            url: "https://en.wikipedia.org/wiki/Massachusetts",
            date: Date().timeIntervalSince1970 * 1000 + 30000,
            sessionId: Date().timeIntervalSince1970 * 1000,
            parentId: 1
        )
        
        let childNode = WikiMapperNode(
            id: 2,
            name: "Massachusetts",
            data: childNodeData,
            children: []
        )
        
        let rootNode = WikiMapperNode(
            id: 1,
            name: "Boston",
            data: sampleNodeData,
            children: [childNode]
        )
        
        let session = WikiMapperSession(
            id: Date().timeIntervalSince1970 * 1000,
            tree: rootNode
        )
        
        return [session]
    }
}