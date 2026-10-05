//
//  IntentDataStore.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import Foundation
import CoreData

/// Read access to the Core Data store for App Intents and entity queries.
///
/// Intents don't run on the main actor, so they can't use the view context. Each read
/// gets its own background context, and the closure must convert managed objects to
/// plain values before returning; managed objects never leave `read(_:)`.
final class IntentDataStore: @unchecked Sendable {
    // @unchecked: the stored state is the container, whose `newBackgroundContext()` is
    // safe to call from any thread, and `UserDefaults`, which is thread-safe. All managed
    // object access happens inside the context's `perform`.

    static let shared = IntentDataStore(container: RFCProvider.shared.container)

    /// The `UserDefaults` key holding the number of the meeting chosen in the app.
    static let meetingNumberKey = "MeetingNumber"

    /// The `UserDefaults` key for the Use Local Time setting.
    static let useLocalTimeKey = "UseLocalTime"

    private let container: NSPersistentContainer

    /// Where the app's settings are read from; tests pass their own suite.
    let defaults: UserDefaults

    init(container: NSPersistentContainer, defaults: UserDefaults = .standard) {
        self.container = container
        self.defaults = defaults
    }

    /// Runs `body` on a new background context and returns its result.
    func read<Value: Sendable>(_ body: @escaping (NSManagedObjectContext) throws -> Value) async throws -> Value {
        let context = container.newBackgroundContext()
        return try await context.perform {
            try body(context)
        }
    }

    /// The number of the meeting the app currently shows, if one has been chosen.
    func currentMeetingNumber() -> String? {
        defaults.string(forKey: Self.meetingNumberKey)
    }
}
