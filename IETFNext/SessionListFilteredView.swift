//
//  SessionListFilteredView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/5/22.
//

import SwiftUI
import CoreData


struct SessionListFilteredView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.loader) private var loader
    @SectionedFetchRequest<String, Session> var fetchRequest: SectionedFetchResults<String, Session>
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedSession: Session?
    @Binding var sessionsForGroup: [Session]?
    @Binding var html: String
    @Binding var title: String
    @Binding var sessionFilterMode: SessionFilterMode
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var agendas: [Agenda]


    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>, sessionsForGroup: Binding<[Session]?>, html: Binding<String>, title: Binding<String>, sessionFilterMode: Binding<SessionFilterMode>, columnVisibility: Binding<NavigationSplitViewVisibility>, agendas: Binding<[Agenda]>) {
        var predicate: NSPredicate
        var now: Date
        let number = selectedMeeting.wrappedValue?.number ?? "0"

        switch(sessionFilterMode.wrappedValue) {
        case .favorites:
            predicate = NSPredicate(format: "meeting.number = %@ AND favorite = %d", number, true)
        case .bofs:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (is_bof = %d)", number, true)
        case .now:
            now = Date()
            predicate = NSPredicate(format: "(meeting.number = %@) AND (start > %@) AND (end < %@)", number, now as CVarArg, now as CVarArg)
        case .today:
            now = Date()
            let calendar = Calendar.current
            let begin = calendar.startOfDay(for: now)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)
            if let end = end {
                predicate = NSPredicate(format: "(meeting.number = %@) AND (start > %@) AND (end < %@)", number, begin as CVarArg, end as CVarArg)
            } else {
                // we should NEVER hit this case but we don't want it to crash unexpectedly
                predicate = NSPredicate(format: "(meeting.number = %@) AND (start > %@)", number, begin as CVarArg)
            }
        case .none:
            predicate = NSPredicate(format: "meeting.number = %@", number)
        case .area_art:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@)", number, "art")
        case .area_gen:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@)", number, "gen")
        case .area_iab:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@)", number, "iab")
        case .area_ietf:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@)", number, "ietf")
        case .area_int:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@)", number, "int")
        case .area_irtf:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@)", number, "irtf")
        case .area_ops:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@)", number, "ops")
        case .area_rtg:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@)", number, "rtg")
        case .area_sec:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@)", number, "sec")
        case .area_tsv:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@)", number, "tsv")
        }

        _fetchRequest = SectionedFetchRequest<String, Session> (
            sectionIdentifier: \.day!,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Session.start, ascending: true),
                NSSortDescriptor(keyPath: \Session.end, ascending: false),
            ],
            predicate: predicate,
            animation: .default
        )

        self._selectedMeeting = selectedMeeting
        self._selectedSession = selectedSession
        self._sessionsForGroup = sessionsForGroup
        self._html = html
        self._title = title
        self._sessionFilterMode = sessionFilterMode
        self._columnVisibility = columnVisibility
        self._agendas = agendas
    }

    private func findSessionsForGroup(meeting: Meeting, group: Group) -> [Session]? {

        let fetchSession: NSFetchRequest<Session> = Session.fetchRequest()
        fetchSession.predicate = NSPredicate(format: "meeting = %@ AND group = %@", meeting, group)
        fetchSession.sortDescriptors = [
            NSSortDescriptor(keyPath: \Session.start, ascending: true)
        ]
        return try? viewContext.fetch(fetchSession)
    }

    var body: some View {
        List(fetchRequest, selection: $selectedSession) { section in
            Section(header: Text(section.id).foregroundColor(.primary)) {
                ForEach(section, id: \.self) { session in
                    SessionListRowView(session: session)
                        .listRowBackground(session.is_bof ? Color(hex: 0xbaffff, alpha: 0.2) : Color(.clear))
                }
            }
        }
        .listStyle(.inset)
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Schedule")
                        .foregroundColor(.primary)
                        .font(.headline)
                    Text("\(sessionFilterMode == .none ? "" : "Filter: \(sessionFilterMode.short)")")
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                }
            }
#if !os(macOS)
            ToolbarItem(placement: .bottomBar) {
                if let meeting = selectedMeeting {
                    if let number = meeting.number {
                        if let city = meeting.city {
                            Text("IETF \(number) (\(city))")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
#endif
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Section("Common Filters") {
                        Button(action: {
                            sessionFilterMode = .favorites
                        }) {
                            Label(SessionFilterMode.favorites.label, systemImage: SessionFilterMode.favorites.image)
                        }
                        Button(action: {
                            sessionFilterMode = .bofs
                        }) {
                            Label(SessionFilterMode.bofs.label, systemImage: SessionFilterMode.bofs.image)
                        }
                        Button(action: {
                            sessionFilterMode = .now
                        }) {
                            Label(SessionFilterMode.now.label, systemImage: SessionFilterMode.now.image)
                        }
                        Button(action: {
                            sessionFilterMode = .today
                        }) {
                            Label(SessionFilterMode.today.label, systemImage: SessionFilterMode.today.image)
                        }
                        Button(action: {
                            sessionFilterMode = .none
                        }) {
                            Label(SessionFilterMode.none.label, systemImage: SessionFilterMode.none.image)
                        }
                    }
                    Section("Filter by Area") {
                        Button(action: {
                            sessionFilterMode = .area_art
                        }) {
                            Label(SessionFilterMode.area_art.label, systemImage: SessionFilterMode.area_art.image)
                                .foregroundColor(.red)
                        }
                        Button(action: {
                            sessionFilterMode = .area_gen
                        }) {
                            Label(SessionFilterMode.area_gen.label, systemImage: SessionFilterMode.area_gen.image)
                        }
                        Button(action: {
                            sessionFilterMode = .area_int
                        }) {
                            Label(SessionFilterMode.area_int.label, systemImage: SessionFilterMode.area_int.image)
                        }
                        Button(action: {
                            sessionFilterMode = .area_irtf
                        }) {
                            Label(SessionFilterMode.area_irtf.label, systemImage: SessionFilterMode.area_irtf.image)
                        }
                        Button(action: {
                            sessionFilterMode = .area_ops
                        }) {
                            Label(SessionFilterMode.area_ops.label, systemImage: SessionFilterMode.area_ops.image)
                        }
                        Button(action: {
                            sessionFilterMode = .area_rtg
                        }) {
                            Label(SessionFilterMode.area_rtg.label, systemImage: SessionFilterMode.area_rtg.image)
                        }
                        Button(action: {
                            sessionFilterMode = .area_sec
                        }) {
                            Label(SessionFilterMode.area_sec.label, systemImage: SessionFilterMode.area_sec.image)
                        }
                        Button(action: {
                            sessionFilterMode = .area_tsv
                        }) {
                            Label(SessionFilterMode.area_tsv.label, systemImage: SessionFilterMode.area_tsv.image)
                        }
                    }
                }
                label: {
                    Label("More", systemImage: sessionFilterMode == .none ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }
        }
        .onChange(of: selectedMeeting) { newValue in
            if let meeting = newValue {
                fetchRequest.nsPredicate = NSPredicate(format: "meeting.number = %@", meeting.number!)
            }
        }
        .onChange(of: selectedSession) { newValue in
            if let meeting = selectedMeeting {
                if let session = selectedSession {
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
                        Task {
                            // TODO: this is getting called twice on selection but not sure why
                            await loader?.loadDrafts(groupID:group.objectID, limit:0, offset:0)
                            await loader?.loadCharterDocument(groupID:group.objectID)
                            await loader?.loadRelatedDrafts(groupID:group.objectID, limit:0, offset:0)
                        }
                    }
                }
            }
        }
        .onAppear() {
            if columnVisibility == .all {
                columnVisibility = .doubleColumn
            }
        }
    }

    // build a list of agenda items, number them only if more than 1
    func uniqueAgendasForSessions(sessions: [Session]?) -> [Agenda] {
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
}

