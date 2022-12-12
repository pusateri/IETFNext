//
//  ContentView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI
import CoreData

extension Bundle {
    var releaseVersionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
    var buildVersionNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
}

public struct Agenda: Identifiable, Hashable {
    public let id: Int32
    public let desc: String
    public let url: URL
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingMeetings = false
    @State var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State var selectedMeeting: Meeting?
    @State var selectedGroup: Group? = nil
    @State var selectedSession: Session?
    @State var selectedLocation: Location?
    @State var loadURL: URL? = nil
    @State var html: String = ""
    @State var title: String = ""
    @State var scheduleFavorites: Bool = false
    @State var groupFavorites: Bool = false
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
                    NavigationLink(destination: SessionListFilteredView(selectedMeeting: $selectedMeeting, selectedSession: $selectedSession, loadURL: $loadURL, title: $title, scheduleFavorites: $scheduleFavorites, agendas: $agendas)) {
                        HStack {
                            Image(systemName: "calendar")
                                .frame(width: 32, height: 32) // constant width left aligns text
                            Text("Schedule")
                        }
                    }
                    NavigationLink(destination: GroupListFilteredView(selectedMeeting: $selectedMeeting, selectedGroup: $selectedGroup, selectedSession: $selectedSession, loadURL: $loadURL, title: $title, groupFavorites: $groupFavorites)) {
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
                        Label("Version \(Bundle.main.releaseVersionNumber).\(Bundle.main.buildVersionNumber) (\(Git.kRevisionNumber))", systemImage: "v.circle")
                    }
                    label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        } content: {
            SessionListFilteredView(selectedMeeting: $selectedMeeting, selectedSession: $selectedSession, loadURL: $loadURL, title: $title, scheduleFavorites: $scheduleFavorites, agendas: $agendas)
        } detail: {
            DetailView(
                selectedMeeting:$selectedMeeting,
                selectedSession:$selectedSession,
                loadURL:$loadURL,
                html:$html,
                title:$title,
                columnVisibility:$columnVisibility,
                agendas: $agendas)
        }
        .sheet(isPresented: $showingMeetings) {
            MeetingListView(selectedMeeting: $selectedMeeting)
        }
        .onAppear {
            if let number = UserDefaults.standard.string(forKey:"MeetingNumber") {
                viewContext.performAndWait {
                    selectedMeeting = selectMeeting(context: viewContext, number: number)
                }
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
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
