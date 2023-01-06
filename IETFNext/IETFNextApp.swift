//
//  IETFNextApp.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI

public enum SidebarOption: String {
    case download
    case groups
    case locations
    case rfc
    case schedule
}

@main
struct IETFNextApp: App {
    @State private var showingMeetings = false
    @State var menuSidebarOption: SidebarOption? = nil
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(showingMeetings: $showingMeetings, menuSidebarOption: $menuSidebarOption)
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
                    Text("Change Meeting")
                }
                .keyboardShortcut("a")
            }
            CommandMenu("Go") {
                Button(action: {
                    menuSidebarOption = .schedule
                }) {
                    Image(systemName: "calendar")
                    Text("Schedule")
                }
                .keyboardShortcut("s")
                Button(action: {
                    menuSidebarOption = .groups
                }) {
                    Image(systemName: "person.3")
                    Text("Working Groups")
                }
                .keyboardShortcut("g")
                Button(action: {
                    menuSidebarOption = .locations
                }) {
                    Image(systemName: "map")
                    Text("Venue & Room Locations")
                }
                .keyboardShortcut("l")
                Button(action: {
                    menuSidebarOption = .rfc
                }) {
                    Image(systemName: "doc.plaintext")
                    Text("RFCs")
                }
                .keyboardShortcut("r")
                Button(action: {
                    menuSidebarOption = .download
                }) {
                    Image(systemName: "arrow.down.circle")
                    Text("Downloads")
                }
                .keyboardShortcut("d")
            }
#endif
        }
    }
}
