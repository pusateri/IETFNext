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
    @SectionedFetchRequest<String, Location> var fetchRequest: SectionedFetchResults<String, Location>
    @State var selectedLocation: Location?
    @Binding var selectedMeeting: Meeting?

    init(selectedMeeting: Binding<Meeting?>) {
        _fetchRequest = SectionedFetchRequest<String, Location>(
            sectionIdentifier: \.level_name!,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Location.level_name, ascending: true),
                NSSortDescriptor(keyPath: \Location.name, ascending: true),
            ],
            predicate: NSPredicate(format: "meeting.number = %@", selectedMeeting.wrappedValue?.number ?? "0"),
            animation: .default
        )
        self._selectedMeeting = selectedMeeting
    }

    var body: some View {
        List(fetchRequest, selection: $selectedLocation) { section in
            Section(header: Text(section.id)) {
                ForEach(section, id: \.self) { location in
                    HStack {
                        Text(location.name ?? "Unknown")
                        Spacer()
                        if location.sessions?.count ?? 0 == 1 {
                            Text("1 Session")
                        } else {
                            Text("\(location.sessions?.count ?? 0) Sessions")
                        }
                    }
                }
            }
            .headerProminence(.increased)
        }
        .listStyle(.inset)
        .onChange(of: selectedMeeting) { newValue in
            if let meeting = newValue {
                fetchRequest.nsPredicate = NSPredicate(format: "meeting.number = %@", meeting.number!)
            }
        }
        .onChange(of: selectedLocation) { newValue in
            if let location = selectedLocation {
                print(location.name!)
            }
        }
    }
}
