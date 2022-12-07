//
//  SessionListFilteredView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/5/22.
//

import SwiftUI
import CoreData

struct SessionListFilteredView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @SectionedFetchRequest<String, Session> var fetchRequest: SectionedFetchResults<String, Session>
    @State var favoritesOnly: Bool = false
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedSession: Session?


    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>) {
        _fetchRequest = SectionedFetchRequest<String, Session>(
            sectionIdentifier: \.day!,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Session.start, ascending: true),
                NSSortDescriptor(keyPath: \Session.end, ascending: false),
            ],
            predicate: NSPredicate(format: "meeting.number = %@", selectedMeeting.wrappedValue?.number ?? "0"),
            animation: .default
        )
        self._selectedMeeting = selectedMeeting
        self._selectedSession = selectedSession
    }

    var body: some View {
        List(fetchRequest, selection: $selectedSession) { section in
            Section(header: Text(section.id)) {
                ForEach(section, id: \.self) { session in
                    SessionListRowView(session: session)
                }
            }
        }
        .listStyle(.inset)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation {
                        favoritesOnly.toggle()
                        updatePredicate()
                    }
                }) {
                    Label("Filter", systemImage: favoritesOnly == true ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .navigationTitle(Text("Schedule"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedMeeting) { newValue in
            if let meeting = newValue {
                fetchRequest.nsPredicate = NSPredicate(format: "meeting.number = %@", meeting.number!)
            }
        }
    }
    func updatePredicate() {
        if let meeting = selectedMeeting {
            if favoritesOnly == false {
                fetchRequest.nsPredicate = NSPredicate(format: "meeting.number = %@", meeting.number!)
            } else {
                fetchRequest.nsPredicate = NSPredicate(format: "meeting.number = %@ AND favorite = %d", meeting.number!, true)
            }
        }
    }
}

