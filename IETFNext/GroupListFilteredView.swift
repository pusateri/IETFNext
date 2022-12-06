//
//  GroupListFilteredView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/5/22.
//

import SwiftUI


struct GroupListFilteredView: View {
    @SectionedFetchRequest<String, Group> var fetchRequest: SectionedFetchResults<String, Group>
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedGroup: Group?
    @State private var searchText = ""

    init(selectedMeeting: Binding<Meeting?>, selectedGroup: Binding<Group?>) {
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
    }

    var body: some View {
        List(fetchRequest, selection: $selectedGroup) { section in
            Section(header: Text(section.id.uppercased()).foregroundColor(Color.blue)) {
                ForEach(section, id: \.self) { group in
                    HStack {
                        Rectangle()
                            .fill(Color(hex: areaColors[group.areaKey ?? "ietf"] ?? 0xffff99))
                            .frame(width: 8, height: 32)
                        VStack(alignment: .leading) {
                            Text(group.acronym!)
                                .bold()
                            Text(group.name!)
                                .foregroundColor(Color(.gray))
                        }
                    }
                }
            }
            //.headerProminence(.increased)
        }
        .listStyle(.inset)
        .searchable(text: $searchText)
        .keyboardType(.alphabet)
        .disableAutocorrection(true)
        .onChange(of: selectedMeeting) { newValue in
            if let meeting = newValue {
                fetchRequest.nsPredicate = NSPredicate(format: "ANY sessions.meeting.number = %@", meeting.number!)
            }
        }
        .onChange(of: selectedGroup) { newValue in
            searchText = ""
        }
        .onChange(of: searchText) { newValue in
            if newValue.isEmpty {
                fetchRequest.nsPredicate = nil
            } else {
                if let meeting = selectedMeeting {
                    fetchRequest.nsPredicate = NSPredicate(
                        format: "(ANY sessions.meeting.number = %@) AND ((name contains[cd] %@) OR (acronym contains[cd] %@))", meeting.number!, newValue, newValue)
                }
            }
        }
    }
}
