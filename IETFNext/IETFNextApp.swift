//
//  IETFNextApp.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI

@main
struct IETFNextApp: App {
    @Environment(\.scenePhase) var scenePhase
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .commands {
            SidebarCommands()
        }
    }
}
