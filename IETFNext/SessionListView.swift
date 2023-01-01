//
//  SessionListFilteredView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/5/22.
//

import SwiftUI
import CoreData


#if !os(macOS)
extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
#endif

struct SessionListFilteredView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @SectionedFetchRequest<String, Session> var fetchRequest: SectionedFetchResults<String, Session>
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedGroup: Group?
    @Binding var sessionFilterMode: SessionFilterMode
    @Binding var html: String
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @State var selected: Session? = nil
    @SceneStorage("schedule.selection") var sessionID: Int?

    private func fetchSession(session_id: Int32) -> Session? {
        let fetchSession: NSFetchRequest<Session> = Session.fetchRequest()
        fetchSession.predicate = NSPredicate(format: "id = %d", session_id)

        let results = try? viewContext.fetch(fetchSession)

        return results?.first
    }

    init(selectedMeeting: Binding<Meeting?>, selectedGroup: Binding<Group?>, sessionFilterMode: Binding<SessionFilterMode>, html: Binding<String>, columnVisibility: Binding<NavigationSplitViewVisibility>) {
        var predicate: NSPredicate
        var now: Date
        let number = selectedMeeting.wrappedValue?.number ?? "0"

        switch(sessionFilterMode.wrappedValue) {
        case .favorites:
            predicate = NSPredicate(format: "meeting.number = %@ AND group.favorite = %d AND (status != \"canceled\")", number, true)
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
        self._selectedGroup = selectedGroup
        self._sessionFilterMode = sessionFilterMode
        self._html = html
        self._columnVisibility = columnVisibility
    }

    var body: some View {
        List(fetchRequest, selection: $selected) { section in
            Section(header: Text(section.id).foregroundColor(.primary)) {
                ForEach(section, id: \.self) { session in
                    if let session_group = session.group {
                        SessionListRowView(session: session, group: session_group)
                            .listRowSeparator(.visible)
                            .listRowBackground(session.is_bof ? Color(hex: 0xbaffff, alpha: 0.2) : Color(.clear))
                    }
                }
            }
        }
        .listStyle(.inset)
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
#if os(macOS)
            ToolbarItem(placement: .navigation) {
                SessionListTitleView(sessionFilterMode: $sessionFilterMode)
            }
            ToolbarItem(placement: .navigation) {
                SessionFilterMenu(sessionFilterMode: $sessionFilterMode)
            }
#else
            ToolbarItem(placement: .principal) {
                SessionListTitleView(sessionFilterMode: $sessionFilterMode)
            }
            ToolbarItem(placement: .primaryAction) {
                SessionFilterMenu(sessionFilterMode: $sessionFilterMode)
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
#endif
        }
        .onChange(of: selectedMeeting) { newValue in
            if let meeting = newValue {
                fetchRequest.nsPredicate = NSPredicate(format: "meeting.number = %@", meeting.number!)
            }
        }
        .onChange(of: selected) { newValue in
            if let session = newValue {
                sessionID = Int(session.id)
                selectedGroup = session.group
            } else {
#if !os(macOS)
                if UIDevice.isIPhone {
                    sessionID = nil
                }
#endif
            }
        }
        .onAppear {
            html = BLANK
            if columnVisibility == .all {
                columnVisibility = .doubleColumn
            }
            if let session_id = sessionID {
                selected = fetchSession(session_id: Int32(session_id))
            }
        }
    }
}

