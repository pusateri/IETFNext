//
//  LocationDetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/25/22.
//

import SwiftUI


extension DynamicFetchRequestView where T : Session {
    init(selectedMeeting: Binding<Meeting?>, selectedLocation: Binding<Location?>, @ViewBuilder content: @escaping (FetchedResults<T>) -> Content) {

        var predicate = NSPredicate(value: false)

        if let loc = selectedLocation.wrappedValue {
            if let meeting = selectedMeeting.wrappedValue {
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

    @Binding var selectedMeeting: Meeting?
    @Binding var selectedLocation: Location?
    @Binding var sessionFormatter: DateFormatter?
    @Binding var timerangeFormatter: DateFormatter?
    @Binding var locationDetailMode: LocationDetailMode

    var body: some View {
        switch(locationDetailMode) {
        case .location:
            VStack() {
                if let location = selectedLocation {
                    if let level = location.level_name, level != "Uncategorized" {
                        Text("\(location.level_name!)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                    if let url = location.map {
                        AsyncImage(url: url, transaction: Transaction(animation: .spring())) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                if colorScheme == .light {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .transition(.scale)
                                } else if colorScheme == .dark {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .transition(.scale)
                                        .colorInvert()
                                }
                            case .failure(_):
                                EmptyView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    if vSizeClass != .compact {
                        DynamicFetchRequestView(selectedMeeting: $selectedMeeting, selectedLocation: $selectedLocation) { results in

                            if let formatter = sessionFormatter {
                                let groupByDate = Dictionary(grouping: results, by: {
                                    formatter.string(from: $0.start!)
                                })
                                List {
                                    ForEach(groupByDate.keys.sorted(), id: \.self) { section in
                                        Section(header: Text(section).foregroundColor(.accentColor)) {
                                            ForEach(groupByDate[section]!, id: \.self) { session in
                                                VStack(alignment: .leading) {
                                                    HStack {
                                                        if let formatter = timerangeFormatter {
                                                            Text("\(formatter.string(from: session.start!))-\(formatter.string(from: session.end!))")
                                                                .font(.title3)
                                                                .foregroundColor(.primary)
                                                        }
                                                        Spacer()
                                                        Text("\(session.group?.acronym ?? "")")
                                                            .foregroundColor(.primary)
                                                            .font(.subheadline)
                                                    }
                                                    .padding(.all, 2)
                                                    Text(session.name!)
                                                        .foregroundColor(.secondary)
                                                        .font(.subheadline)
    #if os(macOS)
                                                        .padding(.bottom, 5)
    #endif
                                                }
                                                .listRowSeparator(.visible)
                                            }
                                        }
                                    }
                                }
                                .listStyle(.inset)
                            }
                        }
                    }
                }
            }
            .background(colorScheme == .light ? .white : .black)
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
            if UIDevice.isIPhone {
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
