//
//  ContentView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI
import CoreData

public struct Agenda: Identifiable, Hashable {
    public let id: Int32
    public let desc: String
    public let url: URL
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingMeetings = false

    @State var columnVisibility = NavigationSplitViewVisibility.automatic
    @State var selectedMeeting: Meeting?
    @State var selectedGroup: Group? = nil
    @State var selectedSession: Session?
    @State var selectedLocation: Location?
    @State var loadURL: URL? = nil
    @State var title: String = ""
    @State var favoritesOnly: Bool = false
    @State var agendas: [Agenda] = []

    @ViewBuilder
    var first_header: some View {
        if let m = selectedMeeting {
            Text("IETF \(m.number!) \(m.city!)")
        } else {
            Text("IETF")
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List() {
                Section(header: first_header) {
                    NavigationLink(destination: SessionListFilteredView(selectedMeeting: $selectedMeeting, selectedSession: $selectedSession, loadURL: $loadURL, title: $title, favoritesOnly: $favoritesOnly, agendas: $agendas)) {
                        HStack {
                            Image(systemName: "calendar")
                                .frame(width: 32, height: 32) // constant width left aligns text
                            Text("Schedule")
                        }
                    }
                    NavigationLink(destination: GroupListFilteredView(selectedMeeting: $selectedMeeting, selectedGroup: $selectedGroup, selectedSession: $selectedSession, loadURL: $loadURL, title: $title)) {
                        HStack {
                            Image(systemName: "person.3")
                                .frame(width: 32, height: 32) // constant width left aligns text
                            Text("Working Groups")
                        }
                    }
                    NavigationLink(destination: LocationListView(selectedMeeting: $selectedMeeting, selectedLocation: $selectedLocation, loadURL: $loadURL, title: $title)) {
                        HStack {
                            Image(systemName: "map")
                                .frame(width: 32, height: 32) // constant width left aligns text
                            Text("Venue & Room Locations")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button(action: {
                            showingMeetings.toggle()
                        }) {
                            Label("Change Meeting", systemImage: "airplane.departure")
                        }
                        Label("Version 1.1", systemImage: "v.circle")
                    }
                    label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        } content: {
            SessionListFilteredView(selectedMeeting: $selectedMeeting, selectedSession: $selectedSession, loadURL: $loadURL, title: $title, favoritesOnly: $favoritesOnly, agendas: $agendas)
        } detail: {
            DetailView(
                selectedMeeting:$selectedMeeting,
                selectedSession:$selectedSession,
                loadURL:$loadURL,
                title:$title,
                columnVisibility:$columnVisibility,
                agendas: $agendas)
        }
        .sheet(isPresented: $showingMeetings) {
            MeetingListView(selectedMeeting: $selectedMeeting)
        }
        .onAppear {
            if let number = UserDefaults.standard.string(forKey:"MeetingNumber") {
                selectedMeeting = selectMeeting(context: viewContext, number: number)
                if let meeting = selectedMeeting {
                    Task {
                        await loadData(meeting:meeting, context:viewContext)
                    }
                }
            } else {
                showingMeetings.toggle()
            }
        }
    }

    private func agendaForGroup(context: NSManagedObjectContext, group: Group) -> URL {
        if let url = URL(string: "https://datatracker.ietf.org/meeting/114/materials/agenda-114-emailcore-01") {
            return url
        } else {
            return URL(string: "about:")!
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
