//
//  SessionTimeframe.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents

/// Which part of the schedule a person is asking about.
///
/// Saved shortcuts store the raw values, so never change or reuse them; only append.
enum SessionTimeframe: String, AppEnum {
    case now = "now"
    case next = "next"
    case today = "today"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Timeframe"

    static let caseDisplayRepresentations: [SessionTimeframe: DisplayRepresentation] = [
        .now: "Now",
        .next: "Next",
        .today: "Today",
    ]
}
