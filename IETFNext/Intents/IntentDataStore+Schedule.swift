//
//  IntentDataStore+Schedule.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import Foundation
import CoreData

// Schedule questions asked through Siri: what's on now, next, or today, and where a
// group meets.
extension IntentDataStore {

    /// The current meeting's sessions for `timeframe`.
    ///
    /// - `now`: sessions in progress at `date`.
    /// - `next`: the sessions in the earliest time slot starting after `date`. Many
    ///   sessions run in parallel, so this is usually several.
    /// - `today`: today's sessions that haven't ended yet.
    func sessions(timeframe: SessionTimeframe, favoritesOnly: Bool, at date: Date, calendar: Calendar = .current) async throws -> [SessionEntity] {
        guard let number = currentMeetingNumber() else {
            return []
        }
        var predicates: [NSPredicate] = []
        if favoritesOnly {
            predicates.append(SessionPredicate.make(meetingNumber: number, filterMode: .favorites))
        }
        switch timeframe {
        case .now:
            predicates.append(SessionPredicate.make(meetingNumber: number, filterMode: .now, now: date))
        case .next:
            predicates.append(SessionPredicate.make(meetingNumber: number, filterMode: .none))
            predicates.append(NSPredicate(format: "start > %@", date as NSDate))
        case .today:
            predicates.append(SessionPredicate.make(meetingNumber: number, filterMode: .today, now: date, calendar: calendar))
            predicates.append(NSPredicate(format: "end > %@", date as NSDate))
        }
        let sessions = try await fetchScheduledSessions(
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates),
            limit: timeframe == .next ? 50 : nil
        )
        guard timeframe == .next, let firstStart = sessions.first?.start else {
            return sessions
        }
        return sessions.filter { $0.start == firstStart }
    }

    /// Every scheduled session of a group at the current meeting, in start order.
    func sessions(groupAcronym: String) async throws -> [SessionEntity] {
        guard let number = currentMeetingNumber() else {
            return []
        }
        let schedule = SessionPredicate.make(meetingNumber: number, filterMode: .none)
        let group = NSPredicate(format: "group.acronym = %@", groupAcronym)
        return try await fetchScheduledSessions(
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [schedule, group]),
            limit: nil
        )
    }

    func hasFavoriteGroups() async throws -> Bool {
        try await read { context in
            let request: NSFetchRequest<Group> = Group.fetchRequest()
            request.predicate = NSPredicate(format: "favorite = true")
            return try context.count(for: request) > 0
        }
    }
}
