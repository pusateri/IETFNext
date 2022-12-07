//
//  DetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/7/22.
//

import SwiftUI


struct DetailView: View {
    @State private var showingOptions = false

    @Binding var selectedMeeting: Meeting?
    @Binding var selectedGroup: Group?
    @Binding var selectedSession: Session?
    @Binding var selectedLocation: Location?
    @Binding var loadURL: URL?
    @Binding var title: String
    @Binding var columnVisibility: NavigationSplitViewVisibility

    var body: some View {
        WebView(url: $loadURL)
        .onChange(of: selectedGroup) { newValue in
            if let group = selectedGroup {
                title = group.acronym!
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
            }
            if UIDevice.current.userInterfaceIdiom == .pad  ||
                UIDevice.current.userInterfaceIdiom == .mac {
                ToolbarItem(placement: .navigationBarLeading) {
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
            ToolbarItem {
                Menu {
                    Button(action: {
                    }) {
                        Text("First Presentation")
                    }
                    Button(action: {
                    }) {
                        Text("Second Presentation")
                    }
                }
                label: {
                    Label("Slides", systemImage: "rectangle.on.rectangle.angled")
                }
            }
            ToolbarItem {
                Menu {
                    Button(action: {
                    }) {
                        Text("First Draft")
                    }
                    Button(action: {
                    }) {
                        Text("Second Draft")
                    }
                }
                label: {
                    Label("Documents", systemImage: "doc")
                }
            }
            ToolbarItem {
                Menu {
                    Button(action: {
                        if let session = selectedSession {
                            if let agenda = session.agenda {
                                loadURL = agenda
                            } else {
                                loadURL = URL(string: "about:blank")!
                            }
                        }
                    }) {
                        Label("View Agenda", systemImage: "list.bullet.clipboard")
                    }
                    Button(action: {
                        if let session = selectedSession {
                            if let minutes = session.minutes {
                                loadURL = minutes
                            } else {
                                loadURL = URL(string: "about:blank")!
                            }
                        }
                    }) {
                        Label("View Minutes", systemImage: "clock")
                    }
                    Button(action: {
                        loadURL = URL(string: "about:blank")!
                    }) {
                        Label("View Recording", systemImage: "play")
                    }
                    Button(action: {
                        loadURL = URL(string: "about:blank")!
                    }) {
                        Label("Listen Audio", systemImage: "speaker.wave.3")
                    }
                    Button(action: {
                        if let session = selectedSession {
                            //
                            if let group = session.group?.acronym {
                                loadURL = URL(string: "https://datatracker.ietf.org/doc/charter-ietf-\(group)/")
                            } else {
                                loadURL = URL(string: "about:blank")!
                            }
                        }
                    }) {
                        Label("View Charter", systemImage: "pencil")
                    }
                    Button(action: {
                        if let session = selectedSession {
                            if let group = session.group?.acronym {
                                loadURL = URL(string: "https://mailarchive.ietf.org/arch/browse/\(group)/")
                            } else {
                                loadURL = URL(string: "about:blank")!
                            }
                        }
                    }) {
                        Label("Mailing List Archive", systemImage: "envelope")
                    }
                }
                label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
    }
}
