//
//  RFCEntityTests.swift
//  IETFNextTests
//
//  Created by Tom Pusateri on 10/2/26.
//

import Testing
@testable import IETFNext

@Suite("RFC numbers")
struct RFCEntityTests {

    @Test("Search text that is an RFC number", arguments: [
        ("9000", 9000),
        ("rfc9000", 9000),
        ("RFC 9000", 9000),
        (" RFC 791 ", 791),
        ("RFC0791", 791),
        ("10000", 10000),
    ])
    func numberFromSearchText(text: String, expected: Int) {
        #expect(RFCEntity.number(fromSearchText: text) == expected)
    }

    @Test("Search text that isn't an RFC number", arguments: ["quic", "rfc", "", "-5", "0", "１２３", "RFC 9000 bis"])
    func notANumber(text: String) {
        #expect(RFCEntity.number(fromSearchText: text) == nil)
    }

    @Test("doc-id round trip", arguments: [
        (1, "RFC0001"),
        (791, "RFC0791"),
        (9000, "RFC9000"),
        (10000, "RFC10000"),
    ])
    func docID(number: Int, name: String) {
        #expect(RFCEntity.name(forNumber: number) == name)
        #expect(RFCEntity.number(fromName: name) == number)
    }

    @Test func nameWithoutPrefix() {
        #expect(RFCEntity.number(fromName: "BCP0014") == nil)
    }
}
