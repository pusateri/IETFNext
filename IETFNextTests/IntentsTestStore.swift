//
//  IntentsTestStore.swift
//  IETFNextTests
//
//  Created by Tom Pusateri on 10/2/26.
//

import Foundation
import CoreData
@testable import IETFNext

/// An in-memory Core Data store and a private `UserDefaults` suite for one test, so tests
/// don't touch the app's data or its chosen meeting and can run in parallel.
@MainActor
final class IntentsTestStore {
    let container: NSPersistentContainer
    let defaults: UserDefaults
    let dataStore: IntentDataStore
    private let suiteName: String

    var context: NSManagedObjectContext { container.viewContext }

    /// The meeting's time zone, also used to build the sample dates.
    static let viennaTimeZone = TimeZone(identifier: "Europe/Vienna")!

    static var viennaCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = viennaTimeZone
        return calendar
    }

    init(meetingNumber: String? = "126", useLocalTime: Bool = false) throws {
        // Reuse the app's model so the entity classes aren't claimed by two models.
        let model = RFCProvider.shared.container.managedObjectModel
        container = NSPersistentContainer(name: "IETFNextTests", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            throw loadError
        }

        suiteName = "IETFNextTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw CocoaError(.featureUnsupported)
        }
        self.defaults = defaults
        defaults.set(meetingNumber, forKey: IntentDataStore.meetingNumberKey)
        defaults.set(useLocalTime, forKey: IntentDataStore.useLocalTimeKey)
        dataStore = IntentDataStore(container: container, defaults: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    /// A date in Vienna, for example `vienna("2026-07-23 09:30")`.
    static func vienna(_ text: String) -> Date {
        let parts = text.split(separator: " ")
        let day = parts[0].split(separator: "-").compactMap { Int($0) }
        let time = parts[1].split(separator: ":").compactMap { Int($0) }
        let components = DateComponents(year: day[0], month: day[1], day: day[2], hour: time[0], minute: time[1])
        return viennaCalendar.date(from: components)!
    }

    // MARK: - Builders

    @discardableResult
    func meeting(_ number: String = "126") -> Meeting {
        let meeting = Meeting(context: context)
        meeting.number = number
        meeting.city = "Vienna"
        meeting.country = "AT"
        meeting.date = "2026-07-18"
        meeting.time_zone = Self.viennaTimeZone.identifier
        meeting.venue_name = "Austria Center Vienna"
        meeting.start = Self.vienna("2026-07-18 09:00")
        return meeting
    }

    @discardableResult
    func group(_ acronym: String, name: String? = nil, favorite: Bool = false) -> Group {
        let group = Group(context: context)
        group.acronym = acronym
        group.name = name ?? acronym.uppercased()
        group.areaKey = "art"
        group.state = "active"
        group.type = "wg"
        group.favorite = favorite
        return group
    }

    @discardableResult
    func location(_ id: Int32, name: String, floor: String, meeting: Meeting) -> Location {
        let location = Location(context: context)
        location.id = id
        location.name = name
        location.level_name = floor
        location.modified = Date()
        location.meeting = meeting
        return location
    }

    @discardableResult
    func session(_ id: Int32, group: Group?, start: String, end: String, meeting: Meeting, location: Location? = nil, status: String = "sched") -> Session {
        let session = Session(context: context)
        session.id = id
        session.session_id = id
        session.name = group?.name ?? "Session \(id)"
        session.status = status
        session.is_bof = false
        session.start = Self.vienna(start)
        session.end = Self.vienna(end)
        session.modified = Date()
        session.session_res_uri = URL(string: "https://datatracker.ietf.org/api/v1/meeting/session/\(id)/")
        session.meeting = meeting
        session.group = group
        session.location = location
        return session
    }

    @discardableResult
    func rfc(_ number: Int, title: String, published: String) -> RFC {
        let rfc = RFC(context: context)
        rfc.name = RFCEntity.name(forNumber: number)
        rfc.title = title
        rfc.published = Self.vienna(published)
        return rfc
    }

    func save() throws {
        try context.save()
    }
}
