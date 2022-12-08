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
    @Environment(\.horizontalSizeClass) var sizeClass
    @SectionedFetchRequest<String, Location> var fetchRequest: SectionedFetchResults<String, Location>
    @Binding var selectedLocation: Location?
    @Binding var selectedMeeting: Meeting?
    @Binding var loadURL: URL?
    @Binding var title: String

    init(selectedMeeting: Binding<Meeting?>, selectedLocation: Binding<Location?>, loadURL: Binding<URL?>, title: Binding<String>) {
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
        self._selectedLocation = selectedLocation
        self._loadURL = loadURL
        self._title = title
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let meeting = selectedMeeting {
                    if let venue = meeting.venue_name {
                        VStack {
                            Text("Rooms")
                                .font(.headline)
                            Text(venue)
                                .font(.subheadline)
                        }
                    }
                }
            }
            ToolbarItem(placement: .bottomBar) {
                if let meeting = selectedMeeting {
                    if let number = meeting.number {
                        if let city = meeting.city {
                            Text("IETF \(number) (\(city))")
                                .font(.subheadline)
                                .foregroundColor(Color.blue)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedMeeting) { newValue in
            if let meeting = newValue {
                fetchRequest.nsPredicate = NSPredicate(format: "meeting.number = %@", meeting.number!)
            }
        }
        .onChange(of: selectedLocation) { newValue in
            if let location = selectedLocation {
                if let name = location.name {
                    if let level = location.level_name {
                        if sizeClass == .compact || level == "Uncategorized" {
                            title = name
                        } else {
                            title = "\(level) - \(name)"
                        }
                    }
                }
                if let map = location.map {
                    loadURL = map
                } else {
                    loadURL = URL(string: "about:blank")!
                }
            }
        }
        .onAppear {
            loadURL = URL(string: "about:blank")!
        }
    }
}
