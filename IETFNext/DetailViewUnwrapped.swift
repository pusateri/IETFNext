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
    @Environment(\.horizontalSizeClass) var sizeClass

    @FetchRequest<Presentation> var presentationRequest: FetchedResults<Presentation>
    @FetchRequest<Document> var charterRequest: FetchedResults<Document>
    // Core Data objects are passed in, not owned, so observe them rather than using @StateObject.
    @ObservedObject var meeting: Meeting
    @ObservedObject var group: Group
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @State var sessionsForGroup: [Session]? = nil
    @State var agendas: [Agenda] = []
    @State var banner: String = "foo"
    @State private var showingDocuments = false
    @State var draftURL: String? = nil
    @State var draftTitle: String? = nil
    @State var kind: DocumentKind = .draft
    @State private var model = DownloadViewModel()
    @State private var refreshCount = 0

    init(meeting: Meeting, group: Group, columnVisibility: Binding<NavigationSplitViewVisibility>) {

        self.meeting = meeting
        self.group = group

        self._columnVisibility = columnVisibility

        _presentationRequest = FetchRequest<Presentation>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Presentation.order, ascending: true),
            ],
            predicate: NSPredicate(format: "(session.meeting.number = %@) AND (session.group.acronym = %@)", meeting.number!, group.acronym!),
            animation: .default
        )
        _charterRequest = FetchRequest<Document>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Document.time, ascending: false),
            ],
            predicate: NSPredicate(format: "(name contains %@) AND (type contains \"charter\")", group.acronym!),
            animation: .default
        )
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

    private func saveFavorite(group: Group) {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Unable to save Session favorite \(group.acronym!)")
            }
        }
    }

    /// Identifies one run of the group-loading task: it restarts when the group changes
    /// or when the scene becomes active again (tracked by `refreshCount`).
    private struct GroupTaskKey: Equatable {
        /// Included so changing meetings reloads sessions, agendas and recordings for the new meeting.
        let meeting: NSManagedObjectID
        let group: NSManagedObjectID
        let refresh: Int
    }

    private func updateFor(group: Group) {
        banner = group.acronym!
        sessionsForGroup = findSessionsForGroup(meeting:meeting, group:group)
        agendas = uniqueAgendasForSessions(sessions: sessionsForGroup)
        // TODO: don't always load first agenda, load selected session agenda
        if let agenda = agendas.first {
            model.download = fetchDownload(context: viewContext, kind:.agenda, url:agenda.url)
            if model.download == nil {
                model.startDownload(context:viewContext, url: agenda.url, group:group, kind:.agenda, title: "IETF \(meeting.number!) (\(meeting.city!)) \(group.acronym!.uppercased())")
            }
        } else {
            // No agenda for this group at this meeting (e.g. after changing meetings): clear the
            // previous document rather than leaving another meeting's or group's agenda on screen.
            model.cancelDownload()
            model.download = nil
        }
    }

    /// Loads drafts, charter, related drafts and recordings for the group.
    /// Runs inside `.task(id:)`, so it is cancelled when the view disappears or the group changes.
    private func loadGroupMetadata(group: Group) async {
        await loadDrafts(context: viewContext, group: group, limit:0, offset:0)
        if group.type != "rg" {
            await loadCharterDocument(context: viewContext, group: group)
        }
        await loadRelatedDrafts(context: viewContext, group: group, limit:0, offset:0)
        // if we don't have a recording URL, go get one. We don't expect it to change once we have it
        for s in sessionsForGroup ?? [] where s.recording == nil {
            if Task.isCancelled { return }
            await loadRecordingDocument(context: viewContext, session: s)
        }
    }

    var body: some View {
        WebView(download:$model.download)
        .navigationTitle(banner)
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            if #available(iOS 27, *) {
                leadingToolbarItems
                // If the bar runs out of room, overflow Slides and Documents first and keep
                // Favorite and More. (On iPhone 17 Pro the system truncates a long title
                // before overflowing any of these, so this doesn't by itself free title space.)
                ToolbarItem { favoriteButton }
                    .visibilityPriority(.high)
                ToolbarItem { slidesMenu }
                    .visibilityPriority(.low)
                ToolbarItem { documentsButton }
                    .visibilityPriority(.low)
                ToolbarItem { moreMenu }
                    .visibilityPriority(.high)
            } else {
                legacyToolbarItems
            }
        }
        .sheet(isPresented: $showingDocuments) {
            // DocumentListView sizes itself on macOS. The old 740pt frame here was taller than the
            // 700pt minimum window height, pushing the sheet's Cancel button off-screen.
            DocumentListView(wg:group.acronym!, urlString:$draftURL, titleString:$draftTitle, kind:$kind)
        }
        .onChange(of: group) { _, newValue in
            // TODO: slides are combined into the group and all slides are shown for all sessions of group
            presentationRequest.nsPredicate = NSPredicate(format: "session.group = %@", newValue)
        }
        .onChange(of: meeting) { _, newValue in
            // The fetch request's predicate is only applied in init, so refresh the Slides menu for
            // the new meeting, matching init's meeting-and-group filter.
            presentationRequest.nsPredicate = NSPredicate(format: "(session.meeting = %@) AND (session.group = %@)", newValue, group)
        }
        .onChange(of: model.error) { _, newValue in
            if let err = newValue {
                if err.starts(with: "Http Result 404:") {
                    if let urlString = draftURL as? NSString {
                        if urlString.pathExtension == "html" {
                            draftURL = urlString.replacingOccurrences(of: ".html", with: ".txt")
                        }
                    }
                } else {
                    print("DetailViewUnwrapped model.error: \(err)")
                }
            }
        }
        .onChange(of:draftURL) { _, newValue in
            if let urlString = newValue {
                if let url = URL(string:urlString) {
                    model.download = fetchDownload(context: viewContext, kind:.draft, url:url)
                    if model.download == nil {
                        model.startDownload(context:viewContext, url:url, group:group, kind:.draft, title:draftTitle)
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshCount += 1
            }
        }
        .task(id: GroupTaskKey(meeting: meeting.objectID, group: group.objectID, refresh: refreshCount)) {
            updateFor(group: group)
            await loadGroupMetadata(group: group)
        }
        // Downloads are not cancelled on disappear: on iPhone the collapsed split view reuses
        // this view across pushes, and the disappear from popping the previous group can
        // arrive after the next group's download has started, silently cancelling it.
        // The model still cancels an older download when a newer one is requested.
    }
}

// MARK: - Toolbar

extension DetailViewUnwrapped {
    /// Items shared by both toolbar layouts.
    @ToolbarContentBuilder
    private var leadingToolbarItems: some ToolbarContent {
#if os(macOS)
        // The macOS window toolbar hides the window title, so show the group name here.
        ToolbarItem(placement: .principal) {
            Text(banner).bold()
        }
#else
        if sizeClass == .regular {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    switch (columnVisibility) {
                        case .detailOnly:
                            withAnimation {
                                columnVisibility = .doubleColumn
                            }

                        default:
                            withAnimation {
                                columnVisibility = .detailOnly
                            }
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
    }

    /// Toolbar for OS versions without `visibilityPriority` (iOS 26.x).
    @ToolbarContentBuilder
    private var legacyToolbarItems: some ToolbarContent {
        leadingToolbarItems
        ToolbarItemGroup {
            favoriteButton
            slidesMenu
            documentsButton
            moreMenu
        }
    }

    private var favoriteButton: some View {
        Button(action: {
            group.favorite.toggle()
            saveFavorite(group: group)
        }) {
            Image(systemName: group.favorite == true ? "star.fill" : "star")
                .foregroundStyle(Color(hex: areaColors[group.areaKey ?? "ietf"] ?? 0xf6c844))
#if os(macOS)
                .overlay {
                    Image(systemName: "star")
                        .imageScale(.large)
                        // Outline adapts to dark mode (was hardcoded black).
                        .foregroundStyle(.primary)
                }
#endif
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(group.favorite ? "Remove from favorites" : "Add to favorites")
        .accessibilityIdentifier("detail.favorite")
    }

    private var slidesMenu: some View {
        Menu {
            ForEach(presentationRequest) { p in
                Button(action: {
                    let urlString = "https://www.ietf.org/proceedings/\(meeting.number!)/slides/\(p.name!)-\(p.rev!).pdf"
                    if let url = URL(string: urlString) {
                        model.download = fetchDownload(context: viewContext, kind:.presentation, url:url)
                        if model.download == nil {
                            model.startDownload(context:viewContext, url:url, group:group, kind:.presentation, title: p.title)
                        }
                    }
                }) {
                    Text(p.title!)
                    Image(systemName: "square.stack")
                }
            }
        }
        label: {
            Label("Slides", systemImage: "rectangle.on.rectangle.angled")
        }
    }

    private var documentsButton: some View {
        Button(action: {
            showingDocuments.toggle()
        }) {
            Label("Documents", systemImage: "doc")
        }
    }

    private var moreMenu: some View {
        Menu {
            ForEach(agendas) { agenda in
                Button(action: {
                    model.download = fetchDownload(context: viewContext, kind:.agenda, url:agenda.url)
                    if model.download == nil {
                        model.startDownload(context:viewContext, url: agenda.url, group:group, kind:.agenda, title: "IETF \(meeting.number!) (\(meeting.city!)) \(group.acronym!.uppercased())")
                    }
                }) {
                    Text("\(agenda.desc)")
                    Image(systemName: "list.bullet.clipboard")
                }
            }
            Button(action: {
                // TODO: Should be only one minutes for all sessions, but check on this
                if let session = sessionsForGroup?.first {
                    if let minutes = session.minutes {
                        model.download = fetchDownload(context: viewContext, kind:.minutes, url:minutes)
                        if model.download == nil {
                            model.startDownload(context:viewContext, url: minutes, group:group, kind:.minutes, title: "IETF \(meeting.number!) (\(meeting.city!)) \(group.acronym!.uppercased())")
                        }
                    }
                }
            }) {
                Text("View Minutes")
                Image(systemName: "clock")
            }
            .disabled(sessionsForGroup?.first?.minutes == nil)
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
                    Text("View Recording\(recordingSuffix(session:session))")
                    Image(systemName: "play")
                }
                .disabled(session.recording == nil)
            }
            Button(action: {
                if let rev = charterRequest.first?.rev {
                    let urlString = "https://www.ietf.org/charter/charter-ietf-\(group.acronym!)-\(rev).txt"
                    if let url = URL(string: urlString) {
                        model.download = fetchDownload(context: viewContext, kind:.charter, url:url)
                        if model.download == nil {
                            model.startDownload(context:viewContext, url:url, group:group, kind:.charter, title: "\(group.acronym!.uppercased()) Charter")
                        }
                    }
                }
            }) {
                if let rev = charterRequest.first?.rev {
                    Text("View Charter (v\(rev))")
                } else {
                    Text("View Charter")
                }
                Image(systemName: "pencil")
            }
            .disabled(charterRequest.first == nil)
            Button(action: {
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
            }) {
                Text("Mailing List Archive")
                Image(systemName: "envelope")
            }
        }
        label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
}

