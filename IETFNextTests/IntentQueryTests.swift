//
//  IntentQueryTests.swift
//  IETFNextTests
//
//  Created by Tom Pusateri on 10/2/26.
//

import Foundation
import Testing
@testable import IETFNext

@MainActor
@Suite("Group queries")
struct GroupQueryTests {
    let store: IntentsTestStore

    init() throws {
        store = try IntentsTestStore()
        let meeting = store.meeting("126")
        let tls = store.group("tls", name: "Transport Layer Security")
        let atls = store.group("atls", name: "Application-Layer TLS")
        let quic = store.group("quic", name: "QUIC", favorite: true)
        store.group("dnsop", name: "Domain Name System Operations", favorite: true)
        store.group("xyz", name: "Not Meeting")
        store.session(1, group: tls, start: "2026-07-23 09:30", end: "2026-07-23 11:30", meeting: meeting)
        store.session(2, group: atls, start: "2026-07-23 13:00", end: "2026-07-23 14:30", meeting: meeting)
        store.session(3, group: quic, start: "2026-07-23 13:00", end: "2026-07-23 14:30", meeting: meeting)
        try store.save()
    }

    @Test("An exact acronym comes first, whatever its case")
    func exactAcronymFirst() async throws {
        for text in ["tls", "TLS", " tls "] {
            let groups = try await store.dataStore.groups(matching: text, limit: 10)
            #expect(groups.first?.id == "tls")
            #expect(Set(groups.map(\.id)) == ["tls", "atls"])
        }
    }

    @Test func matchesName() async throws {
        let groups = try await store.dataStore.groups(matching: "operations", limit: 10)
        #expect(groups.map(\.id) == ["dnsop"])
    }

    @Test func blankSearch() async throws {
        #expect(try await store.dataStore.groups(matching: "  ", limit: 10).isEmpty)
    }

    @Test("Suggestions are favorites, then other groups meeting at the current meeting")
    func suggestions() async throws {
        let groups = try await store.dataStore.suggestedGroups(limit: 10)
        #expect(groups.map(\.id) == ["dnsop", "quic", "atls", "tls"])
    }

    @Test func suggestionsRespectLimit() async throws {
        let groups = try await store.dataStore.suggestedGroups(limit: 3)
        #expect(groups.map(\.id) == ["dnsop", "quic", "atls"])
    }

    @Test func lookupDropsUnknownAcronyms() async throws {
        let groups = try await store.dataStore.groups(acronyms: ["quic", "nope"])
        #expect(groups.map(\.id) == ["quic"])
        #expect(groups.first?.isFavorite == true)
    }
}

@MainActor
@Suite("RFC queries")
struct RFCQueryTests {
    let store: IntentsTestStore

    init() throws {
        store = try IntentsTestStore()
        store.rfc(791, title: "Internet Protocol", published: "1981-09-01 00:00")
        store.rfc(9000, title: "QUIC: A UDP-Based Multiplexed and Secure Transport", published: "2021-05-01 00:00")
        store.rfc(9001, title: "Using TLS to Secure QUIC", published: "2021-05-02 00:00")
        store.rfc(10000, title: "A Future RFC", published: "2026-06-01 00:00")
        try store.save()
    }

    @Test("Numbers match one RFC", arguments: [
        ("RFC 9000", "RFC9000"),
        ("791", "RFC0791"),
        ("rfc10000", "RFC10000"),
    ])
    func matchesNumber(text: String, name: String) async throws {
        let rfcs = try await store.dataStore.rfcs(matching: text, limit: 10)
        #expect(rfcs.map(\.id) == [name])
    }

    @Test func unknownNumber() async throws {
        #expect(try await store.dataStore.rfcs(matching: "1234", limit: 10).isEmpty)
    }

    @Test("Other text matches titles, newest first")
    func matchesTitle() async throws {
        let rfcs = try await store.dataStore.rfcs(matching: "quic", limit: 10)
        #expect(rfcs.map(\.id) == ["RFC9001", "RFC9000"])
    }

    @Test("Recent RFCs sort by date, not by name")
    func recent() async throws {
        let rfcs = try await store.dataStore.recentRFCs(limit: 2)
        #expect(rfcs.map(\.id) == ["RFC10000", "RFC9001"])
        #expect(rfcs.first?.number == 10000)
    }

    @Test func pages() async throws {
        let first = try await store.dataStore.rfcs(offset: 0, limit: 3)
        let second = try await store.dataStore.rfcs(offset: 3, limit: 3)
        #expect(first.count == 3)
        #expect(second.map(\.id) == ["RFC0791"])
    }

    @Test func lookupDropsUnknownNames() async throws {
        let rfcs = try await store.dataStore.rfcs(names: ["RFC0791", "RFC9999"])
        #expect(rfcs.map(\.id) == ["RFC0791"])
    }
}
