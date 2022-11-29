//
//  ContentView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("Working Groups")) {
                    NavigationLink("Groups by Area") {
                        GroupListView()
                    }
                    NavigationLink("Groups Alphabetically") {
                        GroupListView()
                    }
                }
                Section(header: Text("IETF 115")) {
                    NavigationLink("Schedule") {
                        ScheduleListView()
                    }

                    NavigationLink("Floor Maps") {
                        LocationListView()
                    }
                }
                Section(header: Text("Settings")) {
                    NavigationLink("Change Meeting") {
                        MeetingListView()
                    }
                }
            }
            .navigationTitle("IETF")
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
            Text("4")
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
