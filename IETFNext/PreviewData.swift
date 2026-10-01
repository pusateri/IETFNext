//
//  PreviewData.swift
//  IETFNext
//
//  Sample Core Data objects for SwiftUI previews. Debug builds only.
//

#if DEBUG
import Foundation
import CoreData

/// Realistic sample data (IETF 126, Vienna) in an in-memory store, for `#Preview`s.
@MainActor
enum PreviewData {
    /// In-memory container. It reuses the app's managed object model so the entity classes
    /// aren't claimed by two models in the same process.
    static let container: NSPersistentContainer = {
        let model = RFCProvider.shared.container.managedObjectModel
        let container = NSPersistentContainer(name: "IETFNextPreview", managedObjectModel: model)
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Preview store failed to load: \(error)")
            }
        }
        return container
    }()

    static var context: NSManagedObjectContext { container.viewContext }

    static let meeting: Meeting = {
        let meeting = Meeting(context: context)
        meeting.number = "126"
        meeting.city = "Vienna"
        meeting.country = "AT"
        meeting.date = "2026-07-18"
        meeting.time_zone = "Europe/Vienna"
        meeting.venue_name = "Austria Center Vienna"
        meeting.start = date("2026-07-18T09:00")
        return meeting
    }()

    static let group: Group = {
        let group = Group(context: context)
        group.acronym = "cbor"
        group.name = "Concise Binary Object Representation Maintenance and Extensions"
        group.areaKey = "art"
        group.state = "active"
        group.type = "wg"
        group.favorite = true
        return group
    }()

    static let location: Location = {
        let location = Location(context: context)
        location.id = 1
        location.name = "Grand Park Hall 2"
        location.level_name = "Mezzanine Level"
        location.modified = Date()
        location.meeting = meeting
        return location
    }()

    static let session: Session = {
        let session = Session(context: context)
        session.id = 33_001
        session.session_id = 33_001
        session.name = "Concise Binary Object Representation Maintenance and Extensions"
        session.status = "sched"
        session.is_bof = false
        session.start = date("2026-07-23T09:30")
        session.end = date("2026-07-23T11:30")
        session.modified = Date()
        session.session_res_uri = URL(string: "https://datatracker.ietf.org/api/v1/meeting/session/33001/")
        session.meeting = meeting
        session.group = group
        session.location = location
        return session
    }()

    /// Formats session times as "HHmm" in the meeting's time zone, like ContentView does.
    static let timerangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmm"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(identifier: "Europe/Vienna")
        return formatter
    }()

    private static func date(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(identifier: "Europe/Vienna")
        return formatter.date(from: string)
    }
}
#endif
