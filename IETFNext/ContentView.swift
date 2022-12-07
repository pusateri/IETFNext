//
//  ContentView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI
import CoreData
/*
extension UISplitViewController {
    open override func viewDidLoad() {
        preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary

        // remove sidebar button, make sidebar always appear !
       presentsWithGesture = displayMode != .oneBesideSecondary

    }
}
*/
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var showingMeetings = false
    @State var selectedMeeting: Meeting?
    @State var selectedGroup: Group? = nil
    @State var selectedSession: Session?
    @State var selectedLocation: Location?
    @State var loadURL: URL? = nil
    @State var title: String = ""

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
                    NavigationLink(destination: SessionListFilteredView(selectedMeeting: $selectedMeeting, selectedSession: $selectedSession)) {
                        HStack {
                            Image(systemName: "calendar")
                                .frame(width: 32, height: 32) // constant width left aligns text
                            Text("Schedule")
                        }
                    }
                   /*
                    .onChange(of: selectedSession) { newValue in
                    if let session = newValue {
                    selectedGroup = session.group
                    }
                    }
                    */
                    NavigationLink(destination: GroupListFilteredView(selectedMeeting: $selectedMeeting, selectedGroup: $selectedGroup)) {
                        HStack {
                            Image(systemName: "person.3")
                                .frame(width: 32, height: 32) // constant width left aligns text
                            Text("Working Groups")
                        }
                    }
                    NavigationLink(destination: LocationListView(selectedMeeting: $selectedMeeting, selectedLocation: $selectedLocation)) {
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
            SessionListFilteredView(selectedMeeting: $selectedMeeting, selectedSession: $selectedSession)
        } detail: {
            WebView(url: $loadURL)
            .onChange(of: selectedGroup) { newValue in
                if let group = selectedGroup {
                    title = group.acronym!
                    /*
                    if let session = selectedSession {
                        if session.group != group {
                            loadURL = agendaForGroup(context: viewContext, group:group)
                        }
                    }
                     */
                }
            }
            .onChange(of: selectedSession) { newValue in
                if let session = selectedSession {
                    title = session.group?.acronym ?? ""
                    if let agenda = session.agenda {
                        loadURL = agenda
                    } else {
                        loadURL = URL(string: "about:blank")!
                    }
                }
            }
            .onChange(of: selectedLocation) { newValue in
                if let location = selectedLocation {
                    title = location.name!
                    if let map = location.map {
                        loadURL = map
                    } else {
                        loadURL = URL(string: "about:blank")!
                    }
                }
            }
            //.navigationTitle($title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text($title)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if UIDevice.current.userInterfaceIdiom == .pad  ||
                        UIDevice.current.userInterfaceIdiom == .mac {
                        Button(action: {
                            switch (columnVisibility) {
                                case .detailOnly:
                                    columnVisibility = NavigationSplitViewVisibility.automatic

                                default:
                                    columnVisibility = NavigationSplitViewVisibility.detailOnly
                            }
                        }) {
                            switch (columnVisibility) {
                                case .detailOnly:
                                    Label("Expand", systemImage: "arrow.down.right.and.arrow.up.left")
                                default:
                                    Label("Contract", systemImage: "arrow.up.left.and.arrow.down.right")
                            }
                        }
                    }
                }
            }
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
