//
//  SessionEntityQuery.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents
import CoreSpotlight

struct SessionEntityQuery: EntityStringQuery {
    @Dependency private var dataStore: IntentDataStore

    func entities(for identifiers: [SessionEntity.ID]) async throws -> [SessionEntity] {
        try await dataStore.sessions(ids: identifiers)
    }

    /// Sessions at the current meeting whose name, group acronym, or group name contain `string`.
    func entities(matching string: String) async throws -> [SessionEntity] {
        try await dataStore.sessions(matching: string, limit: 25)
    }

    /// The next sessions at the current meeting.
    func suggestedEntities() async throws -> [SessionEntity] {
        try await dataStore.upcomingSessions(favoritesOnly: false, after: Date(), limit: 10)
    }
}

@available(iOS 27.0, macOS 27.0, *)
extension SessionEntityQuery: IndexedEntityQuery {
    func reindexEntities(for identifiers: [SessionEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(dataStore.sessions(ids: identifiers))
    }

    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await SpotlightIndexer(dataStore: dataStore).indexCurrentMeeting()
    }
}
