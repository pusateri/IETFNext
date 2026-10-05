//
//  IntentScheduleTests.swift
//  IETFNextTests
//
//  Created by Tom Pusateri on 10/2/26.
//

import Foundation
import Testing
@testable import IETFNext

/// The schedule questions Siri answers: what's on now, next, today, and where a group meets.
///
/// Sample schedule at IETF 126 (Vienna), Thursday 23 July unless noted:
///
/// | id | group | time | notes |
/// |---|---|---|---|
/// | 1 | cbor | 09:30–11:30 | favorite group |
/// | 2 | quic | 09:30–11:30 | |
/// | 3 | tls | 13:00–14:30 | |
/// | 4 | quic | 13:00–14:30 | |
/// | 5 | tls | Fri 09:30–11:00 | |
/// | 6 | quic | 15:00–16:00 | canceled |
/// | 7 | quic | 16:00–17:00 | at IETF 125, not the current meeting |
/// | 8 | none | 16:00–17:00 | no group, so the schedule doesn't show it |
@MainActor
@Suite("Schedule intents")
struct IntentScheduleTests {
    let store: IntentsTestStore
    let calendar = IntentsTestStore.viennaCalendar

    init() throws {
        store = try IntentsTestStore()
        let meeting = store.meeting("126")
        let other = store.meeting("125")
        let cbor = store.group("cbor", favorite: true)
        let quic = store.group("quic")
        let tls = store.group("tls")
        let hall = store.location(10, name: "Grand Park Hall 2", floor: "Mezzanine Level", meeting: meeting)

        store.session(1, group: cbor, start: "2026-07-23 09:30", end: "2026-07-23 11:30", meeting: meeting, location: hall)
        store.session(2, group: quic, start: "2026-07-23 09:30", end: "2026-07-23 11:30", meeting: meeting)
        store.session(3, group: tls, start: "2026-07-23 13:00", end: "2026-07-23 14:30", meeting: meeting)
        store.session(4, group: quic, start: "2026-07-23 13:00", end: "2026-07-23 14:30", meeting: meeting)
        store.session(5, group: tls, start: "2026-07-24 09:30", end: "2026-07-24 11:00", meeting: meeting)
        store.session(6, group: quic, start: "2026-07-23 15:00", end: "2026-07-23 16:00", meeting: meeting, status: "canceled")
        store.session(7, group: quic, start: "2026-07-23 16:00", end: "2026-07-23 17:00", meeting: other)
        store.session(8, group: nil, start: "2026-07-23 16:00", end: "2026-07-23 17:00", meeting: meeting)
        try store.save()
    }

    private func ids(_ timeframe: SessionTimeframe, favoritesOnly: Bool = false, at time: String) async throws -> Set<Int> {
        let sessions = try await store.dataStore.sessions(
            timeframe: timeframe,
            favoritesOnly: favoritesOnly,
            at: IntentsTestStore.vienna(time),
            calendar: calendar
        )
        return Set(sessions.map(\.id))
    }

    @Test func now() async throws {
        #expect(try await ids(.now, at: "2026-07-23 10:00") == [1, 2])
        #expect(try await ids(.now, favoritesOnly: true, at: "2026-07-23 10:00") == [1])
        #expect(try await ids(.now, at: "2026-07-23 12:00") == [])
    }

    @Test("Next is the whole earliest time slot")
    func next() async throws {
        #expect(try await ids(.next, at: "2026-07-23 10:00") == [3, 4])
        // Late Thursday, the next slot is Friday morning; the canceled 15:00 session doesn't count.
        #expect(try await ids(.next, at: "2026-07-23 14:45") == [5])
        #expect(try await ids(.next, at: "2026-07-24 12:00") == [])
    }

    @Test func nextFavoritesOnly() async throws {
        // cbor has no session after 10:00.
        #expect(try await ids(.next, favoritesOnly: true, at: "2026-07-23 10:00") == [])
        #expect(try await ids(.next, favoritesOnly: true, at: "2026-07-23 08:00") == [1])
    }

    @Test("Today includes sessions in progress but not finished ones")
    func today() async throws {
        #expect(try await ids(.today, at: "2026-07-23 10:00") == [1, 2, 3, 4])
        #expect(try await ids(.today, at: "2026-07-23 12:00") == [3, 4])
        #expect(try await ids(.today, at: "2026-07-23 15:00") == [])
    }

    @Test("A group's sessions skip other meetings and canceled sessions")
    func groupSessions() async throws {
        let sessions = try await store.dataStore.sessions(groupAcronym: "quic")
        #expect(sessions.map(\.id) == [2, 4])
    }

    @Test func sessionEntityFields() async throws {
        let session = try #require(try await store.dataStore.sessions(ids: [1]).first)
        #expect(session.groupAcronym == "cbor")
        #expect(session.room == "Grand Park Hall 2")
        #expect(session.floor == "Mezzanine Level")
        #expect(session.place == "Grand Park Hall 2, Mezzanine Level")
        #expect(session.locationID == 10)
        #expect(session.meetingNumber == "126")
        #expect(session.timeZone == IntentsTestStore.viennaTimeZone)
        #expect(session.start == IntentsTestStore.vienna("2026-07-23 09:30"))
    }

    @Test func sessionWithoutRoom() async throws {
        let session = try #require(try await store.dataStore.sessions(ids: [2]).first)
        #expect(session.room == nil)
        #expect(session.place == nil)
        #expect(session.locationID == nil)
    }

    @Test("Lookups by ID drop unknown IDs and sessions the schedule hides")
    func sessionsByID() async throws {
        let sessions = try await store.dataStore.sessions(ids: [1, 8, 999])
        #expect(sessions.map(\.id) == [1])
    }

    @Test func searchMatchesGroupAcronym() async throws {
        let sessions = try await store.dataStore.sessions(matching: "QUI", limit: 10)
        #expect(sessions.map(\.id) == [2, 4])
    }

    @Test func favorites() async throws {
        #expect(try await store.dataStore.hasFavoriteGroups())
    }
}

@MainActor
@Suite("Schedule intents without a meeting or favorites")
struct IntentScheduleEdgeTests {

    @Test func noMeetingSelected() async throws {
        let store = try IntentsTestStore(meetingNumber: nil)
        let meeting = store.meeting("126")
        store.session(1, group: store.group("quic"), start: "2026-07-23 09:30", end: "2026-07-23 11:30", meeting: meeting)
        try store.save()

        let now = IntentsTestStore.vienna("2026-07-23 10:00")
        #expect(try await store.dataStore.sessions(timeframe: .now, favoritesOnly: false, at: now).isEmpty)
        #expect(try await store.dataStore.sessions(groupAcronym: "quic").isEmpty)
        #expect(try await store.dataStore.sessions(matching: "quic", limit: 10).isEmpty)
    }

    @Test func noFavorites() async throws {
        let store = try IntentsTestStore()
        store.group("quic")
        try store.save()
        #expect(try await store.dataStore.hasFavoriteGroups() == false)
    }

    @Test("Use Local Time shows times in the device's time zone")
    func useLocalTime() async throws {
        let store = try IntentsTestStore(useLocalTime: true)
        let meeting = store.meeting("126")
        store.session(1, group: store.group("quic"), start: "2026-07-23 09:30", end: "2026-07-23 11:30", meeting: meeting)
        try store.save()

        let session = try #require(try await store.dataStore.sessions(ids: [1]).first)
        #expect(session.timeZone == .current)
    }
}
