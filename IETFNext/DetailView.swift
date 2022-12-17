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
    @FetchRequest<Document> var charterRequest: FetchedResults<Document>
    @State private var showingDocuments = false
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedSession: Session?
    @Binding var html: String
    @Binding var fileURL: URL?
    @Binding var title: String
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var agendas: [Agenda]

    @State var draftURL: String? = nil
    @ObservedObject var model: DownloadViewModel

    func loadDownloadFile(from:Download) {
        if let mimeType = from.mimeType {
            if mimeType == "application/pdf" {
                if let filename = from.filename {
                    do {
                        let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                                       in: .userDomainMask,
                                                                       appropriateFor: nil,
                                                                       create: false)
                        fileURL = documentsURL.appendingPathComponent(filename)
                    } catch {
                        html = "Error reading pdf file: \(from.filename!)"
                    }
                }
            } else {
                if let contents = contents2Html(from:from) {
                    html = contents
                } else {
                    html = "Error reading \(from.filename!) error: \(String(describing: model.error))"
                }
            }
        }
    }

    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>, html: Binding<String>, fileURL:Binding<URL?>, title: Binding<String>, columnVisibility: Binding<NavigationSplitViewVisibility>, agendas: Binding<[Agenda]>) {

        _presentationRequest = FetchRequest<Presentation>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Presentation.order, ascending: true),
            ],
            // placeholder predicate
            predicate: NSPredicate(format: "session.group.acronym = %@", selectedSession.wrappedValue?.group?.acronym! ?? "0"),
            animation: .default
        )
        _charterRequest = FetchRequest<Document>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Document.time, ascending: false),
            ],
            predicate: NSPredicate(format: "(name contains %@) AND (type contains \"charter\")", selectedSession.wrappedValue?.group?.acronym! ?? "0"),
            animation: .default
        )

        self._selectedMeeting = selectedMeeting
        self._selectedSession = selectedSession
        self._html = html
        self._fileURL = fileURL
        self._title = title
        self._columnVisibility = columnVisibility
        self._agendas = agendas
        self.model = DownloadViewModel()
    }

    var body: some View {
        WebView(html:$html, fileURL:$fileURL)
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
                                columnVisibility = NavigationSplitViewVisibility.doubleColumn

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
                                if let session = selectedSession {
                                    if let group = session.group {
                                        let urlString = "https://www.ietf.org/proceedings/\(meeting.number!)/slides/\(p.name!)-\(p.rev!).pdf"
                                        if let url = URL(string: urlString) {
                                            let download = fetchDownload(context:viewContext, kind:.presentation, url:url)
                                            if let download = download {
                                                loadDownloadFile(from:download)
                                            } else {
                                                Task {
                                                    await model.downloadToFile(context:viewContext, url:url, mtg:meeting.number!, group:group, kind:.presentation)
                                                }
                                            }
                                        }
                                    }
                                }
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
                            if let meeting = selectedMeeting {
                                if let session = selectedSession {
                                    if let group = session.group {
                                        let download = fetchDownload(context:viewContext, kind:.agenda, url:agenda.url)
                                        if let download = download {
                                            loadDownloadFile(from:download)
                                        } else {
                                            Task {
                                                await model.downloadToFile(context:viewContext, url: agenda.url, mtg:meeting.number!, group:group, kind:.agenda)
                                            }
                                        }
                                    }
                                }
                            }
                        }) {
                            Label("\(agenda.desc)", systemImage: "list.bullet.clipboard")
                        }
                    }
                    Button(action: {
                        if let meeting = selectedMeeting {
                            if let session = selectedSession {
                                if let group = session.group {
                                    if let minutes = session.minutes {
                                        let download = fetchDownload(context:viewContext, kind:.minutes, url:minutes)
                                        if let download = download {
                                            loadDownloadFile(from:download)
                                        } else {
                                            Task {
                                                await model.downloadToFile(context:viewContext, url: minutes, mtg:meeting.number!, group:group, kind:.minutes)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }) {
                        Label("View Minutes", systemImage: "clock")
                    }
                    .disabled(selectedSession?.minutes == nil)
                    /*
                    Button(action: {
                    }) {
                        Label("View Recording", systemImage: "play")
                    }
                    Button(action: {
                    }) {
                        Label("Listen Audio", systemImage: "speaker.wave.3")
                    }
                     */
                    Button(action: {
                        if let meeting = selectedMeeting {
                            if let session = selectedSession {
                                if let group = session.group {
                                    if let rev = charterRequest.first?.rev {
                                        let urlString = "https://www.ietf.org/charter/charter-ietf-\(group.acronym!)-\(rev).txt"
                                        if let url = URL(string: urlString) {
                                            let download = fetchDownload(context:viewContext, kind:.charter, url:url)
                                            if let download = download {
                                                loadDownloadFile(from:download)
                                            } else {
                                                Task {
                                                    await model.downloadToFile(context:viewContext, url:url, mtg:meeting.number!, group:group, kind:.charter)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }) {
                        if let rev = charterRequest.first?.rev {
                            Label("View Charter (v\(rev))", systemImage: "pencil")
                        } else {
                            Label("View Charter", systemImage: "pencil")
                        }
                    }
                    .disabled(charterRequest.first == nil)
                    Button(action: {
                        if let session = selectedSession {
                            if let group = session.group?.acronym {
                                let url = URL(string: "https://mailarchive.ietf.org/arch/browse/\(group)/")!
                                UIApplication.shared.open(url)
                            }
                        }
                    }) {
                        Label("Mailing List Archive", systemImage: "envelope")
                    }
                    .disabled(selectedSession?.group == nil)
                }
                label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingDocuments) {
            if let session = selectedSession {
                if let wg = session.group?.acronym {
                    DocumentListView(wg:wg, urlString:$draftURL)
                }
            }
        }
        .onChange(of: selectedMeeting) { newValue in
            html = BLANK
        }
        .onChange(of: selectedSession) { newValue in
            if let session = selectedSession {
                presentationRequest.nsPredicate = NSPredicate(format: "session = %@", session)

                if let agenda = session.agenda {
                    let download = fetchDownload(context:viewContext, kind:.agenda, url:agenda)
                    if let download = download {
                        loadDownloadFile(from:download)
                    } else {
                        html = "onChange: DetailView selectedSession"
                        if let meeting = selectedMeeting {
                            if let group = session.group {
                                Task {
                                    await model.downloadToFile(context:viewContext, url:agenda, mtg:meeting.number!, group:group, kind:.agenda)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: model.download) { newValue in
            print("model.download")
            if let download = model.download {
                loadDownloadFile(from:download)
            }
        }
        .onChange(of: model.error) { newValue in
            if let err = model.error {
                html = err
            }
        }
        .onChange(of:draftURL) { newValue in
            if let draftURL = draftURL {
                if let url = URL(string:draftURL) {
                    let download = fetchDownload(context:viewContext, kind:.draft, url:url)
                    if let download = download {
                        loadDownloadFile(from:download)
                    } else {
                        if let meeting = selectedMeeting {
                            if let session = selectedSession {
                                if let group = session.group {
                                    Task {
                                        await model.downloadToFile(context:viewContext, url:url, mtg:meeting.number!, group:group, kind:.draft)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
