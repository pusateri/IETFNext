//
//  SessionListFilteredView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/5/22.
//

import SwiftUI
import CoreData
import AppIntents


extension DynamicFetchRequestView where T : Session {

    init(withMeeting meeting: Binding<Meeting?>, searchText: String, filterMode: Binding<SessionFilterMode>, @ViewBuilder content: @escaping (FetchedResults<T>) -> Content) {
        let predicate = SessionPredicate.make(
            meetingNumber: meeting.wrappedValue?.number,
            searchText: searchText,
            filterMode: filterMode.wrappedValue
        )
        self.init( withPredicate: predicate, andSortDescriptor: SessionPredicate.sortDescriptors, content: content)
    }
}

struct SessionListFilteredView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.appNavigator) private var navigator
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedGroup: Group?
    @Binding var sessionFilterMode: SessionFilterMode
    @Binding var sessionFormatter: DateFormatter?
    @Binding var timerangeFormatter: DateFormatter?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @State var selected: Session? = nil
    @State private var searchText = ""
    @SceneStorage("schedule.selection") var sessionID: Int?

    @State private(set) var activityType: String? = nil
    @State private(set) var currentActivity: NSUserActivity? = nil

    private func fetchSession(session_id: Int32) -> Session? {
        let fetchSession: NSFetchRequest<Session> = Session.fetchRequest()
        fetchSession.predicate = NSPredicate(format: "id = %d", session_id)

        let results = try? viewContext.fetch(fetchSession)

        return results?.first
    }

    /// Selects the session an App Intent asked to show, if there is one.
    @discardableResult
    private func selectRoutedSession(scrollViewProxy: ScrollViewProxy) -> Bool {
        guard let id = navigator.take(\.sessionID), let session = fetchSession(session_id: id) else {
            return false
        }
        selected = session
        withAnimation {
            scrollViewProxy.scrollTo(session, anchor: .center)
        }
        return true
    }

    private func donateActivity(session: Session) {
        self.currentActivity = NSUserActivity(activityType: "com.bangj.ietf.selectedSession")
        self.currentActivity?.title = session.name
        self.currentActivity?.isEligibleForHandoff = true
#if !os(macOS)
        self.currentActivity?.isEligibleForPrediction = true
#endif
        self.currentActivity?.persistentIdentifier = String(sessionID ?? 0)
        // Lets Siri resolve "this session" and learn which sessions get opened.
        self.currentActivity?.appEntityIdentifier = EntityIdentifier(for: SessionEntity.self, identifier: Int(session.id))
        self.currentActivity?.becomeCurrent()
    }

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            DynamicFetchRequestView(withMeeting: $selectedMeeting, searchText: searchText, filterMode: $sessionFilterMode) { results in
                if let formatter = sessionFormatter {
                    // Grouped once per render and shared by the list and the day index.
                    // Sessions without a group are dropped here rather than producing empty rows.
                    let days = SessionDaySection.sections(from: results, formatter: formatter, requireGroup: true)
                    List(selection: $selected) {
                        ForEach(days) { day in
                            Section {
                                // `id: \.self` is the managed object's identity, and it doubles as
                                // the selection tag, which must be a `Session` to match `selected`.
                                ForEach(day.sessions, id: \.self) { session in
                                    // Single-root row: the VStack keeps the row unary so List can
                                    // use its fast path (a bare `if` made each row 0 or 1 views).
                                    VStack {
                                        if let session_group = session.group {
                                            SessionListRowView(session: session, group: session_group, timerangeFormatter: $timerangeFormatter)
                                        }
                                    }
                                    .listRowSeparator(.visible)
                                }
                            } header: {
                                // `Color.primary`, not hierarchical `.primary`: inside a section
                                // header the hierarchical style resolves to the header's grey.
                                Text(day.title)
                                    .foregroundStyle(Color.primary)
                            }
                            .id(day.id)
                        }
                    }
                    .listStyle(.inset)
                    .meetingBar(selectedMeeting)
                    .searchable(text: $searchText, placement: .automatic, prompt: "Session name or Group acronym")
                    .autocorrectionDisabled()
                    .overlay(alignment: .trailing) {
                        // Day index floating directly over the list, with no background, so it
                        // doesn't take width from the rows.
                        VStack {
                            ForEach(days) { day in
                                Button(action: {
                                    scrollViewProxy.scrollTo(day.id, anchor: .top)
                                }) {
                                    Text(day.shortDay)
                                }
                                .accessibilityLabel("Jump to \(day.weekday)")
                            }
                        }
                        .accessibilityIdentifier("schedule.dayIndex")
                    }
#if !os(macOS)
                    .textInputAutocapitalization(.never)
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
#endif
            }
            .onChange(of: selected) { _, newValue in
                if let session = newValue {
                    sessionID = Int(session.id)
                    selectedGroup = session.group
                    donateActivity(session: session)
                } else {
#if !os(macOS)
                    // In a collapsed split view, backing out of the detail clears the selection;
                    // forget the saved session too so it isn't re-selected on return.
                    if horizontalSizeClass == .compact {
                        sessionID = nil
                    }
#endif
                }
            }
            .onAppear {
                if columnVisibility == .all {
                    withAnimation {
                        columnVisibility = .doubleColumn
                    }
                }
                // A session requested by an App Intent replaces the saved selection.
                if selectRoutedSession(scrollViewProxy: scrollViewProxy) {
                    return
                }
                // Restoring a selection in a collapsed split view would push the detail
                // instead of showing the list.
                if horizontalSizeClass != .compact, let session_id = sessionID {
                    selected = fetchSession(session_id: Int32(session_id))
                    if let session = selected {
                        withAnimation {
                            scrollViewProxy.scrollTo(session, anchor: .center)
                        }
                    }
                }
            }
            .onChange(of: navigator.routed) {
                selectRoutedSession(scrollViewProxy: scrollViewProxy)
            }
            .onContinueUserActivity("com.bangj.ietf.selectedSession", perform: { userActivity in
                if let session_str = userActivity.persistentIdentifier {
                    if let session_id = Int32(session_str) {
                        if session_id != 0 {
                            selected = fetchSession(session_id: session_id)
                        }
                    }
                }
            })
        }
    }
}

