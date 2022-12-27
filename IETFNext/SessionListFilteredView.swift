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
    @Binding var sessionFilterMode: SessionFilterMode
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @SceneStorage("schedule.selection") var sessionID: Int?

    private func fetchSession(session_id: Int32) -> Session? {
        let fetchSession: NSFetchRequest<Session> = Session.fetchRequest()
        fetchSession.predicate = NSPredicate(format: "id = %d", session_id)

        let results = try? viewContext.fetch(fetchSession)

        return results?.first
    }

    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>, sessionFilterMode: Binding<SessionFilterMode>, columnVisibility: Binding<NavigationSplitViewVisibility>) {
        var predicate: NSPredicate
        var now: Date
        let number = selectedMeeting.wrappedValue?.number ?? "0"

        switch(sessionFilterMode.wrappedValue) {
        case .favorites:
            predicate = NSPredicate(format: "meeting.number = %@ AND favorite = %d AND (status != \"canceled\")", number, true)
        case .bofs:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (is_bof = %d) AND (status != \"canceled\")", number, true)
        case .now:
            now = Date()
            predicate = NSPredicate(format: "(meeting.number = %@) AND (start > %@) AND (end < %@) AND (status != \"canceled\")", number, now as CVarArg, now as CVarArg)
        case .today:
            now = Date()
            let calendar = Calendar.current
            let begin = calendar.startOfDay(for: now)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)
            if let end = end {
                predicate = NSPredicate(format: "(meeting.number = %@) AND (start > %@) AND (end < %@) AND (status != \"canceled\")", number, begin as CVarArg, end as CVarArg)
            } else {
                // we should NEVER hit this case but we don't want it to crash unexpectedly
                predicate = NSPredicate(format: "(meeting.number = %@) AND (start > %@)", number, begin as CVarArg)
            }
        case .none:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (status != \"canceled\")", number)
        case .area_art:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@) AND (status != \"canceled\")", number, "art")
        case .area_gen:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@) AND (status != \"canceled\")", number, "gen")
        case .area_iab:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@) AND (status != \"canceled\")", number, "iab")
        case .area_ietf:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@) AND (status != \"canceled\")", number, "ietf")
        case .area_int:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@) AND (status != \"canceled\")", number, "int")
        case .area_irtf:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@) AND (status != \"canceled\")", number, "irtf")
        case .area_ops:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@) AND (status != \"canceled\")", number, "ops")
        case .area_rtg:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@) AND (status != \"canceled\")", number, "rtg")
        case .area_sec:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@) AND (status != \"canceled\")", number, "sec")
        case .area_tsv:
            predicate = NSPredicate(format: "(meeting.number = %@) AND (group.area.name = %@) AND (status != \"canceled\")", number, "tsv")
        }

        _fetchRequest = SectionedFetchRequest<String, Session> (
            sectionIdentifier: \.day!,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Session.start, ascending: true),
                NSSortDescriptor(keyPath: \Session.end, ascending: false),
                NSSortDescriptor(keyPath: \Session.name, ascending: true),
            ],
            predicate: predicate,
            animation: .default
        )

        self._selectedMeeting = selectedMeeting
        self._selectedSession = selectedSession
        self._sessionFilterMode = sessionFilterMode
        self._columnVisibility = columnVisibility
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
            if let session = selectedSession {
                sessionID = Int(session.id)
            } else {
                sessionID = nil
            }
        }
        .onAppear() {
            if columnVisibility == .all {
                columnVisibility = .doubleColumn
            }
            if let session_id = sessionID {
                selectedSession = fetchSession(session_id: Int32(session_id))
            }
        }
    }
}

