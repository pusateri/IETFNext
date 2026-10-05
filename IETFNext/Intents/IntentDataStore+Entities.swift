//
//  IntentDataStore+Entities.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import Foundation
import CoreData

// Fetches that turn managed objects into App Intents entities. Each runs on its own
// background context through `read(_:)`.
extension IntentDataStore {

    /// The time zone the app shows a meeting's times in, matching `ContentView`'s formatters.
    static func displayTimeZone(for meeting: Meeting?, useLocalTime: Bool) -> TimeZone {
        if useLocalTime {
            return .current
        }
        if let identifier = meeting?.time_zone, let timeZone = TimeZone(identifier: identifier) {
            return timeZone
        }
        return .current
    }

    // MARK: - Sessions

    func sessions(ids: [SessionEntity.ID]) async throws -> [SessionEntity] {
        guard !ids.isEmpty else {
            return []
        }
        return try await fetchScheduledSessions(
            predicate: NSPredicate(format: "id IN %@", ids),
            limit: nil
        )
    }

    /// Sessions at the current meeting whose name or group acronym contain `text`,
    /// using the same search as the schedule list.
    func sessions(matching text: String, limit: Int) async throws -> [SessionEntity] {
        guard let number = currentMeetingNumber() else {
            return []
        }
        return try await fetchScheduledSessions(
            predicate: SessionPredicate.make(meetingNumber: number, searchText: text, filterMode: .none),
            limit: limit
        )
    }

    /// Sessions at the current meeting that haven't ended by `date`, in start order.
    func upcomingSessions(favoritesOnly: Bool, after date: Date, limit: Int) async throws -> [SessionEntity] {
        guard let number = currentMeetingNumber() else {
            return []
        }
        let schedule = SessionPredicate.make(meetingNumber: number, filterMode: favoritesOnly ? .favorites : .none)
        let notEnded = NSPredicate(format: "end > %@", date as NSDate)
        return try await fetchScheduledSessions(
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [schedule, notEnded]),
            limit: limit
        )
    }

    /// Every scheduled session at a meeting, for Spotlight.
    func allSessions(meetingNumber: String) async throws -> [SessionEntity] {
        try await fetchScheduledSessions(
            predicate: SessionPredicate.make(meetingNumber: meetingNumber, filterMode: .none),
            limit: nil
        )
    }

    func fetchScheduledSessions(predicate: NSPredicate, limit: Int?) async throws -> [SessionEntity] {
        let useLocalTime = defaults.bool(forKey: Self.useLocalTimeKey)
        return try await read { context in
            let request: NSFetchRequest<Session> = Session.fetchRequest()
            request.predicate = predicate
            request.sortDescriptors = SessionPredicate.sortDescriptors
            request.relationshipKeyPathsForPrefetching = ["group", "location", "meeting"]
            if let limit {
                request.fetchLimit = limit
            }
            return try context.fetch(request).compactMap { session in
                SessionEntity(session: session, timeZone: Self.displayTimeZone(for: session.meeting, useLocalTime: useLocalTime))
            }
        }
    }

    // MARK: - Groups

    func groups(acronyms: [GroupEntity.ID]) async throws -> [GroupEntity] {
        guard !acronyms.isEmpty else {
            return []
        }
        return try await fetchGroups(predicate: NSPredicate(format: "acronym IN %@", acronyms), limit: nil)
    }

    /// Groups whose acronym or name contain `text`. An exact acronym match comes first,
    /// since that's what someone saying "QUIC" or "TLS" means.
    func groups(matching text: String, limit: Int) async throws -> [GroupEntity] {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return []
        }
        let exact = try await fetchGroups(predicate: NSPredicate(format: "acronym =[c] %@", text), limit: 1)
        let partial = try await fetchGroups(
            predicate: NSPredicate(format: "(acronym CONTAINS[cd] %@) OR (name CONTAINS[cd] %@)", text, text),
            limit: limit
        )
        let exactIDs = Set(exact.map(\.id))
        return Array((exact + partial.filter { !exactIDs.contains($0.id) }).prefix(limit))
    }

    /// Favorite groups first, then other groups with sessions at the current meeting.
    func suggestedGroups(limit: Int) async throws -> [GroupEntity] {
        let favorites = try await fetchGroups(predicate: NSPredicate(format: "favorite = true"), limit: limit)
        guard favorites.count < limit, let number = currentMeetingNumber() else {
            return favorites
        }
        let meeting = try await fetchGroups(
            predicate: NSPredicate(format: "(favorite = false) AND (ANY sessions.meeting.number = %@)", number),
            limit: limit - favorites.count
        )
        return favorites + meeting
    }

    /// Every group, for Spotlight.
    func allGroups() async throws -> [GroupEntity] {
        try await fetchGroups(predicate: nil, limit: nil)
    }

    private func fetchGroups(predicate: NSPredicate?, limit: Int?) async throws -> [GroupEntity] {
        try await read { context in
            let request: NSFetchRequest<Group> = Group.fetchRequest()
            request.predicate = predicate
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Group.acronym, ascending: true)]
            request.relationshipKeyPathsForPrefetching = ["area"]
            if let limit {
                request.fetchLimit = limit
            }
            return try context.fetch(request).compactMap(GroupEntity.init(group:))
        }
    }

    // MARK: - RFCs

    func rfcs(names: [RFCEntity.ID]) async throws -> [RFCEntity] {
        guard !names.isEmpty else {
            return []
        }
        return try await fetchRFCs(predicate: NSPredicate(format: "name IN %@", names), limit: nil, offset: 0)
    }

    /// An RFC number ("9000", "rfc9000", "RFC 9000") matches that RFC; other text matches titles.
    func rfcs(matching text: String, limit: Int) async throws -> [RFCEntity] {
        if let number = RFCEntity.number(fromSearchText: text) {
            return try await fetchRFCs(
                predicate: NSPredicate(format: "name = %@", RFCEntity.name(forNumber: number)),
                limit: 1,
                offset: 0
            )
        }
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return []
        }
        return try await fetchRFCs(predicate: NSPredicate(format: "title CONTAINS[cd] %@", text), limit: limit, offset: 0)
    }

    func recentRFCs(limit: Int) async throws -> [RFCEntity] {
        try await fetchRFCs(predicate: nil, limit: limit, offset: 0)
    }

    /// One page of all RFCs, newest first, for Spotlight.
    func rfcs(offset: Int, limit: Int) async throws -> [RFCEntity] {
        try await fetchRFCs(predicate: nil, limit: limit, offset: offset)
    }

    private func fetchRFCs(predicate: NSPredicate?, limit: Int?, offset: Int) async throws -> [RFCEntity] {
        try await read { context in
            let request: NSFetchRequest<RFC> = RFC.fetchRequest()
            request.predicate = predicate
            // Sort by date: names don't sort numerically ("RFC10000" < "RFC9999").
            request.sortDescriptors = [NSSortDescriptor(keyPath: \RFC.published, ascending: false)]
            request.fetchOffset = offset
            if let limit {
                request.fetchLimit = limit
            }
            return try context.fetch(request).compactMap(RFCEntity.init(rfc:))
        }
    }
}
