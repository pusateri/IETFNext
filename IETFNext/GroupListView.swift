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

    @SectionedFetchRequest(
        sectionIdentifier: \.areaKey!, sortDescriptors: [
            NSSortDescriptor(keyPath: \Group.areaKey, ascending: true),
            NSSortDescriptor(keyPath: \Group.acronym, ascending: true),
        ],
        animation: .default)
    private var groups: SectionedFetchResults<String, Group>

    @State private var selected: String?

    var body: some View {
        List(groups, selection: $selected) { section in
            Section(header: Text(section.id).foregroundColor(Color.blue)) {
                ForEach(section) { group in
                    VStack(alignment: .leading) {
                        Text(group.acronym!)
                            .bold()
                        Text(group.name!)
                            .foregroundColor(Color(.gray))
                    }
                }
            }
            .textCase(.uppercase)
        }
    }
}

struct GroupListView_Previews: PreviewProvider {
    static var previews: some View {
        GroupListView()
    }
}
