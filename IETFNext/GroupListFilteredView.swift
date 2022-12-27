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
    @Binding var groupFavorites: Bool
    @State private var searchText = ""

    init(selectedMeeting: Binding<Meeting?>, selectedSession: Binding<Session?>, columnVisibility: Binding<NavigationSplitViewVisibility>, groupFavorites: Binding<Bool>) {
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
        self._columnVisibility = columnVisibility
        self._groupFavorites = groupFavorites
    }

    private func updatePredicate() {
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
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Groups")
                        .foregroundColor(.primary)
                        .font(.headline)
                    Text("\(groupFavorites ? "Filter: Favorites" : "")")
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
                Button(action: {
                    withAnimation {
                        groupFavorites.toggle()
                        updatePredicate()
                    }
                }) {
                    Label("Filter", systemImage: groupFavorites == true ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .onChange(of: selectedMeeting) { newValue in
            if let meeting = newValue {
                fetchRequest.nsPredicate = NSPredicate(format: "ANY sessions.meeting.number = %@", meeting.number!)
            }
        }
        .onChange(of: selectedGroup) { newValue in
            searchText = ""
            if let group = selectedGroup {
                if let meeting = selectedMeeting {
                    viewContext.performAndWait {
                        let sessions = group.groupSessions(meeting: meeting)
                        selectedSession = sessions?.first ?? nil
                    }
                }
            }
        }
        .onChange(of: searchText) { newValue in
            updatePredicate()
        }
        .onAppear() {
            if columnVisibility == .all {
                columnVisibility = .doubleColumn
            }
        }
    }
}
