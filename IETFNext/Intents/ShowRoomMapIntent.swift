//
//  ShowRoomMapIntent.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents

/// Shows the floor map for the room where a session meets. The type name is stored in
/// saved shortcuts, so don't rename it.
struct ShowRoomMapIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Room Map"
    static let description = IntentDescription("Shows the floor map for the room where a session meets.")
    // Starts in the background so a session without a room fails without opening the app.
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    @Parameter(title: "Session", requestValueDialog: "Which session?")
    var session: SessionEntity

    @Dependency private var navigator: AppNavigator

    init() {}

    init(session: SessionEntity) {
        self.session = session
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Show the room map for \(\.$session)")
    }

    func perform() async throws -> some IntentResult {
        guard let locationID = session.locationID, let id = Int32(exactly: locationID) else {
            throw IETFIntentError.noRoom
        }
        guard systemContext.currentMode.canContinueInForeground else {
            throw needsToContinueInForegroundError("Open IETF Next to see the map for \(session.room ?? "this room").")
        }
        try await continueInForeground(alwaysConfirm: false)
        await navigator.open(.location(id: id))
        return .result()
    }
}
