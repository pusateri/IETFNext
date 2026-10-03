//
//  OpenSessionIntent.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents

/// Brings the app forward and shows a session in the schedule. The type name is stored
/// in saved shortcuts, so don't rename it.
struct OpenSessionIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Session"
    static let description = IntentDescription("Shows a session in the IETF Next schedule.")
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Session", requestValueDialog: "Which session?")
    var target: SessionEntity

    @Dependency private var navigator: AppNavigator

    init() {}

    init(session: SessionEntity) {
        self.target = session
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = Int32(exactly: target.id) else {
            throw AppIntentError.Unrecoverable.entityNotFound
        }
        navigator.open(.session(id: id))
        return .result()
    }
}
