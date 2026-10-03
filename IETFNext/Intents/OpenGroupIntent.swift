//
//  OpenGroupIntent.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents

/// Brings the app forward and shows a group. The type name is stored in saved
/// shortcuts, so don't rename it.
struct OpenGroupIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Group"
    static let description = IntentDescription("Shows a working group or research group in IETF Next.")
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Group", requestValueDialog: "Which group?")
    var target: GroupEntity

    @Dependency private var navigator: AppNavigator

    init() {}

    init(group: GroupEntity) {
        self.target = group
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        navigator.open(.group(acronym: target.id))
        return .result()
    }
}
