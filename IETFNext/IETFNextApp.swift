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
    var jsonLoader: JSONLoader

    init() {
        jsonLoader = JSONLoader(persistenceController.container)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.loader, jsonLoader)
        }
        .commands {
            SidebarCommands()
        }
    }
}
