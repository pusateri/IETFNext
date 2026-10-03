//
//  IETFNextShortcuts.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents

/// The Siri phrases that work without any setup. Once shipped, phrases are what people
/// say out loud: add new ones freely, but don't reword or remove existing ones.
/// Every phrase must include the app name or the system drops it. At most 10 shortcuts.
struct IETFNextShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FindSessionsIntent(timeframe: .next),
            phrases: [
                "What's next in \(.applicationName)",
                "What's my next session in \(.applicationName)",
                "Next session in \(.applicationName)",
            ],
            shortTitle: "What's Next",
            systemImageName: "clock"
        )
        AppShortcut(
            intent: FindSessionsIntent(timeframe: .now),
            phrases: [
                "What's on now in \(.applicationName)",
                "What's happening now in \(.applicationName)",
            ],
            shortTitle: "On Now",
            systemImageName: "dot.radiowaves.left.and.right"
        )
        AppShortcut(
            intent: FindSessionsIntent(timeframe: .today),
            phrases: [
                "What's on today in \(.applicationName)",
                "Show today's sessions in \(.applicationName)",
            ],
            shortTitle: "Today",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: WhereIsGroupMeetingIntent(),
            phrases: [
                "Where is \(\.$group) meeting in \(.applicationName)",
                "Where does \(\.$group) meet in \(.applicationName)",
                "When does \(\.$group) meet in \(.applicationName)",
                "Find a group's room in \(.applicationName)",
            ],
            shortTitle: "Where's My Group",
            systemImageName: "mappin.and.ellipse"
        )
        AppShortcut(
            intent: OpenGroupIntent(),
            phrases: [
                "Show \(\.$target) in \(.applicationName)",
                "Open a group in \(.applicationName)",
            ],
            shortTitle: "Open Group",
            systemImageName: "person.3"
        )
        AppShortcut(
            intent: OpenRFCIntent(),
            phrases: [
                "Open \(\.$target) in \(.applicationName)",
                "Open an RFC in \(.applicationName)",
                "Look up an RFC in \(.applicationName)",
            ],
            shortTitle: "Open RFC",
            systemImageName: "doc.plaintext"
        )
    }
}
