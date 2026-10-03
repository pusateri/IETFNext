//
//  SessionsSnippetIntent.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents
import SwiftUI

/// Renders `SessionsSnippetView` for the schedule intents. The system may run this
/// again whenever it redraws the card, so it only reads.
struct SessionsSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Sessions"
    static let isDiscoverable = false

    @Parameter(title: "Sessions")
    var sessions: [SessionEntity]

    init() {}

    init(sessions: [SessionEntity]) {
        self.sessions = sessions
    }

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        .result(view: SessionsSnippetView(sessions: sessions))
    }
}
