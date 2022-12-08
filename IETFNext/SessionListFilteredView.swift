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
    @Binding var loadURL: URL?
    @Binding var title: String


    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>, loadURL: Binding<URL?>, title: Binding<String>) {
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
        self._loadURL = loadURL
        self._title = title
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Schedule")
                        .font(.headline)
                    Text("\(favoritesOnly ? "Filter: Favorites" : "")")
                        .font(.footnote)
                        .foregroundColor(Color.blue)
                }
            }
            ToolbarItem(placement: .bottomBar) {
                if let meeting = selectedMeeting {
                    if let number = meeting.number {
                        if let city = meeting.city {
                            Text("IETF \(number) (\(city))")
                                .font(.subheadline)
                                .foregroundColor(Color.blue)
                        }
                    }
                }
            }
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
        .onChange(of: selectedMeeting) { newValue in
            if let meeting = newValue {
                fetchRequest.nsPredicate = NSPredicate(format: "meeting.number = %@", meeting.number!)
            }
        }
        .onChange(of: selectedSession) { newValue in
            if let session = selectedSession {
                if let group = session.group {
                    if let wg = group.acronym {
                        title = wg
                        Task {
                            await loadDrafts(context:viewContext, limit:0, offset:0, group:group)
                        }
                    }
                }
                if let agenda = session.agenda {
                    loadURL = agenda
                } else {
                    loadURL = URL(string: "about:blank")!
                }
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

