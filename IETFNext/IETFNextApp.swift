//
//  IETFNextApp.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI

@main
struct IETFNextApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
#if os(macOS)
        .windowToolbarStyle(UnifiedCompactWindowToolbarStyle(showsTitle: false))
        //.windowStyle(HiddenTitleBarWindowStyle())
#endif
        .commands {
            SidebarCommands()
        }
    }
}
