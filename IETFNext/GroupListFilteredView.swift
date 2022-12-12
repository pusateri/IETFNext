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
    @Binding var selectedGroup: Group?
    @Binding var selectedSession: Session?
    @Binding var loadURL: URL?
    @Binding var title: String
    @State private var searchText = ""

    init(selectedMeeting: Binding<Meeting?>, selectedGroup: Binding<Group?>, selectedSession: Binding<Session?>, loadURL: Binding<URL?>, title: Binding<String>) {
        _fetchRequest = SectionedFetchRequest<String, Group>(
            sectionIdentifier: \.areaKey!,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Group.areaKey, ascending: true),
                NSSortDescriptor(keyPath: \Group.acronym, ascending: true),
            ],
            predicate: NSPredicate(format: "ANY sessions.meeting.number = %@", selectedMeeting.wrappedValue?.number ?? "0"),
            animation: .default
        )
        self._selectedMeeting = selectedMeeting
        self._selectedGroup = selectedGroup
        self._selectedSession = selectedSession
        self._loadURL = loadURL
        self._title = title
    }

    var body: some View {
        List(fetchRequest, selection: $selectedGroup) { section in
            Section(header: Text(section.id.uppercased()).foregroundColor(.accentColor)) {
                ForEach(section, id: \.self) { group in
                    GroupListRowView(selectedMeeting:$selectedMeeting, group:group)
                        .listRowBackground(group.state == "bof" ? Color(hex: 0xbaffff, alpha: 0.2) : Color(.clear))
                }
            }
            .headerProminence(.increased)
        }
        .listStyle(.inset)
        .searchable(text: $searchText)
        .keyboardType(.alphabet)
        .disableAutocorrection(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Groups")
                    .font(.headline)
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
                        //let sessions = findSessionsForGroup(context:viewContext, meeting:meeting, group:group)
                        selectedSession = sessions?.first ?? nil
                    }
                }
            }
        }
        .onChange(of: searchText) { newValue in
            if let meeting = selectedMeeting {
                if newValue.isEmpty {
                    fetchRequest.nsPredicate = NSPredicate(format: "ANY sessions.meeting.number = %@", meeting.number!)
                } else {
                    fetchRequest.nsPredicate = NSPredicate(
                        format: "(ANY sessions.meeting.number = %@) AND ((name contains[cd] %@) OR (acronym contains[cd] %@) OR (state = [c] %@))", meeting.number!, newValue, newValue, newValue)
                }
            }
        }
    }
}
