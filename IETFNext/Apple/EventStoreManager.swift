/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for the app.
*/

import EventKit
import Observation

@MainActor
@Observable
final class EventStoreManager {
    /// Contains fetched events when the app receives a full-access authorization status.
    var events: [EKEvent]
    
    /// Specifies the authorization status for the app.
    var authorizationStatus: EKAuthorizationStatus
    
    let dataStore: EventDataStore

    /// Cached calendar used for favorites; not displayed, so changes don't need to invalidate views.
    @ObservationIgnored var ietfNextCalendar: EKCalendar?

    init(store: EventDataStore = EventDataStore()) {
        self.dataStore = store
        self.events = []
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    var isWriteOnlyOrFullAccessAuthorized: Bool {
        if #available(iOS 17.0, macOS 14.0, *) {
            return ((authorizationStatus == .writeOnly) || (authorizationStatus == .fullAccess))
        } else {
            // Fall back on earlier versions.
            return authorizationStatus == .authorized
        }
    }
}
