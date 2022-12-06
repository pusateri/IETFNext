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
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showingMeetings = false
    @State var selectedMeeting: Meeting?
    @State var selectedGroup: Group? = nil
    @State var selectedSession: Session?
    @State var loadURL: String? = "about:"

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
                    NavigationLink(destination: GroupListFilteredView(selectedMeeting: $selectedMeeting, selectedGroup: $selectedGroup)) {
                        HStack {
                            Image(systemName: "person.3")
                                .frame(width: 32, height: 32) // constant width left aligns text
                            Text("Working Groups")
                        }
                    }
                    if let m = selectedMeeting {
                        NavigationLink(destination: SessionListFilteredView(selectedMeeting: $selectedMeeting, selectedSession: $selectedSession)
                            .environmentObject(m)) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .frame(width: 32, height: 32) // constant width left aligns text
                                    Text("Schedule")
                                }
                            }
                            .onChange(of: selectedSession) { newValue in
                                if let session = newValue {
                                    selectedGroup = session.group
                                }
                            }
                    }
                    NavigationLink(destination: LocationListView()) {
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
            WebView(loadURL: $loadURL)
            .onChange(of: selectedGroup) { newValue in
                print("Group changed to \(selectedGroup?.acronym! ?? "None")")
            }
            .navigationBarTitle(selectedGroup?.acronym ?? "None", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
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

    private func more() {
        withAnimation {

        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
