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
                    Section(header: Text(section.id).textCase(.uppercase).foregroundColor(.accentColor)) {
                        ForEach(section, id: \.self) { group in
                            GroupListRowView(group:group)
                                .listRowSeparator(.visible)
                        }
                    }
                    .headerProminence(.increased)
                }
                .listStyle(.inset)
                .searchable(text: $searchText, placement: .automatic, prompt: "Group acronym, name, or BOF")
                .disableAutocorrection(true)
#if !os(macOS)
                .autocapitalization(.none)
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
            .onChange(of: selectedGroup) { newValue in
                if let group = newValue {
                    groupShort = group.acronym!
                } else {
#if !os(macOS)
                    if UIDevice.isIPhone {
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
