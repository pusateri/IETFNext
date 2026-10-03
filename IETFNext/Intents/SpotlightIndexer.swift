//
//  SpotlightIndexer.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import Foundation
import CoreSpotlight

/// Adds sessions, groups, and RFCs to Spotlight as App Intents entities, so a search
/// result opens the item through the entity's query.
struct SpotlightIndexer: Sendable {
    let dataStore: IntentDataStore

    /// `UserDefaults` key recording that the RFC index has been added to Spotlight at least once.
    private static let rfcsIndexedKey = "SpotlightRFCsIndexed"

    /// RFCs are indexed in pages to keep memory bounded; the index has over 9,000.
    private static let rfcPageSize = 1000

    /// Replaces the indexed sessions with those of the current meeting.
    func indexCurrentMeeting() async throws {
        if let number = dataStore.currentMeetingNumber() {
            try await indexSessions(meetingNumber: number)
        }
    }

    /// Replaces the indexed sessions with those of `meetingNumber`. Only one meeting's
    /// sessions are indexed at a time.
    func indexSessions(meetingNumber: String) async throws {
        guard CSSearchableIndex.isIndexingAvailable() else {
            return
        }
        let sessions = try await dataStore.allSessions(meetingNumber: meetingNumber)
        let index = CSSearchableIndex.default()
        try await index.deleteAppEntities(ofType: SessionEntity.self)
        try await index.indexAppEntities(sessions)
    }

    func indexGroups() async throws {
        guard CSSearchableIndex.isIndexingAvailable() else {
            return
        }
        try await CSSearchableIndex.default().indexAppEntities(dataStore.allGroups())
    }

    /// Updates specific groups, for example after one becomes a favorite.
    func indexGroups(acronyms: [String]) async throws {
        guard CSSearchableIndex.isIndexingAvailable() else {
            return
        }
        try await CSSearchableIndex.default().indexAppEntities(dataStore.groups(acronyms: acronyms))
    }

    func indexRFCs() async throws {
        guard CSSearchableIndex.isIndexingAvailable() else {
            return
        }
        let index = CSSearchableIndex.default()
        var offset = 0
        while true {
            try Task.checkCancellation()
            let page = try await dataStore.rfcs(offset: offset, limit: Self.rfcPageSize)
            if page.isEmpty {
                break
            }
            try await index.indexAppEntities(page)
            offset += page.count
        }
        UserDefaults.standard.set(true, forKey: Self.rfcsIndexedKey)
    }

    /// Indexes RFCs when the index was just refreshed, or if it has never been indexed
    /// (for example, right after updating to a version with Spotlight support).
    func indexRFCs(indexRefreshed: Bool) async throws {
        if indexRefreshed || !UserDefaults.standard.bool(forKey: Self.rfcsIndexedKey) {
            try await indexRFCs()
        }
    }
}
