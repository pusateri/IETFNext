//
//  GroupListFilteredView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/5/22.
//

import SwiftUI
import CoreData


struct GroupListFilteredView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @SectionedFetchRequest<String, Group> var fetchRequest: SectionedFetchResults<String, Group>
    @Binding var selectedMeeting: Meeting?
    @State var selectedGroup: Group?
    @Binding var selectedSession: Session?
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var html: String
    @Binding var groupFavorites: Bool
    @State private var searchText = ""

    @SceneStorage("group.selection") var groupShort: String?

    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>, html: Binding<String>, columnVisibility: Binding<NavigationSplitViewVisibility>, groupFavorites: Binding<Bool>) {
        var predicate = NSPredicate(value: false)

        if groupFavorites.wrappedValue == false {
            predicate = NSPredicate(format: "ANY sessions.meeting.number = %@", selectedMeeting.wrappedValue?.number ?? "0")
        } else {
            predicate = NSPredicate(format: "(ANY sessions.meeting.number = %@) AND (ANY sessions.favorite = %d)", selectedMeeting.wrappedValue?.number ?? "0", true)
        }
        _fetchRequest = SectionedFetchRequest<String, Group>(
            sectionIdentifier: \.areaKey!,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Group.areaKey, ascending: true),
                NSSortDescriptor(keyPath: \Group.acronym, ascending: true),
            ],
            predicate: predicate,
            animation: .default
        )
        self._selectedMeeting = selectedMeeting
        self._selectedSession = selectedSession
        self._html = html
        self._columnVisibility = columnVisibility
        self._groupFavorites = groupFavorites
    }

    private func fetchGroup(short: String) -> Group? {
        let fetchGroup: NSFetchRequest<Group> = Group.fetchRequest()
        fetchGroup.predicate = NSPredicate(format: "acronym = %@", short)

        let results = try? viewContext.fetch(fetchGroup)

        return results?.first
    }

    private func updateGroupPredicate() {
        if let meeting = selectedMeeting {
            if groupFavorites == false {
                if searchText.isEmpty {
                    fetchRequest.nsPredicate = NSPredicate(format: "ANY sessions.meeting.number = %@", meeting.number!)
                } else {
                    fetchRequest.nsPredicate = NSPredicate(
                        format: "(ANY sessions.meeting.number = %@) AND ((name contains[cd] %@) OR (acronym contains[cd] %@) OR (state = [c] %@))", meeting.number!, searchText, searchText, searchText)
                }
            } else {
                if searchText.isEmpty {
                    fetchRequest.nsPredicate = NSPredicate(format: "(ANY sessions.meeting.number = %@) AND (ANY sessions.favorite = %d)", meeting.number!, true)
                } else {
                    fetchRequest.nsPredicate = NSPredicate(
                        format: "(ANY sessions.meeting.number = %@) AND (ANY sessions.favorite = %d) AND ((name contains[cd] %@) OR (acronym contains[cd] %@) OR (state = [c] %@))", meeting.number!, true, searchText, searchText, searchText)
                }
            }
        }
    }

    var body: some View {
        List(fetchRequest, selection: $selectedGroup) { section in
            Section(header: Text(section.id).textCase(.uppercase).foregroundColor(.accentColor)) {
                ForEach(section, id: \.self) { group in
                    GroupListRowView(selectedMeeting:$selectedMeeting, group:group)
                        .listRowSeparator(.visible)
                        .listRowBackground(group.state == "bof" ? Color(hex: 0xbaffff, alpha: 0.2) : Color(.clear))
                }
            }
            .headerProminence(.increased)
        }
        .listStyle(.inset)
#if !os(macOS)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .keyboardType(.alphabet)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .disableAutocorrection(true)
        .toolbar {
#if os(macOS)
            ToolbarItem(placement: .navigation) {
                GroupListTitleView(groupFavorites: $groupFavorites)
            }
            ToolbarItem(placement: .navigation) {
                GroupFilterMenu(groupFavorites: $groupFavorites)
            }
#else
            ToolbarItem(placement: .principal) {
                GroupListTitleView(groupFavorites: $groupFavorites)
            }
            ToolbarItem(placement: .primaryAction) {
                GroupFilterMenu(groupFavorites: $groupFavorites)
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
        .onChange(of: groupFavorites) { newValue in
            updateGroupPredicate()
        }
        .onChange(of: selectedMeeting) { newValue in
            if let meeting = newValue {
                fetchRequest.nsPredicate = NSPredicate(format: "ANY sessions.meeting.number = %@", meeting.number!)
            }
        }
        .onChange(of: selectedGroup) { newValue in
            searchText = ""
            if let group = newValue {
                if let meeting = selectedMeeting {
                    viewContext.performAndWait {
                        let sessions = group.groupSessions(meeting: meeting)
                        selectedSession = sessions?.first ?? nil
                    }
                }
                groupShort = group.acronym!
            } else {
#if !os(macOS)
                if UIDevice.isIPhone {
                    groupShort = nil
                }
#endif
            }
        }
        .onChange(of: searchText) { newValue in
            updateGroupPredicate()
        }
        .onAppear() {
            if columnVisibility == .all {
                columnVisibility = .doubleColumn
            }
            if let short = groupShort {
                selectedGroup = fetchGroup(short: short)
            }
        }
    }
}
