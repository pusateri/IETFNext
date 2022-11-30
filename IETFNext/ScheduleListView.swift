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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.start, ascending: true)],
        predicate: NSPredicate(format: "meeting.number = %@", "115"),
        animation: .default)
    private var sessions: FetchedResults<Session>

    @State var selected: Session.ID?

    var body: some View {
        List(sessions, selection: $selected) { session in
            ScheduleListRowView(session: session)
        }
    }
}

struct ScheduleListView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleListView(selected: 1)
    }
}
