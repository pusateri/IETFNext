//
//  IETFIntentError.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents

/// Failures an intent reports to Siri and Shortcuts. Conforming to
/// `CustomLocalizedStringResourceConvertible` is what makes the message reach the
/// person instead of a generic failure.
enum IETFIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noMeetingSelected
    case noRoom

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noMeetingSelected:
            "No meeting is selected. Open IETF Next and choose a meeting first."
        case .noRoom:
            "This session doesn't have a room yet."
        }
    }
}
