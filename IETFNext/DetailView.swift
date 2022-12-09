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
    @FetchRequest<Presentation> var presentationRequest: FetchedResults<Presentation>
    @State private var showingDocuments = false
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedSession: Session?
    @Binding var loadURL: URL?
    @Binding var title: String
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var agendas: [Agenda]

    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>, loadURL: Binding<URL?>, title: Binding<String>, columnVisibility: Binding<NavigationSplitViewVisibility>, agendas: Binding<[Agenda]>) {

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
        self._agendas = agendas
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
                Button(action: {
                    if let _ = selectedSession {
                        showingDocuments.toggle()
                    }
                }) {
                    Label("Documents", systemImage: "doc")
                }
            }
            ToolbarItem {
                Menu {
                    ForEach(agendas) { agenda in
                        Button(action: {
                            loadURL = agenda.url
                        }) {
                            Label("\(agenda.desc)", systemImage: "list.bullet.clipboard")
                        }
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
                    .disabled(selectedSession?.minutes == nil)
                    /*
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
                     */
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
        .sheet(isPresented: $showingDocuments) {
            if let session = selectedSession {
                if let wg = session.group?.acronym {
                    DocumentListView(wg: wg, loadURL:$loadURL)
                }
            }
        }
        .onChange(of: selectedMeeting) { newValue in
            loadURL = URL(string: "about:blank")!
        }
        .onChange(of: selectedSession) { newValue in
            if let session = selectedSession {
                presentationRequest.nsPredicate = NSPredicate(format: "session = %@", session)
            }
        }
    }
}
