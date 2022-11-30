//
//  ScheduleListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI
import CoreData

struct ScheduleListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @SectionedFetchRequest(
        sectionIdentifier: \.day!, sortDescriptors: [
            NSSortDescriptor(keyPath: \Session.start, ascending: true),
            NSSortDescriptor(keyPath: \Session.end, ascending: false),
        ],
        predicate: NSPredicate(format: "meeting.number = %@", "115"),
        animation: .default)
    private var sessions: SectionedFetchResults<String, Session>

    @State var selected: Session.ID?

    var body: some View {
        List(sessions, selection: $selected) { section in
            Section(header: Text(section.id)) {
                ForEach(section) { session in
                    ScheduleListRowView(session: session)
                }
            }
        }
    }
}

struct ScheduleListView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleListView(selected: 1)
    }
}
