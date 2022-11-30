//
//  Load.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import Foundation
import CoreData

extension String {
    func convertToTimeInterval() -> TimeInterval {
        guard self != "" else {
            return 0
        }

        var interval:Double = 0

        let parts = self.components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
        }

        return interval
    }
}

struct CustomTimeInterval: Codable {
    let value: TimeInterval
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        self.value = text.convertToTimeInterval()
    }
}

enum Schedule {
    case location(JSONLocation)
    case parent(Parent)
    case session(JSONSession)
}

enum ObjectType: String, Decodable {
    case location
    case parent
    case session
}

enum Status: String, Decodable {
    case canceled
    case resched
    case sched
}

struct JSONLocation: Decodable {
    let id: Int32
    let level_name: String?
    let level_sort: Int32?
    let map: String?
    let modified: Date
    let name: String
    let objtype: ObjectType
    let x: Float?
    let y: Float?
}

struct Parent: Decodable {
    let id: Int32
    let description: String
    let modified: Date
    let name: String
    let objtype: ObjectType
}

struct JSONSession: Decodable {
    let agenda: String?
    let duration: CustomTimeInterval
    let group: JSONGroup
    let id: Int32
    let is_bof: Bool
    let location: String
    let minutes: String?
    let modified: Date
    let name: String
    let objtype: ObjectType
    let presentations: [JSONPresentation]?
    let session_id: Int32
    let session_res_uri: String
    let start: Date
    let status: Status
}

struct JSONPresentation: Decodable {
    let name: String
    let order: Int32
    let resource_uri: String
    let rev: String
    let title: String
}

enum GroupState: String, Decodable {
    case active
    case bof
    case proposed
}

struct JSONGroup: Decodable {
    let acronym: String
    let name: String
    let parent: String?
    let state: GroupState
    let type: String
}

extension Schedule: Decodable {
    private enum CodingKeys: String, CodingKey {
        case objtype = "objtype"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleContainer = try decoder.singleValueContainer()

        let type = try container.decode(String.self, forKey: .objtype)
        switch type {
        case "location":
            let location = try singleContainer.decode(JSONLocation.self)
            self = .location(location)
        case "parent":
            let parent = try singleContainer.decode(Parent.self)
            self = .parent(parent)
        case "session":
            let session = try singleContainer.decode(JSONSession.self)
            self = .session(session)
        default:
            fatalError("Unknown type of content.")
            // or handle this case properly
        }
    }
}

private extension DateFormatter {
    static let rfc3339: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

public func loadData(meeting: Meeting, context: NSManagedObjectContext) async {
    guard let url = URL(string: "https://datatracker.ietf.org/meeting/\(meeting.number!)/agenda.json") else {
        print("Invalid URL")
        return
    }
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.rfc3339)
            let messages = try decoder.decode([String:[Schedule]].self, from: data)
            let objs = messages[meeting.number!] ?? []
            // first pass get dependencies
            for obj in objs {
                switch(obj) {
                case .location(let loc):
                    updateLocation(context:context, location:loc)
                case .parent(let area):
                    updateArea(context:context, parent:area)
                case .session(_):
                    continue
                }
            }
            // second pass get sessions
            for obj in objs {
                switch(obj) {
                case .location(_):
                    continue
                case .parent(_):
                    continue
                case .session(let session):
                    updateSession(context:context, meeting:meeting, session:session)
                }
            }
        } catch DecodingError.dataCorrupted(let context) {
            print(context)
        } catch DecodingError.keyNotFound(let key, let context) {
            print("Key '\(key)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch DecodingError.valueNotFound(let value, let context) {
            print("Value '\(value)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch DecodingError.typeMismatch(let type, let context) {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch {
            print("error: ", error)
        }
    } catch {
        print("Unexpected agenda format")
    }
}

private func updateLocation(context: NSManagedObjectContext, location: JSONLocation) {
    let loc: Location!

    let fetchLocation: NSFetchRequest<Location> = Location.fetchRequest()
    fetchLocation.predicate = NSPredicate(format: "id = %d", location.id)

    let results = try? context.fetch(fetchLocation)

    if results?.count == 0 {
        // here you are inserting
        loc = Location(context: context)
    } else {
        // here you are updating
        loc = results?.first
    }

    loc.id = location.id
    loc.name = location.name
    loc.level_name = location.level_name ?? "Uncategorized"
    loc.level_sort = location.level_sort ?? 0
    loc.map = location.map
    loc.modified = location.modified
    loc.x = location.x ?? 0.0
    loc.y = location.y ?? 0.0

    do {
        try context.save()
    }
    catch {
        print("Unable to save Location \(location.name)")
    }
}

private func updateArea(context: NSManagedObjectContext, parent: Parent) {
    let area: Area!

    let fetchArea: NSFetchRequest<Area> = Area.fetchRequest()
    fetchArea.predicate = NSPredicate(format: "name = %@", parent.name)

    let results = try? context.fetch(fetchArea)

    if results?.count == 0 {
        // here you are inserting
        area = Area(context: context)
    } else {
        // here you are updating
        area = results?.first
    }

    area.id = parent.id
    area.desc = parent.description
    area.modified = parent.modified
    area.name = parent.name

    do {
        try context.save()
    }
    catch {
        print("Unable to save Area \(area.name!)")
    }
}

private func updateSession(context: NSManagedObjectContext, meeting: Meeting, session: JSONSession) {
    let s: Session!

    let fetchSession: NSFetchRequest<Session> = Session.fetchRequest()
    fetchSession.predicate = NSPredicate(format: "id = %d", session.id)

    let results = try? context.fetch(fetchSession)

    if results?.count == 0 {
        // here you are inserting
        s = Session(context: context)
    } else {
        // here you are updating
        s = results?.first
    }

    //s.agenda = session.agenda
    //s.duration = session.duration
    //s.group = Group()
    s.id = session.id
    s.is_bof = session.is_bof
    //s.location = Location()
    //s.minutes = session.minutes
    s.modified = session.modified
    s.name = session.name
    //s.presentations: [JSONPresentation]?
    s.session_id = session.session_id
    //s.session_res_uri = session.session_res_uri
    s.start = session.start
    //s.status = session.status
    s.meeting = meeting

    do {
        try context.save()
    }
    catch {
        print("Unable to save Session \(s.id)")
    }
}
