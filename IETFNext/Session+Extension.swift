//
//  Session+Extension.swift
//  IETFNext
//
//  Created by Tom Pusateri on 7/22/24.
//

import Foundation
import CoreData
import EventKit

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
