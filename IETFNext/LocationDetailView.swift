//
//  LocationDetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/25/22.
//

import SwiftUI


class MapSize: ObservableObject {
    @Published var size: CGSize
    var url: URL?

    init(url: URL?) {
        self.url = url
        self.size = CGSize()

        DispatchQueue.global().async {
            if let url = url {
                if let data = try? Data(contentsOf: url) {
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.size = image.size
                        }
                    }
                }
            }
        }
    }
}

struct LocationDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.verticalSizeClass) var vSizeClass

    @SectionedFetchRequest<String, Session> var fetchRequest: SectionedFetchResults<String, Session>
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedLocation: Location?
    //@State private var pulse = false

    //@ObservedObject private var map: MapSize

    init(selectedMeeting: Binding<Meeting?>, selectedLocation: Binding<Location?>) {
        var predicate = NSPredicate(value: false)

        self._selectedMeeting = selectedMeeting
        self._selectedLocation = selectedLocation

        if let loc = selectedLocation.wrappedValue {
            if let meeting = selectedMeeting.wrappedValue {
                predicate = NSPredicate(format: "(meeting.number = %@) AND (location.name = %@) AND (status != \"canceled\")", meeting.number!, loc.name!)
            }
        }
        //map = MapSize(url: selectedLocation.wrappedValue?.map)

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

    private func pinXPosition(size: CGSize, geom: GeometryProxy, location: Location) -> CGFloat {
        var x: CGFloat = 0.0
        if size.width > 0.0 {
            x = CGFloat(location.x) * geom.size.width / size.width
        }
        return x
    }

    private func pinYPosition(size: CGSize, geom: GeometryProxy, location: Location) -> CGFloat {
        var y: CGFloat = 0.0
        if size.height > 0.0 {
            y = CGFloat(location.y) * geom.size.height / size.height
        }
        return y
    }

    var body: some View {
        VStack() {
            if let location = selectedLocation {
                if let level = location.level_name, level != "Uncategorized" {
                    Text("\(location.level_name!)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let url = location.map {
                    //GeometryReader { geo in
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
                    /*
                        .overlay(
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.red)
                                .position(
                                    x: pinXPosition(size: map.size, geom: geo, location: location),
                                    y: pinYPosition(size: map.size, geom: geo, location: location)
                                )
                                .offset(x: 0, y: pulse ? -7 : -20)
                                .onAppear {
                                    withAnimation(
                                        .easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true)
                                        .speed(1.5)
                                    ) {
                                        pulse.toggle()
                                    }
                                }
                        )
                     */
                    //}
                }
                if vSizeClass != .compact {
                    List(fetchRequest) { section in
                        Section(header: Text(section.id).foregroundColor(.accentColor)) {
                            ForEach(section, id: \.self) { session in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("\(session.timerange!)")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(session.group?.acronym ?? "")")
                                            .foregroundColor(.primary)
                                            .font(.subheadline)
                                    }
                                    Text(session.name!)
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                }
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
