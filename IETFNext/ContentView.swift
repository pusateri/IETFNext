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
    @State private var selectedItem: String? = "schedule"

    var body: some View {
        NavigationSplitView(columnVisibility:
                                $columnVisibility) {
            List(selection: $selectedItem) {
                Section(header: Text("IETF 115")) {
                    NavigationLink(destination: GroupListView()) {
                        HStack {
                            Image(systemName: "person.3")
                                .frame(width: 32, height: 32)
                            Text("Working Groups")
                        }
                    }
                    NavigationLink(destination: ScheduleListView()) {
                        HStack {
                            Image(systemName: "calendar")
                                .frame(width: 32, height: 32)
                            Text("Schedule")
                        }
                    }
                    NavigationLink(destination: LocationListView()) {
                        HStack {
                            Image(systemName: "map")
                                .frame(width: 32, height: 32)
                            Text("Venue & Room Locations")
                        }
                    }
                }
                Section(header: Text("Settings")) {
                    NavigationLink(destination: MeetingListView()) {
                        HStack {
                            Image(systemName: "airplane.departure")
                                .frame(width: 32, height: 32)
                            Text("Change Meeting")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: more) {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            Text("115 - Yokahama")
        } content: {
            Text("3")
        } detail: {
            DetailView(url: "about:")
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
        .task {
            await loadData(meeting:"115", context:viewContext)
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
