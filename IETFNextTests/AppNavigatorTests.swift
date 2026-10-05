//
//  AppNavigatorTests.swift
//  IETFNextTests
//
//  Created by Tom Pusateri on 10/2/26.
//

import Testing
@testable import IETFNext

@MainActor
@Suite("App navigator")
struct AppNavigatorTests {

    @Test func requestMovesThroughBothStages() {
        let navigator = AppNavigator()
        navigator.open(.session(id: 33_001))
        #expect(navigator.pending == .session(id: 33_001))
        #expect(navigator.routed == nil)

        #expect(navigator.route() == .session(id: 33_001))
        #expect(navigator.pending == nil)
        #expect(navigator.routed == .session(id: 33_001))

        #expect(navigator.take(\.sessionID) == 33_001)
        #expect(navigator.routed == nil)
    }

    @Test func listIgnoresOtherKindsOfRequest() {
        let navigator = AppNavigator()
        navigator.open(.rfc(name: "RFC9000"))
        _ = navigator.route()

        // The schedule list asks for a session; the RFC request must survive for the RFC list.
        #expect(navigator.take(\.sessionID) == nil)
        #expect(navigator.routed == .rfc(name: "RFC9000"))
        #expect(navigator.take(\.rfcName) == "RFC9000")
    }

    @Test func routeWithNothingPending() {
        let navigator = AppNavigator()
        #expect(navigator.route() == nil)
        #expect(navigator.take(\.groupAcronym) == nil)
    }

    @Test("Each request opens the right sidebar section", arguments: [
        (NavigationRequest.session(id: 1), SidebarOption.schedule),
        (.group(acronym: "quic"), .groups),
        (.rfc(name: "RFC9000"), .rfc),
        (.location(id: 1), .locations),
    ])
    func section(request: NavigationRequest, section: SidebarOption) {
        #expect(request.section == section)
    }
}
