//
//  ContentView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI
import CoreData

extension Bundle {
    var releaseVersionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
    var buildVersionNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
}

protocol CompoundEnum {
    var image: String { get }
    var label: String { get }
    var short: String { get }
}

enum SessionFilterMode: String, CompoundEnum {
    case bofs
    case favorites
    case none
    case now
    case today
    case area_art
    case area_gen
    case area_iab
    case area_ietf
    case area_int
    case area_irtf
    case area_ops
    case area_rtg
    case area_sec
    case area_tsv

    var image: String {
        switch(self) {
        case .favorites:
            return "star.fill"
        case .today:
            return "clock"
        case .now:
            return "exclamationmark.2"
        case .bofs:
            return "bird"
        case .none:
            return "circle.slash"
        default:
            return "square.3.layers.3d.down.forward"
        }
    }
    var label: String {
        switch(self) {
        case .favorites:
            return "Show Favorites"
        case .today:
            return "Show Today"
        case .now:
            return "Show Now"
        case .bofs:
            return "Show BoFs"
        case .none:
            return "No Filter"
        case .area_art:
            return "ART Area"
        case .area_gen:
            return "GEN Area"
        case .area_iab:
            return "IAB"
        case .area_ietf:
            return "IETF"
        case .area_int:
            return "INT Area"
        case .area_irtf:
            return "IRTF"
        case .area_ops:
            return "OPS Area"
        case .area_rtg:
            return "RTG Area"
        case .area_sec:
            return "SEC Area"
        case .area_tsv:
            return "TSV Area"
        }
    }
    var short: String {
        switch(self) {
        case .favorites:
            return "Favorites"
        case .today:
            return "Today"
        case .now:
            return "Now"
        case .bofs:
            return "BoFs"
        case .none:
            return "None"
        case .area_art:
            return "ART"
        case .area_gen:
            return "GEN"
        case .area_iab:
            return "IAB"
        case .area_ietf:
            return "IETF"
        case .area_int:
            return "INT"
        case .area_irtf:
            return "IRTF"
        case .area_ops:
            return "OPS"
        case .area_rtg:
            return "RTG"
        case .area_sec:
            return "SEC"
        case .area_tsv:
            return "TSV"
        }
    }
}

public struct Agenda: Identifiable, Hashable {
    public let id: Int32
    public let desc: String
    public let url: URL
}

// drafts downloaded are categorized by type and stored in one of three group relations
enum DocumentKind: String {
    case charter
    case draft
    case related
    case rfc
}

public enum SidebarOption: String {
    case none
    case schedule
    case groups
    case locations
    case download
}

struct Choice: Identifiable, Hashable {
    var id: SidebarOption
    var text: String
    var imageName: String
}

extension Choice {
    typealias ChoiceItem = (String, Choice)
    static let sectionChoices: [ChoiceItem] = [
        ("IETF", Choice(id: .schedule, text: "Schedule", imageName: "calendar")),
        ("IETF", Choice(id: .groups, text: "Working Groups", imageName: "person.3")),
        ("IETF", Choice(id: .locations, text: "Venue & Room Locations", imageName: "map")),
        ("Local", Choice(id: .download, text: "Downloads", imageName: "arrow.down.circle")),
    ]
}

private class ChoiceViewModel: ObservableObject {
    @Published var choices: [Choice.ChoiceItem] = Choice.sectionChoices
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.loader) private var loader
    @State private var showingMeetings = false
    @State var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State var selectedMeeting: Meeting?
    @State var selectedGroup: Group? = nil
    @State var selectedSession: Session?
    @State var sessionsForGroup: [Session]?
    @State var selectedLocation: Location?
    @State var html: String = ""
    @State var fileURL: URL? = nil
    @State var title: String = ""
    @State var sessionFilterMode: SessionFilterMode = .none
    @State var groupFavorites: Bool = false
    @State var agendas: [Agenda] = []

    @SceneStorage("ContentView.sidebarPath") private var sidebarOption: SidebarOption?

    @ViewBuilder
    var first_header: some View {
        if let m = selectedMeeting {
            Text("IETF \(m.number!) \(m.city!)")
        } else {
            Text("IETF")
        }
    }
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Download.basename, ascending: true)],
        animation: .default)
    private var downloads: FetchedResults<Download>
    @StateObject fileprivate var viewModel = ChoiceViewModel()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List() {
                Section(header: first_header) {
                    NavigationLink(value: SidebarOption.schedule) {
                        Label("Schedule", systemImage: "calendar")
                    }
                    NavigationLink(value: SidebarOption.groups) {
                        Label("Working Groups", systemImage: "person.3")
                    }
                    NavigationLink(value: SidebarOption.locations) {
                        Label("Venue & Room Locations", systemImage: "map")
                    }
                }
                Section(header: Text("Local")) {
                    NavigationLink(value: SidebarOption.download) {
                        HStack {
                            Label("Downloads", systemImage: "arrow.down.circle")
                            Spacer()
                            Text("\(downloads.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationDestination(for: SidebarOption.self) { sidebar in
                switch(sidebar) {
                case .none:
                    Text("Please go back and selection Menu option")
                case .schedule:
                    SessionListFilteredView(selectedMeeting: $selectedMeeting, selectedSession: $selectedSession, sessionsForGroup:$sessionsForGroup, html: $html, title: $title, sessionFilterMode: $sessionFilterMode, columnVisibility:$columnVisibility, agendas: $agendas)
                case .groups:
                    GroupListFilteredView(selectedMeeting: $selectedMeeting, selectedGroup: $selectedGroup, selectedSession: $selectedSession, html: $html, title: $title, columnVisibility:$columnVisibility, groupFavorites: $groupFavorites)
                case .locations:
                    LocationListView(selectedMeeting: $selectedMeeting, selectedLocation: $selectedLocation, html:$html, title: $title, columnVisibility:$columnVisibility)
                case .download:
                    DownloadListView(html:$html, fileURL:$fileURL, title:$title, columnVisibility:$columnVisibility)
                }
            }
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button(action: {
                            showingMeetings.toggle()
                        }) {
                            Label("Change Meeting", systemImage: "airplane.departure")
                        }
                        Label("Version \(Bundle.main.releaseVersionNumber).\(Bundle.main.buildVersionNumber) (\(Git.kRevisionNumber))", systemImage: "v.circle")
                    }
                    label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        } content: {
            SessionListFilteredView(selectedMeeting: $selectedMeeting, selectedSession: $selectedSession, sessionsForGroup:$sessionsForGroup, html: $html, title: $title, sessionFilterMode: $sessionFilterMode, columnVisibility:$columnVisibility, agendas: $agendas)
        } detail: {
            DetailView(
                selectedMeeting:$selectedMeeting,
                selectedSession:$selectedSession,
                sessionsForGroup:$sessionsForGroup,
                html:$html,
                fileURL:$fileURL,
                title:$title,
                columnVisibility:$columnVisibility,
                agendas: $agendas)
        }
        .sheet(isPresented: $showingMeetings) {
            MeetingListView(selectedMeeting: $selectedMeeting)
        }
        .onAppear {
            if let number = UserDefaults.standard.string(forKey:"MeetingNumber") {
                viewContext.performAndWait {
                    selectedMeeting = selectMeeting(context: viewContext, number: number)
                }
                if let meeting = selectedMeeting {
                    Task {
                        await loader?.loadData(meetingID: meeting.objectID)
                    }
                }
            } else {
                showingMeetings.toggle()
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
