//
//  SessionPredicate.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import Foundation
import CoreData

/// Builds the fetch predicate and sort order for scheduled sessions, shared by the
/// schedule list and the App Intents so they agree on what "now", "today", and
/// "favorites" mean.
enum SessionPredicate {

    static func make(meetingNumber: String?, searchText: String = "", filterMode: SessionFilterMode, now: Date = Date(), calendar: Calendar = .current) -> NSPredicate {
        var search_criteria = searchText.isEmpty ? "" : "((name contains[cd] %@) OR (group.acronym contains[cd] %@)) AND "
        var args: [CVarArg] = searchText.isEmpty ? [] : [searchText, searchText]

        search_criteria += "(meeting.number = %@) AND (status contains \"sched\")"
        args.append(meetingNumber ?? "0")

        switch(filterMode) {
            case .favorites:
                search_criteria += " AND (group.favorite = true)"
            case .bofs:
                search_criteria += " AND (is_bof = true)"
            case .now:
                search_criteria += " AND (start < %@) AND (end > %@)"
                args.append(now as CVarArg)
                args.append(now as CVarArg)
            case .today:
                let begin = calendar.startOfDay(for: now)
                let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)
                if let end = end {
                    search_criteria += " AND (start > %@) AND (end < %@)"
                    args.append(begin as CVarArg)
                    args.append(end as CVarArg)
                } else {
                        // we should NEVER hit this case but we don't want it to crash unexpectedly
                    search_criteria += " AND (start > %@)"
                    args.append(begin as CVarArg)
                }
            case .none:
                break
            case .area_art:
                search_criteria += " AND (group.area.name = \"art\")"
            case .area_gen:
                search_criteria += " AND (group.area.name = \"gen\")"
            case .area_iab:
                search_criteria += " AND (group.area.name = \"iab\")"
            case .area_ietf:
                search_criteria += " AND (group.area.name = \"ietf\")"
            case .area_int:
                search_criteria += " AND (group.area.name = \"int\")"
            case .area_irtf:
                search_criteria += " AND (group.area.name = \"irtf\")"
            case .area_ops:
                search_criteria += " AND (group.area.name = \"ops\")"
            case .area_rtg:
                search_criteria += " AND (group.area.name = \"rtg\")"
            case .area_sec:
                search_criteria += " AND (group.area.name = \"sec\")"
            case .area_tsv:
                search_criteria += " AND (group.area.name = \"tsv\")"
        }

        return NSPredicate(format: search_criteria, argumentArray: args)
    }

    static var sortDescriptors: [NSSortDescriptor] {
        [
            NSSortDescriptor(keyPath: \Session.start, ascending: true),
            NSSortDescriptor(keyPath: \Session.end, ascending: false),
            NSSortDescriptor(keyPath: \Session.name, ascending: true),
        ]
    }
}
