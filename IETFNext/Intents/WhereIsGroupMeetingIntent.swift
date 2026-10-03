//
//  WhereIsGroupMeetingIntent.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents

/// Answers "where is QUIC meeting" for the current meeting without opening the app.
/// The type name is stored in saved shortcuts, so don't rename it.
struct WhereIsGroupMeetingIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Where a Group Meets"
    static let description = IntentDescription(
        "Tells you when and in which room a group meets at the meeting chosen in IETF Next."
    )
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Group", requestValueDialog: "Which group?")
    var group: GroupEntity

    @Dependency private var dataStore: IntentDataStore

    init() {}

    init(group: GroupEntity) {
        self.group = group
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Find where \(\.$group) meets")
    }

    func perform() async throws -> some ReturnsValue<[SessionEntity]> & ProvidesDialog & ShowsSnippetIntent {
        guard let number = dataStore.currentMeetingNumber() else {
            throw IETFIntentError.noMeetingSelected
        }
        let all = try await dataStore.sessions(groupAcronym: group.id)
        let now = Date()
        let upcoming = all.filter { $0.end > now }
        let acronym = group.acronym.uppercased()

        let dialog: IntentDialog
        let shown: [SessionEntity]
        if let next = upcoming.first {
            let place = next.place ?? "a room to be announced"
            if next.start <= now {
                dialog = "\(acronym) is meeting now in \(place)."
            } else {
                dialog = "\(acronym) meets \(next.startDescription) in \(place)."
            }
            shown = upcoming
        } else if all.isEmpty {
            dialog = "\(acronym) isn't meeting at IETF \(number)."
            shown = []
        } else {
            dialog = "\(acronym) has already met at IETF \(number)."
            shown = all
        }
        return .result(value: shown, dialog: dialog, snippetIntent: SessionsSnippetIntent(sessions: shown))
    }
}
