//
//  LocationListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/28/22.
//

import SwiftUI
import CoreData

struct LocationListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @SectionedFetchRequest(
        sectionIdentifier: \.level_name!, sortDescriptors: [
            NSSortDescriptor(keyPath: \Location.level_name, ascending: true),
            NSSortDescriptor(keyPath: \Location.name, ascending: true),
        ],
        animation: .default)
    private var locations: SectionedFetchResults<String, Location>

    var body: some View {
        List(locations) { section in
            Section(header: Text(section.id)) {
                ForEach(section) { location in
                    Text(location.name ?? "Unknown")
                }
            }
        }
    }
}

struct LocationListView_Previews: PreviewProvider {
    static var previews: some View {
        LocationListView()
    }
}
