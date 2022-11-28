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

    private func appear() {
        print("on appear")
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear(perform: appear)
        }
        .onChange(of: scenePhase) { newScenePhase in
              switch newScenePhase {
              case .active:
                print("App is active")
              case .inactive:
                print("App is inactive")
              case .background:
                print("App is in background")
              @unknown default:
                print("Oh - interesting: I received an unexpected new value.")
              }
            }
    }
}
