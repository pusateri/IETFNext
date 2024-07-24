//
//  EKEvent+Extension.swift
//  IETFNext
//
//  Created by Tom Pusateri on 7/22/24.
//

import CoreData
import EventKit

extension EKEvent {
        /// Creates a nonfloating event that uses the specified session, event store, and calendar.
    convenience init(session: Session, eventStore store: EKEventStore, calendar: EKCalendar?) {
        self.init(eventStore: store)
        self.title = session.name
        self.calendar = calendar
        self.startDate = session.start
        self.endDate = session.end
        self.timeZone = TimeZone.gmt
    }
}
