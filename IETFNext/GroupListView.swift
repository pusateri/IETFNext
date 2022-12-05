//
//  GroupListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI
import CoreData

struct GroupListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedGroup: Group?
    @State private var searchText = ""

    @SectionedFetchRequest<String, Group>(
        sectionIdentifier: \.areaKey!, sortDescriptors: [
            NSSortDescriptor(keyPath: \Group.areaKey, ascending: true),
            NSSortDescriptor(keyPath: \Group.acronym, ascending: true),
        ],
        animation: .default)
    private var groups: SectionedFetchResults<String, Group>

    var body: some View {
        List(groups) { section in
            Section(header: Text(section.id.uppercased()).foregroundColor(Color.blue)) {
                ForEach(section, id: \.self.acronym) { group in
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
                    .onTapGesture {
                        selectedGroup = group
                    }
                }
            }
            .headerProminence(.increased)
        }
        .searchable(text: $searchText)
    }
/*
    var searchResults: [String] {
       if searchText.isEmpty {
         return names
       } else {
         return names.filter { $0.contains(searchText) }
       }
   }
 */
}

struct GroupListView_Previews: PreviewProvider {
    static var previews: some View {
        GroupListView(selectedMeeting: .constant(nil), selectedGroup: .constant(nil))
    }
}
