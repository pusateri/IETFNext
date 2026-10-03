//
//  NavigationRequest.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import Foundation

/// A request to show a specific item, made from outside the view hierarchy (for example,
/// by an App Intent). Each case carries only the item's stable identifier; the views that
/// handle the request fetch the managed object themselves.
enum NavigationRequest: Equatable, Sendable {
    case session(id: Int32)
    case group(acronym: String)
    case rfc(name: String)
    case location(id: Int32)

    /// The sidebar section that displays the requested item.
    var section: SidebarOption {
        switch self {
        case .session:
            return .schedule
        case .group:
            return .groups
        case .rfc:
            return .rfc
        case .location:
            return .locations
        }
    }

    var sessionID: Int32? {
        if case .session(let id) = self { id } else { nil }
    }

    var groupAcronym: String? {
        if case .group(let acronym) = self { acronym } else { nil }
    }

    var rfcName: String? {
        if case .rfc(let name) = self { name } else { nil }
    }

    var locationID: Int32? {
        if case .location(let id) = self { id } else { nil }
    }
}
