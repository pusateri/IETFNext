//
//  Session+Extension.swift
//  IETFNext
//
//  Created by Tom Pusateri on 7/22/24.
//

import Foundation
import CoreData
import EventKit

/// One day's sessions for a sectioned session list.
///
/// Built once per list render. The previous code grouped with `Dictionary(grouping:)`, then sorted
/// the keys twice and split each key string several times per row.
/// TODO(performance): cache these in state and rebuild only when the fetch results or the
/// formatter change, instead of on every body evaluation.
struct SessionDaySection: Identifiable {
    /// Sortable key from the session formatter, "yyyy-MM-dd EEEE:EEE". Unique per day.
    let id: String
    /// Section header, e.g. "2025-07-21 Monday".
    let title: String
    /// Short day for the jump index, e.g. "Mon".
    let shortDay: String
    /// Sessions in fetch order.
    let sessions: [Session]

    /// Groups sessions by day using `formatter`, sorted chronologically.
    /// - Parameter requireGroup: Drop sessions with no group (rows that couldn't be displayed).
    static func sections(from sessions: some Sequence<Session>, formatter: DateFormatter, requireGroup: Bool = false) -> [SessionDaySection] {
        let usable = sessions.filter { $0.start != nil && (!requireGroup || $0.group != nil) }
        let grouped = Dictionary(grouping: usable) { formatter.string(from: $0.start!) }
        return grouped.keys.sorted().map { key in
            let parts = key.components(separatedBy: ":")
            return SessionDaySection(
                id: key,
                title: parts.first ?? key,
                shortDay: parts.count > 1 ? parts[1] : "",
                sessions: grouped[key] ?? []
            )
        }
    }
}

extension Session {
    @MainActor func createEvent(storeManager: EventStoreManager, calendar: EKCalendar? = nil) async {
        let calendar = storeManager.ietfNextCalendar
        let newEvent = EKEvent(session: self,
                               eventStore: storeManager.dataStore.eventStore,
                               calendar: calendar ?? storeManager.dataStore.eventStore.defaultCalendarForNewEvents)
        do {
            try storeManager.dataStore.eventStore.save(newEvent, span: .thisEvent)
            self.eventId = newEvent.eventIdentifier
        }
        catch {
            print("Save calendar event failed: \(error.localizedDescription)")
        }
    }
    @MainActor func deleteEvent(storeManager: EventStoreManager) async {
        let store = storeManager.dataStore.eventStore
        if let identifier = self.eventId {
            if let event = store.event(withIdentifier: identifier) {
                do {
                    try await storeManager.removeEvent(event)
                }
                catch {
                    print("Delete calendar event failed: \(error.localizedDescription)")
                }
                self.eventId = nil
            }
        }
    }
}
