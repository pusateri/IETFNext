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

    /// Most recent favorite-to-calendar sync. Each new sync waits on this so updates apply in order.
    @ObservationIgnored var calendarUpdateTask: Task<Void, Never>?

    init(store: EventDataStore = EventDataStore()) {
        self.dataStore = store
        self.events = []
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    // The deployment target is iOS/macOS 26, so the pre-17 `.authorized` fallback branch was dead code.
    var isWriteOnlyOrFullAccessAuthorized: Bool {
        authorizationStatus == .writeOnly || authorizationStatus == .fullAccess
    }
}
