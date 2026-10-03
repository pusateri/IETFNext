//
//  GroupEntityQuery.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents
import CoreSpotlight

struct GroupEntityQuery: EntityStringQuery {
    @Dependency private var dataStore: IntentDataStore

    func entities(for identifiers: [GroupEntity.ID]) async throws -> [GroupEntity] {
        try await dataStore.groups(acronyms: identifiers)
    }

    /// Groups whose acronym or name contain `string`, exact acronym matches first.
    func entities(matching string: String) async throws -> [GroupEntity] {
        try await dataStore.groups(matching: string, limit: 25)
    }

    /// Favorite groups first, then other groups meeting at the current meeting.
    func suggestedEntities() async throws -> [GroupEntity] {
        try await dataStore.suggestedGroups(limit: 30)
    }
}

@available(iOS 27.0, macOS 27.0, *)
extension GroupEntityQuery: IndexedEntityQuery {
    func reindexEntities(for identifiers: [GroupEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(dataStore.groups(acronyms: identifiers))
    }

    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await SpotlightIndexer(dataStore: dataStore).indexGroups()
    }
}
