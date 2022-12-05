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
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedSession: Session?

    @SectionedFetchRequest(
        sectionIdentifier: \.day!, sortDescriptors: [
            NSSortDescriptor(keyPath: \Session.start, ascending: true),
            NSSortDescriptor(keyPath: \Session.end, ascending: false),
        ],
        //predicate: NSPredicate(format: "meeting.number = %@", selectedMeeting?.number!),
        animation: .default)
    private var sessions: SectionedFetchResults<String, Session>



    var body: some View {
        List(sessions, selection: $selectedSession) { section in
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
        ScheduleListView(selectedMeeting: .constant(nil), selectedSession: .constant(nil))
    }
}
