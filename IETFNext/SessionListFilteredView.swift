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
    @SectionedFetchRequest<String, Session> var fetchRequest: SectionedFetchResults<String, Session>
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedSession: Session?
    @Binding var html: String
    @Binding var title: String
    @Binding var sessionFilterMode: SessionFilterMode
    @Binding var agendas: [Agenda]


    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>, html: Binding<String>, title: Binding<String>, sessionFilterMode: Binding<SessionFilterMode>, agendas: Binding<[Agenda]>) {
        var predicate: NSPredicate
        let number = selectedMeeting.wrappedValue?.number ?? "0"
        let now = Date() as CVarArg

        switch(sessionFilterMode.wrappedValue) {
        case .favorites:
            predicate = NSPredicate(format: "meeting.number = %@ AND favorite = %d", number, true)
        case .bofs:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (is_bof = %d)", number, true)
        case .now:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (start > %@) AND (end < %@)", number, now, now)
        case .day, .none:
            predicate = NSPredicate(format: "meeting.number = %@", number)
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
        self._html = html
        self._title = title
        self._sessionFilterMode = sessionFilterMode
        self._agendas = agendas
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
        .navigationBarTitleDisplayMode(.inline)
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
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Section("Session Filters") {
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
                            sessionFilterMode = .none
                        }) {
                            Label(SessionFilterMode.none.label, systemImage: SessionFilterMode.none.image)
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
                            let all_sessions = findSessionsForGroup(context:viewContext, meeting:meeting, group:group)
                            agendas = uniqueAgendasForSessions(sessions: all_sessions)
                        }

                        if let wg = group.acronym {
                            // update the title and load the corresponding documents
                            title = wg
                        }
                        Task {
                            await loadDrafts(context:viewContext, limit:0, offset:0, group:group)
                            await loadCharterDocument(context:viewContext, group:group)
                        }
                    }
                }
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

