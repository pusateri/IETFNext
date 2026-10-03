//
//  FindSessionsIntent.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents

/// Answers "what's on now", "what's next", and "what's on today" for the current meeting
/// without opening the app. The type name is stored in saved shortcuts, so don't rename it.
struct FindSessionsIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Sessions"
    static let description = IntentDescription(
        "Tells you which sessions are on now, next, or later today at the meeting chosen in IETF Next."
    )
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Timeframe", default: .next, requestDisambiguationDialog: "Now, next, or later today?")
    var timeframe: SessionTimeframe

    @Parameter(
        title: "Favorites Only",
        description: "Only sessions of your favorite groups. Ignored if you have no favorites.",
        default: true
    )
    var favoritesOnly: Bool

    @Dependency private var dataStore: IntentDataStore

    init() {}

    init(timeframe: SessionTimeframe) {
        self.timeframe = timeframe
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Find \(\.$timeframe) sessions") {
            \.$favoritesOnly
        }
    }

    func perform() async throws -> some ReturnsValue<[SessionEntity]> & ProvidesDialog & ShowsSnippetIntent {
        guard let number = dataStore.currentMeetingNumber() else {
            throw IETFIntentError.noMeetingSelected
        }
        // With no favorites at all, "favorites only" would always be empty.
        let favorites = favoritesOnly ? try await dataStore.hasFavoriteGroups() : false
        let sessions = try await dataStore.sessions(timeframe: timeframe, favoritesOnly: favorites, at: Date())
        return .result(
            value: sessions,
            dialog: dialog(for: sessions, favorites: favorites, meetingNumber: number),
            snippetIntent: SessionsSnippetIntent(sessions: sessions)
        )
    }

    private func dialog(for sessions: [SessionEntity], favorites: Bool, meetingNumber: String) -> IntentDialog {
        guard let first = sessions.first else {
            switch (timeframe, favorites) {
            case (.now, true):
                return "None of your favorite groups are meeting right now."
            case (.now, false):
                return "Nothing is on right now at IETF \(meetingNumber)."
            case (.next, true):
                return "None of your favorite groups have any more sessions at IETF \(meetingNumber)."
            case (.next, false):
                return "There are no more sessions at IETF \(meetingNumber)."
            case (.today, true):
                return "None of your favorite groups have any more sessions today."
            case (.today, false):
                return "There are no more sessions today at IETF \(meetingNumber)."
            }
        }
        let acronym = first.groupAcronym.uppercased()
        let place = first.place ?? "a room to be announced"
        if sessions.count == 1 {
            switch timeframe {
            case .now:
                return "\(acronym) is meeting now in \(place)."
            case .next:
                return "Next up is \(acronym) at \(first.startDescription) in \(place)."
            case .today:
                return "\(acronym) is the only session left today, at \(first.startTime) in \(place)."
            }
        }
        let acronyms = sessions.map { $0.groupAcronym.uppercased() }
        switch timeframe {
        case .now:
            return "On now: \(acronyms.formatted(.list(type: .and)))."
        case .next:
            return "Next, at \(first.startDescription): \(acronyms.formatted(.list(type: .and)))."
        case .today:
            return "\(sessions.count) more sessions today, starting with \(acronym) at \(first.startTime) in \(place)."
        }
    }
}
