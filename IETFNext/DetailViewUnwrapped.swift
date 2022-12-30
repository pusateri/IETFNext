//
//  DetailViewUnwrapped.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/29/22.
//

import SwiftUI
import CoreData

struct DetailViewUnwrapped: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.presentationMode) var presentation
    @Environment(\.horizontalSizeClass) var sizeClass

    @FetchRequest<Presentation> var presentationRequest: FetchedResults<Presentation>
    @FetchRequest<Document> var charterRequest: FetchedResults<Document>
    @ObservedObject var meeting: Meeting
    @ObservedObject var session: Session
    @Binding var html: String
    @Binding var localFileURL: URL?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @State var sessionsForGroup: [Session]? = nil
    @State var agendas: [Agenda] = []
    @State var banner: String = "foo"
    @State private var showingDocuments = false
    @State var draftURL: String? = nil
    @State var draftTitle: String? = nil
    @State var kind: DocumentKind = .draft
    @ObservedObject var model: DownloadViewModel = DownloadViewModel.shared

    init(meeting: Meeting, session: Session, html: Binding<String>, localFileURL:Binding<URL?>, columnVisibility: Binding<NavigationSplitViewVisibility>) {

        self.meeting = meeting
        self.session = session

        self._html = html
        self._localFileURL = localFileURL
        self._columnVisibility = columnVisibility

        _presentationRequest = FetchRequest<Presentation>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Presentation.order, ascending: true),
            ],
            predicate: NSPredicate(format: "(session.meeting.number = %@) AND (session.group.acronym = %@)", meeting.number!, session.group?.acronym ?? ""),
            animation: .default
        )
        _charterRequest = FetchRequest<Document>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Document.time, ascending: false),
            ],
            predicate: NSPredicate(format: "(name contains %@) AND (type contains \"charter\")", session.group?.acronym ?? ""),
            animation: .default
        )
    }

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
                        html = ""
                        localFileURL = documentsURL.appendingPathComponent(filename)
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

    private func saveFavorite(session: Session) {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Unable to save Session favorite \(session.name!)")
            }
        }
    }

    private func updateFor(session: Session) {
        if let group = session.group {
            banner = group.acronym!
            sessionsForGroup = findSessionsForGroup(meeting:meeting, group:group)
            agendas = uniqueAgendasForSessions(sessions: sessionsForGroup)
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
            // if we don't have a recording URL, go get one. We don't expect it to change once we have it
            if let allSessions = sessionsForGroup {
                for s in allSessions {
                    if s.recording == nil {
                        Task {
                            await loadRecordingDocument(context: viewContext, session: s)
                        }
                    }
                }
            }
        }
    }

    var body: some View {
        WebView(html:$html, localFileURL:$localFileURL)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(banner).bold()
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
                Button(action: {
                    session.favorite.toggle()
                    saveFavorite(session: session)
                }) {
                    Image(systemName: session.favorite == true ? "star.fill" : "star")
                        .foregroundColor(Color(hex: areaColors[session.group?.areaKey ?? "ietf"] ?? 0xf6c844))
#if os(macOS)
                        .overlay {
                            Image(systemName: "star")
                                .imageScale(.large)
                                .foregroundColor(.black)
                        }
#endif
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            ToolbarItem {
                Menu {
                    ForEach(presentationRequest, id: \.self) { p in
                        Button(action: {
                            let urlString = "https://www.ietf.org/proceedings/\(meeting.number!)/slides/\(p.name!)-\(p.rev!).pdf"
                            if let url = URL(string: urlString) {
                                let download = fetchDownload(kind:.presentation, url:url)
                                if let download = download {
                                    loadDownloadFile(from:download)
                                } else {
                                    if let group = session.group {
                                        Task {
                                            await model.downloadToFile(context:viewContext, url:url, mtg:meeting.number!, group:group, kind:.presentation, title: p.title)
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
                    showingDocuments.toggle()
                }) {
                    Label("Documents", systemImage: "doc")
                }
            }
            ToolbarItem {
                    Menu {
                        ForEach(agendas) { agenda in
                            Button(action: {
                                let download = fetchDownload(kind:.agenda, url:agenda.url)
                                if let download = download {
                                    loadDownloadFile(from:download)
                                } else {
                                    if let group = session.group {
                                        Task {
                                            await model.downloadToFile(context:viewContext, url: agenda.url, mtg:meeting.number!, group:group, kind:.agenda, title: "IETF \(meeting.number!) (\(meeting.city!)) \(group.acronym!.uppercased())")
                                        }
                                    }
                                }
                            }) {
                                Label("\(agenda.desc)", systemImage: "list.bullet.clipboard")
                            }
                        }
                        Button(action: {
                            if let minutes = session.minutes {
                                let download = fetchDownload(kind:.minutes, url:minutes)
                                if let download = download {
                                    loadDownloadFile(from:download)
                                } else {
                                    if let group = session.group {
                                        Task {
                                            await model.downloadToFile(context:viewContext, url: minutes, mtg:meeting.number!, group:group, kind:.minutes, title: "IETF \(meeting.number!) (\(meeting.city!)) \(group.acronym!.uppercased())")
                                        }
                                    }
                                }
                            }
                        }) {
                            Label("View Minutes", systemImage: "clock")
                        }
                        .disabled(session.minutes == nil)
                        ForEach(sessionsForGroup ?? []) { session in
                            Button(action: {
                                if let url = session.recording {
#if os(macOS)
                                    if let youtubeID = url.host {
                                        if let youtube = URL(string: "https://www.youtube.com/embed/\(youtubeID)") {
                                            NSWorkspace.shared.open(youtube)
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
                            if let rev = charterRequest.first?.rev {
                                if let group = session.group {
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
                        }) {
                            if let rev = charterRequest.first?.rev {
                                Label("View Charter (v\(rev))", systemImage: "pencil")
                            } else {
                                Label("View Charter", systemImage: "pencil")
                            }
                        }
                        .disabled(charterRequest.first == nil)
                        Button(action: {
                            if let group = session.group {
                                var url: URL? = nil
                                // rewrite acronym for some working groups mailing lists
                                if group.acronym! == "httpbis" {
                                    url = URL(string: "https://lists.w3.org/Archives/Public/ietf-http-wg/")
                                } else if group.acronym! == "6man" {
                                    url = URL(string: "https://mailarchive.ietf.org/arch/browse/ipv6/")
                                } else {
                                    url = URL(string: "https://mailarchive.ietf.org/arch/browse/\(group.acronym!)/")
                                }
                                if let url = url {
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
                    }
                    label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
        }
        .sheet(isPresented: $showingDocuments) {
            if let group = session.group {
                DocumentListView(wg:group.acronym!, urlString:$draftURL, titleString:$draftTitle, kind:$kind)
            }
        }
        .onChange(of: meeting) { newValue in
            html = BLANK
        }
        .onChange(of: session) { newValue in
            presentationRequest.nsPredicate = NSPredicate(format: "session = %@", newValue)
            updateFor(session: newValue)
        }
        .onChange(of: model.download) { newValue in
            if let download = model.download {
                loadDownloadFile(from:download)
            }
        }
        .onChange(of: model.error) { newValue in
            if let err = model.error {
                if err.starts(with: "Http Result 404:") {
                    if let urlString = draftURL as? NSString {
                        if urlString.pathExtension == "html" {
                            draftURL = urlString.replacingOccurrences(of: ".html", with: ".txt")
                        }
                    }
                } else {
                    html = PLAIN_PRE + err + PLAIN_POST
                }
            }
        }
        .onChange(of:draftURL) { newValue in
            if let draftURL = draftURL {
                if let url = URL(string:draftURL) {
                    let download = fetchDownload(kind:.draft, url:url)
                    if let download = download {
                        loadDownloadFile(from:download)
                    } else {
                        if let group = session.group {
                            Task {
                                await model.downloadToFile(context:viewContext, url:url, mtg:meeting.number!, group:group, kind:.draft, title:draftTitle)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                updateFor(session: session)
            }
        }
        .onAppear {
            updateFor(session: session)
        }
    }
}

