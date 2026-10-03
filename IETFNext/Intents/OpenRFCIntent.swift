//
//  OpenRFCIntent.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents

/// Brings the app forward and shows an RFC. The type name is stored in saved
/// shortcuts, so don't rename it.
struct OpenRFCIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open RFC"
    static let description = IntentDescription("Shows an RFC in IETF Next.")
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "RFC", requestValueDialog: "Which RFC?")
    var target: RFCEntity

    @Dependency private var navigator: AppNavigator

    init() {}

    init(rfc: RFCEntity) {
        self.target = rfc
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        navigator.open(.rfc(name: target.id))
        return .result()
    }
}
