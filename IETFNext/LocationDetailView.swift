//
//  LocationDetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/25/22.
//

import SwiftUI

let venuePhotos = [
    "116": "https://www.pacifico.co.jp/Portals/0/images/en/index/kv/kv_01re.jpg",
    "115": "https://weekender-hotel-api-2.imgix.net/hotel-images/20170206-LONMETW-hotel-banner-1.jpg?auto=format&q=50&w=1200&dpr=1.5",
    "114": "https://cache.marriott.com/content/dam/marriott-renditions/PHLWS/phlws-exterior-0091-hor-clsc.jpg",
    "113": "https://www.hilton.com/im/en/VIEHITW/14562339/hilton-vienna-exterior.jpg?impolicy=crop&cw=4517&ch=2540&gravity=NorthWest&xposition=0&yposition=229&rw=1214&rh=683",
    "106": "https://d2e5ushqwiltxm.cloudfront.net/wp-content/uploads/sites/203/2019/11/08031528/fairmont-singapore-night-view.jpg",
]

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
    @Environment(\.horizontalSizeClass) var hSizeClass

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

    private func escapedAddress(meeting: Meeting) -> String? {
        if let venue_addr = meeting.venue_addr {
            return venue_addr
                .replacingOccurrences(of: "\r\n", with: ",")
                .replacingOccurrences(of: " ,", with: ",")
                .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        } else {
            return nil
        }
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
            ToolbarItem {
                Menu {
                    if let meeting = selectedMeeting {
                        if let _ = venuePhotos[meeting.number!] {
                            if hSizeClass != .compact {
                                Button(action: {
                                    selectedLocation = nil
                                }) {
                                    Label("Show Venue Photo", systemImage: "photo")
                                }
                            }
                        }
                    }
                    Button(action: {
                        if let meeting = selectedMeeting {
                            if let addr = escapedAddress(meeting: meeting) {
                                let urlString = "https://maps.apple.com/?address=\(addr)"
                                guard let url = URL(string: urlString) else {
                                    print("Invalid venue address URL: \(urlString)")
                                    return
                                }
#if os(macOS)
                                NSWorkspace.shared.open(url)
#else
                                UIApplication.shared.open(url)
#endif
                            }
                        }
                    }) {
                        Label("Show Venue on Map", systemImage: "mappin.and.ellipse")
                    }
                    .disabled(selectedMeeting?.venue_addr?.isEmpty ?? true)
                    Button(action: {
                        if let meeting = selectedMeeting {
                            if let addr = escapedAddress(meeting: meeting) {
                                let urlString = "https://maps.apple.com/?daddr=\(addr)"
                                guard let url = URL(string: urlString) else {
                                    print("Invalid venue address URL: \(urlString)")
                                    return
                                }
#if os(macOS)
                                NSWorkspace.shared.open(url)
#else
                                UIApplication.shared.open(url)
#endif
                            }
                        }
                    }) {
                        Label("Directions to Venue", systemImage: "mappin.and.ellipse")
                    }
                    .disabled(selectedMeeting?.venue_addr?.isEmpty ?? true)
                }
                label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
    }
}
