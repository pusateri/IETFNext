//
//  DetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/7/22.
//

import SwiftUI

struct DetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) var sizeClass
    @FetchRequest<Document> var docRequest: FetchedResults<Document>
    @FetchRequest<Presentation> var presentationRequest: FetchedResults<Presentation>
    @State private var showingOptions = false
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedSession: Session?
    @Binding var loadURL: URL?
    @Binding var title: String
    @Binding var columnVisibility: NavigationSplitViewVisibility

    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>, loadURL: Binding<URL?>, title: Binding<String>, columnVisibility: Binding<NavigationSplitViewVisibility>) {

        _docRequest = FetchRequest<Document>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Document.name, ascending: true),
            ],
            // placeholder predicate
            predicate: NSPredicate(format: "group.acronym = %@", selectedSession.wrappedValue?.group?.acronym! ?? "0"),
            animation: .default
        )
        _presentationRequest = FetchRequest<Presentation>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Presentation.order, ascending: true),
            ],
            // placeholder predicate
            predicate: NSPredicate(format: "session.group.acronym = %@", selectedSession.wrappedValue?.group?.acronym! ?? "0"),
            animation: .default
        )
        self._selectedMeeting = selectedMeeting
        self._selectedSession = selectedSession
        self._loadURL = loadURL
        self._title = title
        self._columnVisibility = columnVisibility
    }

    var body: some View {
        WebView(url: $loadURL)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title).bold()
            }
            if sizeClass == .regular {
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
                    ForEach(presentationRequest, id: \.self) { p in
                        Button(action: {
                            if let meeting = selectedMeeting {
                                let urlString = "https://www.ietf.org/proceedings/\(meeting.number!)/slides/\(p.name!)-\(p.rev!).pdf"
                                loadURL = URL(string: urlString)!
                            }
                        }) {
                            Label(p.title!, systemImage: "square.stack")
                        }
                    }
                }
                label: {
                    Label("Slides", systemImage: "rectangle.on.rectangle.angled")
                }
            }
            ToolbarItem {
                Menu {
                    ForEach(docRequest, id: \.self) { d in
                        Button(action: {
                            // htmlized
                            //let urlString = "https://datatracker.ietf.org/doc/html/\(d.name!)-\(d.rev!)"
                            let urlString = "https://www.ietf.org/archive/id/\(d.name!)-\(d.rev!).html"
                            loadURL = URL(string: urlString)!
                        }) {
                            Text(d.title!)
                        }
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
        .onChange(of: selectedMeeting) { newValue in
            loadURL = URL(string: "about:blank")!
        }
        .onChange(of: selectedSession) { newValue in
            if let session = selectedSession {
                presentationRequest.nsPredicate = NSPredicate(format: "session = %@", session)
                if let group = session.group {
                    docRequest.nsPredicate = NSPredicate(format: "group = %@", group)
                }
            }
        }
    }
}
