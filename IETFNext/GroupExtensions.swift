//
//  GroupExtensions.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/12/22.
//

import Foundation
import CoreData


enum FavoriteMode: String {
    case all
    case none
    case some
    case unknown
}

extension Group {
    func groupSessions(meeting: Meeting) -> [Session]? {
        let predicate = NSPredicate(format: "meeting.number = %@", meeting.number!)
        return Array(sessions!.filtered(using: predicate)) as? [Session]
    }
    func favoriteSymbolMode(meeting: Meeting?) -> FavoriteMode {
        if let meeting = meeting {
            let sessions = self.groupSessions(meeting: meeting)
            if let sessions = sessions {
                if sessions.map({ $0.favorite }).reduce(true, { $0 && $1 }) {
                    return .all
                }
                if sessions.map({ $0.favorite }).reduce(false, { $0 || $1 }) == false {
                    return .none
                }
                return .some
            }
        }
        return .unknown
    }
    func favoriteSymbol(mode: FavoriteMode) -> String {
        switch(mode) {
        case .all:
            return "star.fill"
        case .none:
            return "star"
        case .some:
            return "star.leadinghalf.filled"
        case .unknown:
            return "questionmark"
        }
    }
    func updateFavoriteSymbolMode(meeting: Meeting?) {
        if let meeting = meeting {
            let sessions = self.groupSessions(meeting: meeting)
            if let sessions = sessions {

                switch(self.favoriteSymbolMode(meeting: meeting)) {
                case .all:
                    for session in sessions {
                        session.favorite = false
                    }
                case .none, .some:
                    for session in sessions {
                        session.favorite = true
                    }
                case .unknown:
                    return
                }
            }
        }
    }
}
