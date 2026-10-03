//
//  SessionEntity.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents
import CoreData
import CoreSpotlight

/// A scheduled session at an IETF meeting, as seen by Siri, Shortcuts, and Spotlight.
///
/// The `id` is the Datatracker schedule ID (`Session.id`), which is stable across launches
/// and devices. Saved shortcuts store it, so don't change what it means.
struct SessionEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Session",
        numericFormat: "\(placeholder: .int) sessions"
    )
    static let defaultQuery = SessionEntityQuery()

    let id: Int

    @Property(title: "Name", indexingKey: \.title)
    var name: String

    @Property(title: "Group")
    var groupAcronym: String

    @Property(title: "Group Name", indexingKey: \.contentDescription)
    var groupName: String

    @Property(title: "Start")
    var start: Date

    @Property(title: "End")
    var end: Date

    @Property(title: "Room")
    var room: String?

    @Property(title: "Floor")
    var floor: String?

    @Property(title: "BoF")
    var isBoF: Bool

    /// The meeting number, for example "125".
    let meetingNumber: String

    /// The room's `Location.id`, used to show its floor map.
    let locationID: Int?

    /// The time zone the app shows times in: the meeting's, or the device's when the
    /// person turned on Use Local Time.
    let timeZone: TimeZone

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name) (\(groupAcronym))",
            subtitle: "\(timeRange) · \(room ?? "Unspecified")"
        )
    }

    /// For example "Mon 10:00 – 11:30", in `timeZone`.
    var timeRange: String {
        "\(startDescription) – \(end.formatted(timeStyle))"
    }

    /// The start day and time, for example "Mon 10:00", in `timeZone`.
    var startDescription: String {
        var day = Date.FormatStyle.dateTime.weekday(.abbreviated).hour().minute()
        day.timeZone = timeZone
        return start.formatted(day)
    }

    /// The start time only, for example "10:00", in `timeZone`.
    var startTime: String {
        start.formatted(timeStyle)
    }

    /// The room and floor, for example "Grand Park Hall 2, Mezzanine Level".
    var place: String? {
        guard let room else {
            return nil
        }
        return [room, floor].compactMap(\.self).joined(separator: ", ")
    }

    private var timeStyle: Date.FormatStyle {
        var time = Date.FormatStyle.dateTime.hour().minute()
        time.timeZone = timeZone
        return time
    }

    /// Returns `nil` for sessions the schedule list doesn't show (no group or no times).
    init?(session: Session, timeZone: TimeZone) {
        guard let acronym = session.group?.acronym,
              let start = session.start,
              let end = session.end,
              let meetingNumber = session.meeting?.number else {
            return nil
        }
        self.id = Int(session.id)
        self.meetingNumber = meetingNumber
        self.locationID = session.location.map { Int($0.id) }
        self.timeZone = timeZone
        self.name = session.name ?? acronym
        self.groupAcronym = acronym
        self.groupName = session.group?.name ?? acronym
        self.start = start
        self.end = end
        self.room = session.location?.name
        self.floor = session.location?.level_name
        self.isBoF = session.is_bof
    }
}
