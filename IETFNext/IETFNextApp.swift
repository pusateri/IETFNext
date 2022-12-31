//
//  IETFNextApp.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI

@main
struct IETFNextApp: App {
    @State private var showingMeetings = false
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(showingMeetings: $showingMeetings)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
#if os(macOS)
        .windowToolbarStyle(UnifiedCompactWindowToolbarStyle(showsTitle: false))
        //.windowStyle(HiddenTitleBarWindowStyle())
#endif
        .commands {
            SidebarCommands()
#if os(macOS)
            CommandGroup(replacing: .appInfo) {
                Button("About IETF Next") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "git: \(Git.kRevisionNumber)",
                                attributes: [
                                    NSAttributedString.Key.font: NSFont.boldSystemFont(
                                        ofSize: NSFont.smallSystemFontSize)
                                ]
                            ),
                            NSApplication.AboutPanelOptionKey(
                                rawValue: "Copyright"
                            ): "© 2022, Thomas Pusateri"
                        ]
                    )
                }
            }
            CommandGroup(replacing: .newItem) {
            }
            CommandGroup(replacing: .help) {
            }
            CommandMenu("Meeting") {
                Button(action: {
                    showingMeetings.toggle()
                }) {
                    Image(systemName: "airplane.departure")
                    Text("Change Meeting Location")
                }
                .keyboardShortcut("l")
            }
            CommandMenu("Go") {
                Button(action: {
                    print("schedule")
                    //showingMeetings.toggle()
                }) {
                    Image(systemName: "calendar")
                    Text("Schedule")
                }
                .keyboardShortcut("s")
                Button(action: {
                    print("Working Groups")
                    //showingMeetings.toggle()
                }) {
                    Image(systemName: "person.3")
                    Text("Working Groups")
                }
                .keyboardShortcut("g")
                Button(action: {
                    print("Venue & Room Locations")
                    //showingMeetings.toggle()
                }) {
                    Image(systemName: "map")
                    Text("Venue & Room Locations")
                }
                .keyboardShortcut("r")
            }
#endif
        }
    }
}
