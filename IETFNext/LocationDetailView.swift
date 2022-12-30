//
//  LocationDetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/25/22.
//

import SwiftUI

struct LocationDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.verticalSizeClass) var vSizeClass

    @SectionedFetchRequest<String, Session> var fetchRequest: SectionedFetchResults<String, Session>
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedLocation: Location?

    init(selectedMeeting: Binding<Meeting?>, selectedLocation: Binding<Location?>) {
        var predicate = NSPredicate(value: false)

        self._selectedMeeting = selectedMeeting
        self._selectedLocation = selectedLocation

        if let loc = selectedLocation.wrappedValue {
            if let meeting = selectedMeeting.wrappedValue {
                predicate = NSPredicate(format: "(meeting.number = %@) AND (location.name = %@) AND (status != \"canceled\")", meeting.number!, loc.name!)
            }
        }

        _fetchRequest = SectionedFetchRequest<String, Session> (
            sectionIdentifier: \.day!,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Session.start, ascending: true),
                NSSortDescriptor(keyPath: \Session.end, ascending: false),
            ],
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
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
                    List(fetchRequest) { section in
                        Section(header: Text(section.id).foregroundColor(.accentColor)) {
                            ForEach(section, id: \.self) { session in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("\(session.timerange!)")
                                            .font(.title3)
                                            .foregroundColor(.primary)
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
                    .listStyle(.inset)
                }
            } else {
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
    }
}
