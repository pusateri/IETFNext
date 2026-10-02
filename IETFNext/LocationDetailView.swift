//
//  LocationDetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/25/22.
//

import SwiftUI


extension DynamicFetchRequestView where T : Session {
    init(selectedMeeting: Meeting?, selectedLocation: Location?, @ViewBuilder content: @escaping (FetchedResults<T>) -> Content) {

        var predicate = NSPredicate(value: false)

        if let loc = selectedLocation {
            if let meeting = selectedMeeting {
                predicate = NSPredicate(format: "(meeting.number = %@) AND (location.name = %@) AND (status != \"canceled\")", meeting.number!, loc.name!)
            }
        }
        let sortDescriptors = [
            NSSortDescriptor(keyPath: \Session.start, ascending: true),
            NSSortDescriptor(keyPath: \Session.end, ascending: false),
            NSSortDescriptor(keyPath: \Session.name, ascending: true),
        ]
        self.init( withPredicate: predicate, andSortDescriptor: sortDescriptors, content: content)
    }
}

struct LocationDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.verticalSizeClass) var vSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Read-only inputs are passed by value so ContentView depends on them and the detail
    // column updates when a room is picked (see DetailView).
    let selectedMeeting: Meeting?
    let selectedLocation: Location?
    @Binding var sessionFormatter: DateFormatter?
    @Binding var timerangeFormatter: DateFormatter?
    let locationDetailMode: LocationDetailMode

    var body: some View {
        switch(locationDetailMode) {
        case .location:
            VStack() {
                if let location = selectedLocation {
                    if let level = location.level_name, level != "Uncategorized" {
                        Text("\(location.level_name!)")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .padding(.top)
                    }
                    if let url = location.map {
                        // Zoomable map with its blank margins trimmed (see FloorMapImage).
                        FloorMapImage(url: url)
                            .accessibilityLabel("Floor map")
                            .accessibilityIdentifier("location.map")
                            // A new room starts at the fitted (un-zoomed) map, even when rooms on
                            // the same floor share a map image.
                            .id(location.objectID)
                    }
                    if vSizeClass != .compact {
                        DynamicFetchRequestView(selectedMeeting: selectedMeeting, selectedLocation: selectedLocation) { results in

                            if let formatter = sessionFormatter {
                                List {
                                    // Grouped once per render (see SessionDaySection).
                                    ForEach(SessionDaySection.sections(from: results, formatter: formatter)) { day in
                                        Section {
                                            ForEach(day.sessions, id: \.self) { session in
                                                VStack(alignment: .leading) {
                                                    HStack {
                                                        if let formatter = timerangeFormatter {
                                                            Text("\(formatter.string(from: session.start!))-\(formatter.string(from: session.end!))")
                                                                .font(.title3)
                                                                .foregroundStyle(.primary)
                                                        }
                                                        Spacer()
                                                        Text("\(session.group?.acronym ?? "")")
                                                            .foregroundStyle(.primary)
                                                            .font(.subheadline)
                                                    }
                                                    .padding(.all, 2)
                                                    Text(session.name!)
                                                        .foregroundStyle(.secondary)
                                                        .font(.subheadline)
    #if os(macOS)
                                                        .padding(.bottom, 5)
    #endif
                                                }
                                                .listRowSeparator(.visible)
                                            }
                                        } header: {
                                            Text(day.title).foregroundStyle(Color.accentColor)
                                        }
                                    }
                                }
                                .listStyle(.inset)
                                // Start the session list right below the map instead of after
                                // the list's default top margin.
                                .contentMargins(.top, 0, for: .scrollContent)
                            }
                        }
                    }
                }
            }
            // System background adapts to light/dark and elevated contexts (was hardcoded white/black).
            .background(.background)
    #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
    #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if let location = selectedLocation {
                        Text("\(location.name!)").bold()
                    } else {
                        if let meeting = selectedMeeting {
                            if let venue = meeting.venue_name {
                                Text("\(venue)").bold()
                            }
                        }
                    }
                }
            }
        case .none:
            if let meeting = selectedMeeting {
                if let urlString = venuePhotos[meeting.number!] {
                    AsyncImage(url: URL(string: urlString)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .transition(.scale)
                    } placeholder: {
                        ProgressView()
                    }
#if !os(macOS)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            if let venue = meeting.venue_name {
                                Text(venue)
                                    .font(.headline)
                            }
                        }
                    }
#endif
                }
            }
        case .weather:
#if !os(macOS)
            // When collapsed, LocationListView presents weather as a sheet instead.
            if horizontalSizeClass == .compact {
                EmptyView()
            } else {
                if let meeting = selectedMeeting {
                    WeatherView(meeting: meeting)
                } else {
                    Text("Please select Meeting in Sidebar")
                }
            }
#else
            if let meeting = selectedMeeting {
                WeatherView(meeting: meeting)
            } else {
                Text("Please select Meeting in Sidebar")
            }
#endif
        }
    }
}
