//
//  AppNavigator.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import SwiftUI
import Observation

/// Carries navigation requests from App Intents into the view hierarchy.
///
/// A request is handled in two stages because the list views restore their own saved
/// selection when they appear, which would overwrite a selection made at the same time:
/// 1. An intent calls `open(_:)`, which sets `pending`.
/// 2. `ContentView` switches to the right meeting and sidebar section, then calls `route()`,
///    which moves the request to `routed`.
/// 3. The list for that section picks it up with `take(_:)`, after its own restore, and
///    selects the item. `take(_:)` clears the request so it is applied only once.
@MainActor
@Observable
final class AppNavigator {
    // Nonisolated so the SwiftUI environment default below can create it.
    nonisolated static let shared = AppNavigator()

    /// Set by an intent; not yet handled by `ContentView`.
    private(set) var pending: NavigationRequest?

    /// Handled by `ContentView`; waiting for the list in `routed.section` to select it.
    private(set) var routed: NavigationRequest?

    nonisolated init() {}

    func open(_ request: NavigationRequest) {
        pending = request
    }

    /// Moves the pending request to the list stage and returns it.
    func route() -> NavigationRequest? {
        guard let request = pending else {
            return nil
        }
        pending = nil
        routed = request
        return request
    }

    /// Returns and clears the routed request if it is the kind the caller handles,
    /// for example `navigator.take(\.sessionID)`.
    func take<Value>(_ value: KeyPath<NavigationRequest, Value?>) -> Value? {
        guard let request = routed, let result = request[keyPath: value] else {
            return nil
        }
        routed = nil
        return result
    }
}

extension EnvironmentValues {
    /// Navigation requests from App Intents. Defaults to the shared instance so previews
    /// and views don't need it injected.
    @Entry var appNavigator: AppNavigator = .shared
}
