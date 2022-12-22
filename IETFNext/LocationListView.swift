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
#if !os(macOS)
    @Environment(\.horizontalSizeClass) var sizeClass
#endif
    @SectionedFetchRequest<String, Location> var fetchRequest: SectionedFetchResults<String, Location>
    @Binding var selectedLocation: Location?
    @Binding var selectedMeeting: Meeting?
    @Binding var html: String
    @Binding var title: String
    @Binding var columnVisibility: NavigationSplitViewVisibility


    init(selectedMeeting: Binding<Meeting?>, selectedLocation: Binding<Location?>, html: Binding<String>, title: Binding<String>, columnVisibility: Binding<NavigationSplitViewVisibility>) {
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
        self._html = html
        self._title = title
        self._columnVisibility = columnVisibility
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
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
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
        }
        .onChange(of: selectedMeeting) { newValue in
            if let meeting = newValue {
                fetchRequest.nsPredicate = NSPredicate(format: "meeting.number = %@", meeting.number!)
            }
        }
        .onChange(of: selectedLocation) { newValue in
            if let location = selectedLocation {
                if let name = location.name {
                    /*
                     * macOS doesn't have sizeClass.
                     * TODO: level isn't showing up even on iOS
                    if let level = location.level_name {
                        // TODO: iPad landscape detail view is compat when all columns are shown
                        if sizeClass == .compact || level == "Uncategorized" {
                            title = name
                        } else {
                            title = "\(level) - \(name)"
                        }
                    }
                     */
                    title = name
                }
                if let map = location.map {
                    html = IMAGE_PRE + "\(map)" + IMAGE_POST
                } else {
                    html = BLANK
                }
            }
        }
        .onAppear {
            html = BLANK
            if columnVisibility == .all {
                columnVisibility = .doubleColumn
            }
        }
    }
}
