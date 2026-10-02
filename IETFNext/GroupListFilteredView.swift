//
//  GroupListFilteredView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/5/22.
//

import SwiftUI
import CoreData


extension DynamicSectionedFetchRequestView where T : Group {

    init(withMeeting meeting: Binding<Meeting?>, searchText: String, filterMode: Binding<GroupFilterMode>, @ViewBuilder content: @escaping (SectionedFetchResults<String, T>) -> Content) {

        var search_criteria = searchText.isEmpty ? "" : "((name contains[cd] %@) OR (acronym contains[cd] %@) OR (state = [c] %@)) AND "
        var args = searchText.isEmpty ? [] : [searchText, searchText, searchText]

        search_criteria += "(ANY sessions.meeting.number = %@)"
        args.append(meeting.wrappedValue?.number ?? "0")

        if filterMode.wrappedValue == .favorites {
            search_criteria += " AND (favorite = true)"
        }
        let predicate = NSPredicate(format: search_criteria, argumentArray: args)

        let sortDescriptors = [
            NSSortDescriptor(keyPath: \Group.areaKey, ascending: true),
            NSSortDescriptor(keyPath: \Group.acronym, ascending: true),
        ]
        self.init( withPredicate: predicate, andSectionIdentifier: \.areaKey!, andSortDescriptor: sortDescriptors, content: content)
    }
}

struct GroupListFilteredView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var selectedMeeting: Meeting?
    @Binding var selectedGroup: Group?
    @Binding var groupFilterMode: GroupFilterMode
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @State private var searchText = ""
    @SceneStorage("group.selection") var groupShort: String?

    private func fetchGroup(short: String) -> Group? {
        let fetchGroup: NSFetchRequest<Group> = Group.fetchRequest()
        fetchGroup.predicate = NSPredicate(format: "acronym = %@", short)

        let results = try? viewContext.fetch(fetchGroup)

        return results?.first
    }

    var body: some View {
        ScrollViewReader { scrollViewReader in
            DynamicSectionedFetchRequestView(withMeeting: $selectedMeeting, searchText: searchText, filterMode: $groupFilterMode) { results in
                List(results, selection: $selectedGroup) { section in
                    Section {
                        ForEach(section, id: \.self) { group in
                            GroupListRowView(group:group)
                                .listRowSeparator(.visible)
                        }
                    } header: {
                        Text(section.id).textCase(.uppercase).foregroundStyle(Color.accentColor)
                    }
                    .headerProminence(.increased)
                }
                .listStyle(.inset)
                .meetingBar(selectedMeeting)
                .searchable(text: $searchText, placement: .automatic, prompt: "Group acronym, name, or BOF")
                .autocorrectionDisabled()
#if !os(macOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.alphabet)
                .navigationBarTitleDisplayMode(.inline)
#endif
            }
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .navigation) {
                    GroupListTitleView(groupFilterMode: $groupFilterMode)
                }
                ToolbarItem(placement: .navigation) {
                    GroupFilterMenu(groupFilterMode: $groupFilterMode)
                }
#else
                ToolbarItem(placement: .principal) {
                    GroupListTitleView(groupFilterMode: $groupFilterMode)
                }
                ToolbarItem(placement: .primaryAction) {
                    GroupFilterMenu(groupFilterMode: $groupFilterMode)
                }
#endif
            }
            .onChange(of: selectedGroup) { _, newValue in
                if let group = newValue {
                    groupShort = group.acronym!
                } else {
#if !os(macOS)
                    // In a collapsed split view, backing out of the detail clears the selection;
                    // forget the saved group too so it isn't re-selected on return.
                    if horizontalSizeClass == .compact {
                        groupShort = nil
                    }
#endif
                }
            }
            .onAppear() {
                if columnVisibility == .all {
                    withAnimation {
                        columnVisibility = .doubleColumn
                    }
                }
                if let short = groupShort {
                    selectedGroup = fetchGroup(short: short)
                    if let group = selectedGroup {
                        withAnimation {
                            scrollViewReader.scrollTo(group, anchor: .center)
                        }
                    }
                }
                if selectedGroup == nil {
                    //html = BLANK
                }
            }
        }
    }
}
