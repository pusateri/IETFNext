//
//  Load.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import Foundation

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

public struct CustomTimeInterval: Codable {
    let value: TimeInterval
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        self.value = text.convertToTimeInterval()
    }
}

public protocol HasDateFormatter {
    static var dateFormatter: DateFormatter { get }
}

public struct CustomDate<E:HasDateFormatter>: Codable {

    let value: Date
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let date = E.dateFormatter.date(from: text) else {
            throw CustomDateError.general
        }
        self.value = date
    }
    enum CustomDateError: Error {
        case general
    }

}

public struct RFC3339Date: HasDateFormatter {
    public static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }
}

public enum Schedule {
    case location(Location)
    case parent(Parent)
    case session(Session)
}

public enum ObjectType: String, Decodable {
    case location
    case parent
    case session
}

public enum Status: String, Decodable {
    case canceled
    case resched
    case sched
}

public struct Location: Decodable {
    public let id: Int
    public let level_name: String?
    public let level_sort: Int?
    public let map: String?
    public let modified: CustomDate<RFC3339Date>
    public let name: String
    public let objtype: ObjectType
    public let x: Float?
    public let y: Float?
}

public struct Parent: Decodable {
    public let id: Int
    public let description: String
    public let modified: CustomDate<RFC3339Date>
    public let name: String
    public let objtype: ObjectType
}

public struct Session: Decodable {
    public let agenda: String?
    public let duration: CustomTimeInterval
    public let group: Group
    public let id: Int
    public let is_bof: Bool
    public let location: String
    public let minutes: String?
    public let modified: CustomDate<RFC3339Date>
    public let name: String
    public let objtype: ObjectType
    public let presentations: [Presentation]?
    public let session_id: Int
    public let session_res_uri: String
    public let start: CustomDate<RFC3339Date>
    public let status: Status
}

public struct Presentation: Decodable {
    public let name: String
    public let order: Int
    public let resource_uri: String
    public let rev: String
    public let title: String
}

public enum GroupState: String, Decodable {
    case active
    case bof
    case proposed
}

public struct Group: Decodable {
    public let acronym: String
    public let name: String
    public let parent: String?
    public let state: GroupState
    public let type: String
}

extension Schedule: Decodable {
    private enum CodingKeys: String, CodingKey {
        case objtype = "objtype"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleContainer = try decoder.singleValueContainer()

        let type = try container.decode(String.self, forKey: .objtype)
        switch type {
        case "location":
            let location = try singleContainer.decode(Location.self)
            self = .location(location)
        case "parent":
            let parent = try singleContainer.decode(Parent.self)
            self = .parent(parent)
        case "session":
            let session = try singleContainer.decode(Session.self)
            print(session)
            self = .session(session)
        default:
            fatalError("Unknown type of content.")
            // or handle this case properly
        }
    }
}

public func loadData(meeting: String) async {
    guard let url = URL(string: "https://datatracker.ietf.org/meeting/\(meeting)/agenda.json") else {
        print("Invalid URL")
        return
    }
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        do {
            let decoder = JSONDecoder()
            let messages = try decoder.decode([String:[Schedule]].self, from: data)
            let objs = messages[meeting] ?? []
            for obj in objs {
                print(obj)
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
