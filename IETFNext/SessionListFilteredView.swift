//
//  SessionListFilteredView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/5/22.
//

import SwiftUI
import CoreData


extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

struct SessionListFilteredView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @SectionedFetchRequest<String, Session> var fetchRequest: SectionedFetchResults<String, Session>
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedSession: Session?
    @Binding var loadURL: URL?
    @Binding var title: String
    @Binding var scheduleFavorites: Bool
    @Binding var agendas: [Agenda]


    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>, loadURL: Binding<URL?>, title: Binding<String>, scheduleFavorites: Binding<Bool>, agendas: Binding<[Agenda]>) {
        var predicate: NSPredicate

        if scheduleFavorites.wrappedValue == false {
            predicate = NSPredicate(format: "meeting.number = %@", selectedMeeting.wrappedValue?.number ?? "0")
        } else {
            predicate = NSPredicate(format: "meeting.number = %@ AND favorite = %d", selectedMeeting.wrappedValue?.number ?? "0", true)
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
        self._loadURL = loadURL
        self._title = title
        self._scheduleFavorites = scheduleFavorites
        self._agendas = agendas
    }

    private func updatePredicate() {
        if let meeting = selectedMeeting {
            if scheduleFavorites == false {
                fetchRequest.nsPredicate = NSPredicate(format: "meeting.number = %@", meeting.number!)
            } else {
                fetchRequest.nsPredicate = NSPredicate(format: "meeting.number = %@ AND favorite = %d", meeting.number!, true)
            }
        }
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
                    Text("\(scheduleFavorites ? "Filter: Favorites" : "")")
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
                Button(action: {
                    withAnimation {
                        scheduleFavorites.toggle()
                        updatePredicate()
                    }
                }) {
                    Label("Filter", systemImage: scheduleFavorites == true ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
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
                    if let agenda = session.agenda {
                        loadURL = agenda
                    } else {
                        loadURL = URL(string: "about:blank")!
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

