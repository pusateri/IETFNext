//
//  RFCEntityQuery.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents
import CoreSpotlight

/// Looks up RFCs by number or title. The index has over 9,000 RFCs, so every method
/// fetches only what it needs; nothing loads the whole index.
struct RFCEntityQuery: EntityStringQuery {
    @Dependency private var dataStore: IntentDataStore

    func entities(for identifiers: [RFCEntity.ID]) async throws -> [RFCEntity] {
        try await dataStore.rfcs(names: identifiers)
    }

    /// "9000", "rfc9000", and "RFC 9000" match by number; anything else matches titles.
    func entities(matching string: String) async throws -> [RFCEntity] {
        try await dataStore.rfcs(matching: string, limit: 25)
    }

    /// The most recently published RFCs.
    func suggestedEntities() async throws -> [RFCEntity] {
        try await dataStore.recentRFCs(limit: 20)
    }
}

@available(iOS 27.0, macOS 27.0, *)
extension RFCEntityQuery: IndexedEntityQuery {
    func reindexEntities(for identifiers: [RFCEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(dataStore.rfcs(names: identifiers))
    }

    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await SpotlightIndexer(dataStore: dataStore).indexRFCs()
    }
}
