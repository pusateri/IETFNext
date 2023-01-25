//
//  SessionListFilteredView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/5/22.
//

import SwiftUI
import CoreData


extension DynamicFetchRequestView where T : Session {

    init(withMeeting meeting: Binding<Meeting?>, searchText: String, filterMode: Binding<SessionFilterMode>, @ViewBuilder content: @escaping (FetchedResults<T>) -> Content) {

        var now: Date
        var search_criteria = searchText.isEmpty ? "" : "((name contains[cd] %@) OR (group.acronym contains[cd] %@)) AND "
        var args: [CVarArg] = searchText.isEmpty ? [] : [searchText, searchText]

        search_criteria += "(meeting.number = %@) AND (status != \"canceled\")"
        args.append(meeting.wrappedValue?.number ?? "0")

        switch(filterMode.wrappedValue) {
            case .favorites:
                search_criteria += " AND (group.favorite = true)"
            case .bofs:
                search_criteria += " AND (is_bof = true)"
            case .now:
                now = Date()
                search_criteria += " AND (start > %@) AND (end < %@)"
                args.append(now as CVarArg)
                args.append(now as CVarArg)
            case .today:
                now = Date()
                let calendar = Calendar.current
                let begin = calendar.startOfDay(for: now)
                let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)
                if let end = end {
                    search_criteria += " AND (start > %@) AND (end < %@)"
                    args.append(begin as CVarArg)
                    args.append(end as CVarArg)
                } else {
                        // we should NEVER hit this case but we don't want it to crash unexpectedly
                    search_criteria += " AND (start > %@)"
                    args.append(begin as CVarArg)
                }
            case .none:
                break
            case .area_art:
                search_criteria += " AND (group.area.name = \"art\")"
            case .area_gen:
                search_criteria += " AND (group.area.name = \"gen\")"
            case .area_iab:
                search_criteria += " AND (group.area.name = \"iab\")"
            case .area_ietf:
                search_criteria += " AND (group.area.name = \"ietf\")"
            case .area_int:
                search_criteria += " AND (group.area.name = \"int\")"
            case .area_irtf:
                search_criteria += " AND (group.area.name = \"irtf\")"
            case .area_ops:
                search_criteria += " AND (group.area.name = \"ops\")"
            case .area_rtg:
                search_criteria += " AND (group.area.name = \"rtg\")"
            case .area_sec:
                search_criteria += " AND (group.area.name = \"sec\")"
            case .area_tsv:
                search_criteria += " AND (group.area.name = \"tsv\")"
        }

        let predicate = NSPredicate(format: search_criteria, argumentArray: args)

        let sortDescriptors = [
            NSSortDescriptor(keyPath: \Session.start, ascending: true),
            NSSortDescriptor(keyPath: \Session.end, ascending: false),
            NSSortDescriptor(keyPath: \Session.name, ascending: true),
        ]
        self.init( withPredicate: predicate, andSortDescriptor: sortDescriptors, content: content)
    }
}

struct SessionListFilteredView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedGroup: Group?
    @Binding var sessionFilterMode: SessionFilterMode
    @Binding var sessionFormatter: DateFormatter?
    @Binding var timerangeFormatter: DateFormatter?
    @Binding var html: String
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @State var selected: Session? = nil
    @State private var searchText = ""
    @SceneStorage("schedule.selection") var sessionID: Int?

    private func fetchSession(session_id: Int32) -> Session? {
        let fetchSession: NSFetchRequest<Session> = Session.fetchRequest()
        fetchSession.predicate = NSPredicate(format: "id = %d", session_id)

        let results = try? viewContext.fetch(fetchSession)

        return results?.first
    }

    var body: some View {
        ScrollViewReader { scrollViewReader in
            DynamicFetchRequestView(withMeeting: $selectedMeeting, searchText: searchText, filterMode: $sessionFilterMode) { results in

                if let formatter = sessionFormatter {
                    let groupByDate = Dictionary(grouping: results, by: {
                        formatter.string(from: $0.start!)
                    })
                    List(selection: $selected) {
                        ForEach(groupByDate.keys.sorted(), id: \.self) { section in
                            Section(header: Text(section).foregroundColor(.primary)) {
                                ForEach(groupByDate[section]!, id: \.self) { session in
                                    if let session_group = session.group {
                                        SessionListRowView(session: session, group: session_group, timerangeFormatter: $timerangeFormatter)
                                            .listRowSeparator(.visible)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                    .searchable(text: $searchText, placement: .automatic, prompt: "Session name or Group acronym")
                    .disableAutocorrection(true)
#if !os(macOS)
                    .autocapitalization(.none)
                    .keyboardType(.alphabet)
                    .navigationBarTitleDisplayMode(.inline)
#endif
                }
            }
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
                if columnVisibility == .all {
                    columnVisibility = .doubleColumn
                }
                if let session_id = sessionID {
                    selected = fetchSession(session_id: Int32(session_id))
                    if let session = selected {
                        withAnimation {
                            scrollViewReader.scrollTo(session, anchor: .center)
                        }
                    }
                } else {
                    html = BLANK
                }
            }
        }
    }
}

