//
//  IntentsSync.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import Foundation

/// Keeps Siri and Spotlight in step with changes made in the app's UI.
enum IntentsSync {

    /// Call after a group's favorite flag is saved. Updates the group's Spotlight entry
    /// and the groups Siri phrases offer ("Where is QUIC meeting"), which list favorites
    /// first.
    static func favoriteChanged(groupAcronym: String?) {
        guard let groupAcronym else {
            return
        }
        Task(priority: .utility) {
            try? await SpotlightIndexer(dataStore: .shared).indexGroups(acronyms: [groupAcronym])
            IETFNextShortcuts.updateAppShortcutParameters()
        }
    }
}
