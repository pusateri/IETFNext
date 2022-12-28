//
//  DetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/7/22.
//

import SwiftUI
import CoreData

struct DetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
#if os(iOS)
    @Environment(\.horizontalSizeClass) var sizeClass
#endif
    @FetchRequest<Presentation> var presentationRequest: FetchedResults<Presentation>
    @FetchRequest<Document> var charterRequest: FetchedResults<Document>
    @State private var showingDocuments = false
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedSession: Session?
    @Binding var sessionsForGroup: [Session]?
    @Binding var html: String
    @Binding var fileURL: URL?
    @Binding var title: String
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var agendas: [Agenda]

    @State var draftURL: String? = nil
    @State var draftTitle: String? = nil
    @State var kind: DocumentKind = .draft
    @ObservedObject var model: DownloadViewModel

    public func fetchDownload(kind:DownloadKind, url:URL) -> Download? {
        var download: Download?

        viewContext.performAndWait {
            let fetch: NSFetchRequest<Download> = Download.fetchRequest()
            fetch.predicate = NSPredicate(format: "basename = %@", url.lastPathComponent)

            let results = try? viewContext.fetch(fetch)

            if results?.count == 0 {
                download = nil
            } else {
                // here you are updating
                download = results?.first
            }
        }
        return download
    }

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

    func recordingSuffix(session: Session) -> String {
        if let sessions = sessionsForGroup {
            if sessions.count != 1 {
                let idx = sessions.firstIndex(of: session)
                if let idx = idx {
                    return String(format: " \(idx + 1)")
                }
            }
        }
        return ""
    }

    private func findSessionsForGroup(meeting: Meeting, group: Group) -> [Session]? {

        let fetchSession: NSFetchRequest<Session> = Session.fetchRequest()
        fetchSession.predicate = NSPredicate(format: "meeting = %@ AND group = %@", meeting, group)
        fetchSession.sortDescriptors = [
            NSSortDescriptor(keyPath: \Session.start, ascending: true)
        ]
        return try? viewContext.fetch(fetchSession)
    }

    // build a list of agenda items, number them only if more than 1
    private func uniqueAgendasForSessions(sessions: [Session]?) -> [Agenda] {
        var agendas: [Agenda] = []
        var seen: Set<String> = []
        var index: Int32 = 1
        for session in sessions ?? [] {
            if let agendaURL = session.agenda {
                seen.insert(agendaURL.absoluteString)
            }
        }
        let numbered = seen.count > 1
        seen = []
        for session in sessions ?? [] {
            if let agendaURL = session.agenda {
                if !seen.contains(agendaURL.absoluteString) {
                    seen.insert(agendaURL.absoluteString)
                    var desc: String = "View Agenda"
                    if numbered {
                        desc = "View Agenda \(index)"
                    }
                    agendas.append(Agenda(id:index, desc:desc, url:agendaURL))
                    index += 1
                }
            }
        }
        return agendas
    }

    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>, sessionsForGroup: Binding<[Session]?>, html: Binding<String>, fileURL:Binding<URL?>, title: Binding<String>, columnVisibility: Binding<NavigationSplitViewVisibility>, agendas: Binding<[Agenda]>) {

        _presentationRequest = FetchRequest<Presentation>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Presentation.order, ascending: true),
            ],
            // placeholder predicate
            predicate: NSPredicate(format: "(session.meeting.number = %@) AND (session.group.acronym = %@)", selectedSession.wrappedValue?.meeting?.number ?? "0", selectedSession.wrappedValue?.group?.acronym! ?? "0"),
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
        self._sessionsForGroup = sessionsForGroup
        self._html = html
        self._fileURL = fileURL
        self._title = title
        self._columnVisibility = columnVisibility
        self._agendas = agendas
        self.model = DownloadViewModel.shared
    }

    var body: some View {
        WebView(html:$html, fileURL:$fileURL)
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title).bold()
            }
#if !os(macOS)
            if sizeClass == .regular {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        switch (columnVisibility) {
                            case .detailOnly:
                                columnVisibility = .doubleColumn

                            default:
                                columnVisibility = .detailOnly
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
#endif
            ToolbarItem {
                Menu {
                    ForEach(presentationRequest, id: \.self) { p in
                        Button(action: {
                            if let meeting = selectedMeeting {
                                if let session = selectedSession {
                                    if let group = session.group {
                                        let urlString = "https://www.ietf.org/proceedings/\(meeting.number!)/slides/\(p.name!)-\(p.rev!).pdf"
                                        if let url = URL(string: urlString) {
                                            let download = fetchDownload(kind:.presentation, url:url)
                                            if let download = download {
                                                loadDownloadFile(from:download)
                                            } else {
                                                Task {
                                                    await model.downloadToFile(context:viewContext, url:url, mtg:meeting.number!, group:group, kind:.presentation, title: p.title)
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
                if let _ = selectedSession {
                    Menu {
                        ForEach(agendas) { agenda in
                            Button(action: {
                                if let meeting = selectedMeeting {
                                    if let session = selectedSession {
                                        if let group = session.group {
                                            let download = fetchDownload(kind:.agenda, url:agenda.url)
                                            if let download = download {
                                                loadDownloadFile(from:download)
                                            } else {
                                                Task {
                                                    await model.downloadToFile(context:viewContext, url: agenda.url, mtg:meeting.number!, group:group, kind:.agenda, title: "IETF \(meeting.number!) (\(meeting.city!)) \(group.acronym!.uppercased())")
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
                                            let download = fetchDownload(kind:.minutes, url:minutes)
                                            if let download = download {
                                                loadDownloadFile(from:download)
                                            } else {
                                                Task {
                                                    await model.downloadToFile(context:viewContext, url: minutes, mtg:meeting.number!, group:group, kind:.minutes, title: "IETF \(meeting.number!) (\(meeting.city!)) \(group.acronym!.uppercased())")
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
                        ForEach(sessionsForGroup ?? []) { session in
                            Button(action: {
                                if let url = session.recording {
#if os(macOS)
                                    if NSWorkspace.shared.canOpenURL(url) {
                                        NSWorkspace.shared.open(url)
                                    } else{
                                        if let youtubeID = url.host {
                                            if let youtube = URL(string: "https://www.youtube.com/embed/\(youtubeID)") {
                                                UIApplication.shared.open(youtube)
                                            }
                                        }
                                    }
#else
                                    if UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url)
                                    } else {
                                        if let youtubeID = url.host {
                                            if let youtube = URL(string: "https://www.youtube.com/embed/\(youtubeID)") {
                                                UIApplication.shared.open(youtube)
                                            }
                                        }
                                    }
#endif
                                }
                            }) {
                                Label("View Recording\(recordingSuffix(session:session))", systemImage: "play")
                            }
                            .disabled(session.recording == nil)
                        }
                        Button(action: {
                            if let meeting = selectedMeeting {
                                if let session = selectedSession {
                                    if let group = session.group {
                                        if let rev = charterRequest.first?.rev {
                                            let urlString = "https://www.ietf.org/charter/charter-ietf-\(group.acronym!)-\(rev).txt"
                                            if let url = URL(string: urlString) {
                                                let download = fetchDownload(kind:.charter, url:url)
                                                if let download = download {
                                                    loadDownloadFile(from:download)
                                                } else {
                                                    Task {
                                                        await model.downloadToFile(context:viewContext, url:url, mtg:meeting.number!, group:group, kind:.charter, title: "\(group.acronym!.uppercased()) Charter")
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
#if os(macOS)
                                    NSWorkspace.shared.open(url)
#else
                                    UIApplication.shared.open(url)
#endif
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
        }
        .sheet(isPresented: $showingDocuments) {
            if let session = selectedSession {
                if let wg = session.group?.acronym {
                    DocumentListView(wg:wg, urlString:$draftURL, titleString:$draftTitle, kind:$kind)
                }
            }
        }
        .onChange(of: selectedMeeting) { newValue in
            html = BLANK
        }
        .onChange(of: selectedSession) { newValue in
            html = BLANK
            if let meeting = selectedMeeting {
                if let session = selectedSession {
                    presentationRequest.nsPredicate = NSPredicate(format: "session = %@", session)
                    if let group = session.group {

                        // find all agendas for all sessions in the same group
                        viewContext.performAndWait {
                            sessionsForGroup = findSessionsForGroup(meeting:meeting, group:group)
                            agendas = uniqueAgendasForSessions(sessions: sessionsForGroup)
                        }

                        if let wg = group.acronym {
                            // update the title and load the corresponding documents
                            title = wg
                        }
                        if let agenda = session.agenda {
                            let download = fetchDownload(kind:.agenda, url:agenda)
                            if let download = download {
                                loadDownloadFile(from:download)
                            } else {
                                Task {
                                    await model.downloadToFile(context:viewContext, url:agenda, mtg:meeting.number!, group:group, kind:.agenda, title: "IETF \(meeting.number!) (\(meeting.city!)) \(group.acronym!.uppercased())")
                                }
                            }
                        }
                        Task {
                            await loadDrafts(context: viewContext, group: group, limit:0, offset:0)
                            await loadCharterDocument(context: viewContext, group: group)
                            await loadRelatedDrafts(context: viewContext, group: group, limit:0, offset:0)
                        }
                    }
                    // if we don't have a recording URL, go get one. We don't expect it to change once we have it
                    if session.recording == nil {
                        Task {
                            await loadRecordingDocument(context: viewContext, session: session)
                        }
                    }
                } else {
                    title = ""
                }
            }
        }
        .onChange(of: model.download) { newValue in
            if let download = model.download {
                loadDownloadFile(from:download)
            }
        }
        .onChange(of: model.error) { newValue in
            if let err = model.error {
                html = PLAIN_PRE + err + PLAIN_POST
            }
        }
        .onChange(of:draftURL) { newValue in
            if let draftURL = draftURL {
                if let url = URL(string:draftURL) {
                    let download = fetchDownload(kind:.draft, url:url)
                    if let download = download {
                        loadDownloadFile(from:download)
                    } else {
                        if let meeting = selectedMeeting {
                            if let session = selectedSession {
                                if let group = session.group {
                                    Task {
                                        await model.downloadToFile(context:viewContext, url:url, mtg:meeting.number!, group:group, kind:.draft, title:draftTitle)
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
