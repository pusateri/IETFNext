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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Group.acronym, ascending: false)],
        animation: .default)
    private var groups: FetchedResults<Group>

    @State private var selected: String?

    var body: some View {
        List(groups, selection: $selected) { group in
            Text("\(group.acronym!))")
        }
    }
}

struct GroupListView_Previews: PreviewProvider {
    static var previews: some View {
        GroupListView()
    }
}
