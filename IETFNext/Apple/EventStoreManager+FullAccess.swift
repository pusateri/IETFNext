/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for the app.
*/

import EventKit

extension EventStoreManager {
    /*
        Listens for event store changes, which are always posted on the main thread. When the app receives a full access authorization status, it
        fetches all events occuring within a month in all the user's calendars.
    */
    func listenForCalendarChanges() async {
        let center = NotificationCenter.default
        let notifications = center.notifications(named: .EKEventStoreChanged).map({ (notification: Notification) in notification.name })
        
        for await _ in notifications {
            guard await dataStore.isFullAccessAuthorized else { return }
            //await self.fetchLatestEvents()
        }
    }
    
    func setupEventStore() async throws {
        let response = try await dataStore.verifyAuthorizationStatus()
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if response {
            //await fetchLatestEvents()
        }
    }

    func removeEvent(_ event: EKEvent) async throws {
        try await dataStore.removeEvent(event)
    }

    func setIETFNextCalendar() {
        let calendars = dataStore.eventStore.calendars(for: .event)

        if (ietfNextCalendar == nil) {
            for calendar in calendars {
                if calendar.title == "IETFNext" {
                    ietfNextCalendar = (calendar as EKCalendar)
                    break
                } else if calendar.title == "IETFers" {
                    ietfNextCalendar = (calendar as EKCalendar)
                    break
                }
            }

            if (ietfNextCalendar == nil) {
                ietfNextCalendar = EKCalendar(for: .event, eventStore: dataStore.eventStore)
                ietfNextCalendar!.title = "IETFNext"
                ietfNextCalendar!.source = dataStore.eventStore.defaultCalendarForNewEvents?.source

                do {
                    try dataStore.eventStore.saveCalendar(ietfNextCalendar!, commit: true)
                } catch {
                    print("Error saving Calendar: \(error.localizedDescription)")
                }
            }
        }
    }
}
