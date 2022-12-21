//
//  Load.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI
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

struct Meta: Decodable {
    let limit: Int32
    let next: String?
    let offset: Int32
    let previous: String?
    let total_count: Int32
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

/*
 * session status options:
 * appr : Approved
 * canceled : Cancelled
 * canceledpa : Cancelled - Pre Announcement
 * deleted : Deleted
 * disappr : Disapproved
 * notmeet : Not meeting
 * resched : Rescheduled
 * sched : Scheduled
 * scheda : Scheduled - Announcement to be sent
 * apprw : Waiting for Approval
 * schedw : Waiting for Scheduling
 */

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
    let status: String?
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

// Documents like internet drafts, RFCs
struct Documents: Decodable {
    let meta: Meta
    let objects: [JSONDocument]
}

struct JSONDocument: Decodable {
    let abstract: String?
    let ad: String?
    let expires: Date?
    let external_url: String?
    let group: String?
    let id: Int32
    let intended_std_level: String?
    let internal_comments: String?
    let name: String
    let note: String?
    let notify: String?
    let order: Int32
    let pages: Int32?
    let resource_uri: String
    let rev: String
    let rfc: String?
    let shepherd: String?
    let states: [String]?
    let std_level: String?
    let stream: String?
    let submissions: [String]?
    let tags: [String]?
    let time: Date?
    let title: String
    let type: String
    let uploaded_filename: String?
    let words: Int32?
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

public func findSessionsForGroup(context: NSManagedObjectContext, meeting: Meeting, group: Group) -> [Session]? {

    let fetchSession: NSFetchRequest<Session> = Session.fetchRequest()
    fetchSession.predicate = NSPredicate(format: "meeting = %@ AND group = %@", meeting, group)
    fetchSession.sortDescriptors = [
        NSSortDescriptor(keyPath: \Session.start, ascending: true)
        ]
    return try? context.fetch(fetchSession)
}

public func loadData(meeting: Meeting, context: NSManagedObjectContext) async {
    let baseURL = URL(string: "https://datatracker.ietf.org")
    guard let url = URL(string: "/meeting/\(meeting.number!)/agenda.json", relativeTo:baseURL) else {
        print("Invalid URL")
        return
    }
    do {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: Locale.current.identifier)
        dayFormatter.dateFormat = "yyyy-MM-dd EEEE"
        dayFormatter.calendar = Calendar(identifier: .iso8601)
        dayFormatter.timeZone = TimeZone(identifier: meeting.time_zone!)

        let rangeFormatter = DateFormatter()
        rangeFormatter.locale = Locale(identifier: Locale.current.identifier)
        rangeFormatter.dateFormat = "HHmm"
        rangeFormatter.calendar = Calendar(identifier: .iso8601)
        rangeFormatter.timeZone = TimeZone(identifier: meeting.time_zone!)

        let (data, _) = try await URLSession.shared.data(from: url)
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.rfc3339)
            let messages = try decoder.decode([String:[Schedule]].self, from: data)
            let objs = messages[meeting.number!] ?? []

            // first pass get dependencies
            context.performAndWait {
                for obj in objs {
                    switch(obj) {
                    case .location(let loc):
                        updateLocation(context:context, meeting:meeting, location:loc)
                    case .parent(let area):
                        updateArea(context:context, parent:area)
                    case .session(_):
                        continue
                    }
                }
            }
            // second pass get sessions
            context.performAndWait {
                for obj in objs {
                    switch(obj) {
                    case .location(_):
                        continue
                    case .parent(_):
                        continue
                    case .session(let JSONsession):
                        if let baseURL = baseURL {
                            updateSession(context:context, baseURL: baseURL, dayFormatter:dayFormatter, rangeFormatter:rangeFormatter, meeting:meeting, session:JSONsession)
                        }
                    }
                }
            }
        } catch DecodingError.dataCorrupted(let context) {
            print("schedule \(meeting.number!), ")
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

public func loadDrafts(context: NSManagedObjectContext, limit: Int32, offset: Int32, group: Group) async {
    let url: URL
    let urlString = "https://datatracker.ietf.org/api/v1/doc/document/?group__acronym=\(group.acronym!)&type=draft&states__slug__contains=active"

    if offset == 0 {
        guard let url0 = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        url = url0
    } else {
        guard let url_offset = URL(string: urlString + "limit=\(limit)&offset=\(offset)") else {
            print("Invalid URL")
            return
        }
        url = url_offset
    }
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.rfc3339)
            let json_docs = try decoder.decode(Documents.self, from: data)

            context.performAndWait {
                group.documents = Set<Group>() as NSSet
                for obj in json_docs.objects {
                    updateDocument(context:context, group:group, kind:.draft, document:obj)
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
        print("Unexpected Meeting format")
    }
}

// For when we add RFCs
// This has some duplicates in it. Not sure why.
// What we really want is "states": ["/api/v1/doc/state/3/",
// http://datatracker.ietf.org/api/v1/doc/document/?name__regex=draft-ietf-ippm-*&type=draft&states__slug__contains=rfc&limit=85

public func loadRelatedDrafts(context: NSManagedObjectContext, limit: Int32, offset: Int32, group: Group) async {
    let url: URL
    let urlString = "https://datatracker.ietf.org/api/v1/doc/document/?name__regex=draft-(?!ietf-\(group.acronym!))[A-Za-z0-9]*-\(group.acronym!)-*&type=draft&states__slug__contains=active"

    if offset == 0 {
        guard let url0 = URL(string: urlString) else {
            print("Invalid Related Draft URL")
            return
        }
        url = url0
    } else {
        guard let url_offset = URL(string: urlString + "limit=\(limit)&offset=\(offset)") else {
            print("Invalid Related Draft URL offset")
            return
        }
        url = url_offset
    }
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.rfc3339)
            let json_docs = try decoder.decode(Documents.self, from: data)

            context.performAndWait {
                group.relatedDocs = Set<Group>() as NSSet
                for obj in json_docs.objects {
                    if !obj.name.starts(with: "draft-ietf-\(group.acronym!)") {
                        updateDocument(context:context, group:group, kind:.related, document:obj)
                    }
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
        print("Unexpected Meeting format")
    }
}

public func loadRecordingDocument(context: NSManagedObjectContext, selectedSession: Binding<Session?>) async {
    if let session = selectedSession.wrappedValue {
        if let meeting = session.meeting {
            if let group = session.group {
                let urlString = "https://datatracker.ietf.org/api/v1/doc/document/?name__contains=recording-\(meeting.number!)&external_url__contains=youtube&group__acronym=\(group.acronym!)"

                guard let url = URL(string: urlString) else {
                    print("Invalid URL: \(urlString)")
                    return
                }
                do {
                    // 2022-11-09 at 13:00:00
                    let recFormatter = DateFormatter()
                    recFormatter.locale = Locale(identifier: Locale.current.identifier)
                    recFormatter.dateFormat = "yyyy-MM-dd' at 'HH:mm:ss"
                    recFormatter.calendar = Calendar(identifier: .iso8601)
                    recFormatter.timeZone = TimeZone(identifier: meeting.time_zone!)
                    let matchTitle = String(format: "Video recording for \(group.acronym!.uppercased()) on \(recFormatter.string(from: session.start!))")
                    let (data, _) = try await URLSession.shared.data(from: url)
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .formatted(DateFormatter.rfc3339)
                        let json_docs = try decoder.decode(Documents.self, from: data)

                        for obj in json_docs.objects {
                            if obj.title == matchTitle {
                                if let external_url = obj.external_url {
                                    guard let recording_url = URL(string: external_url) else {
                                        print("Invalid External recording URL: \(external_url)")
                                        return
                                    }
                                    context.performAndWait {
                                        session.recording = recording_url
                                        do {
                                            try context.save()
                                        }
                                        catch {
                                            print("Unable to save recording in Session: \(session.name!)")
                                        }
                                    }
                                }
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
                    print("Unexpected recording format")
                }
            }
        }
    }
}

public func loadCharterDocument(context: NSManagedObjectContext, group: Group) async {
    let urlString = "https://datatracker.ietf.org/api/v1/doc/document/charter-ietf-\(group.acronym!)/"

    guard let url = URL(string: urlString) else {
        print("Invalid URL: \(urlString)")
        return
    }
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.rfc3339)
            let json_doc = try decoder.decode(JSONDocument.self, from: data)

            context.performAndWait {
                updateDocument(context:context, group:group, kind:.charter, document:json_doc)
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
        print("Unexpected Meeting format")
    }
}

private func updateDocument(context: NSManagedObjectContext, group: Group, kind: DocumentKind, document: JSONDocument) {
    let fetchDocument: NSFetchRequest<Document> = Document.fetchRequest()
    fetchDocument.predicate = NSPredicate(format: "id = %d", document.id)

    var doc: Document!
    var save = false
    let results = try? context.fetch(fetchDocument)

    if results?.count == 0 {
        // here you are inserting
        doc = Document(context: context)
        doc.id = document.id
        save = true
    } else {
        // here you are updating
        doc = results?.first
    }

    if let abstract = document.abstract {
        if doc.abstract != abstract {
            doc.abstract = abstract
            save = true
        }
    }
    if let ad = document.ad {
        if doc.ad != ad {
            doc.ad = ad
            save = true
        }
    }
    if let expires = document.expires {
        if doc.expires != expires {
            doc.expires = expires
            save = true
        }
    }
    if let external_url = document.external_url {
        let url = URL(string: external_url)
        if doc.external_url != url {
            doc.external_url = url
            save = true
        }
    }
    if let group_uri = document.group {
        if doc.group_uri != group_uri {
            doc.group_uri = group_uri
            save = true
        }
    }
    if let intended_std_level = document.intended_std_level {
        if doc.intended_std_level != intended_std_level {
            doc.intended_std_level = intended_std_level
            save = true
        }
    }
    if let internal_comments = document.internal_comments {
        if doc.internal_comments != internal_comments {
            doc.internal_comments = internal_comments
            save = true
        }
    }
    if doc.name != document.name {
        doc.name = document.name
        save = true
    }
    if let note = document.note {
        if doc.note != note {
            doc.note = note
            save = true
        }
    }
    if let notify = document.notify {
        if doc.notify != notify {
            doc.notify = notify
            save = true
        }
    }
    if doc.order != document.order {
        doc.order = document.order
        save = true
    }
    if let pages = document.pages {
        if doc.pages != pages {
            doc.pages = pages
            save = true
        }
    }
    if doc.resource_uri != document.resource_uri {
        doc.resource_uri = document.resource_uri
        save = true
    }
    if doc.rev != document.rev {
        doc.rev = document.rev
        save = true
    }
    if let rfc = document.rfc {
        if doc.rfc != rfc {
            doc.rfc = rfc
            save = true
        }
    }
    if let shepherd = document.shepherd {
        if doc.shepherd != shepherd {
            doc.shepherd = shepherd
            save = true
        }
    }
    if let std_level = document.std_level {
        if doc.std_level != std_level {
            doc.std_level = std_level
            save = true
        }
    }
    if let stream = document.stream {
        if doc.stream != stream {
            doc.stream = stream
            save = true
        }
    }
    if let time = document.time {
        if doc.time != time {
            doc.time = time
            save = true
        }
    }
    if doc.title != document.title {
        doc.title = document.title
        save = true
    }
    if doc.type != document.type {
        doc.type = document.type
        save = true
    }
    if let uploaded_filename = document.uploaded_filename {
        if doc.uploaded_filename != uploaded_filename {
            doc.uploaded_filename = uploaded_filename
            save = true
        }
    }
    if let words = document.words {
        if doc.words != words {
            doc.words = words
            save = true
        }
    }
    /*
        Ignoring array of strings items:
            states, submissions, tags
     */

    // associate document with working group
    switch(kind) {
    case .charter, .draft:
        if doc.group != group {
            doc.group = group
            save = true
        }
    case .related:
        if doc.relatedGroup != group {
            doc.relatedGroup = group
            save = true
        }
    case .rfc:
        if doc.rfcGroup != group {
            doc.rfcGroup = group
            save = true
        }
    }

    if save {
        do {
            try context.save()
        }
        catch {
            print("Unable to save Document \(document.name)")
        }
    }
}

private func updateLocation(context: NSManagedObjectContext, meeting:Meeting, location: JSONLocation) {
    let fetchLocation: NSFetchRequest<Location> = Location.fetchRequest()
    fetchLocation.predicate = NSPredicate(format: "id = %d", location.id)

    var loc: Location!
    var save = false
    let results = try? context.fetch(fetchLocation)

    if results?.count == 0 {
        // here you are inserting
        loc = Location(context: context)
        loc.id = location.id
        loc.meeting = meeting
        save = true
    } else {
        // here you are updating
        loc = results?.first
    }

    if loc.name != location.name {
        loc.name = location.name
        save = true
    }
    if let level_name = location.level_name {
        if loc.level_name != level_name {
            loc.level_name = level_name
            save = true
        }
    } else {
        if loc.level_name != "Uncategorized" {
            loc.level_name = "Uncategorized"
            save = true
        }
    }
    if let level_sort = location.level_sort {
        if loc.level_sort != level_sort {
            loc.level_sort = level_sort
            save = true
        }
    } else {
        if loc.level_sort != 0 {
            loc.level_sort = 0
            save = true
        }
    }
    if let map = location.map {
        let url = URL(string: map)
        if loc.map != url {
            loc.map = url
            save = true
        }
    }
    if loc.modified != location.modified {
        loc.modified = location.modified
        save = true
    }
    if let x = location.x {
        if loc.x != x {
            loc.x = x
            save = true
        }
    } else {
        if loc.x != 0.0 {
            loc.x = 0.0
            save = true
        }
    }
    if let y = location.y {
        if loc.y != y {
            loc.y = y
            save = true
        }
    } else {
        if loc.y != 0.0 {
            loc.y = 0.0
            save = true
        }
    }

    if save {
        do {
            try context.save()
        }
        catch {
            print("Unable to save Location \(location.name)")
        }
    }
}

private func updateArea(context: NSManagedObjectContext, parent: Parent) {

    let fetchArea: NSFetchRequest<Area> = Area.fetchRequest()
    fetchArea.predicate = NSPredicate(format: "name = %@", parent.name)

    var area: Area!
    var save = false
    let results = try? context.fetch(fetchArea)

    if results?.count == 0 {
        // here you are inserting
        area = Area(context: context)
        area.name = parent.name
        save = true
    } else {
        // here you are updating
        area = results?.first
    }

    if area.id != parent.id {
        area.id = parent.id
        save = true
    }
    if area.desc != parent.description {
        area.desc = parent.description
        save = true
    }
    if area.modified != parent.modified {
        area.modified = parent.modified
        save = true
    }

    if save {
        do {
            try context.save()
        }
        catch {
            print("Unable to save Area \(area.name!)")
        }
    }
}

private func findArea(context: NSManagedObjectContext, name: String) -> Area? {
    let area: Area?

    let fetchArea: NSFetchRequest<Area> = Area.fetchRequest()
    fetchArea.predicate = NSPredicate(format: "name = %@", name)

    let results = try? context.fetch(fetchArea)

    if results?.count == 0 {
        area = nil
    } else {
            // here you are updating
        area = results?.first
    }
    return area
}

private func findLocation(context: NSManagedObjectContext, meeting: Meeting, name: String) -> Location? {
    let location: Location?

    let fetchLocation: NSFetchRequest<Location> = Location.fetchRequest()
    fetchLocation.predicate = NSPredicate(format: "(meeting.number = %@) AND (name = %@)", meeting.number!, name)
    let results = try? context.fetch(fetchLocation)

    if results?.count == 0 {
        location = nil
    } else {
        location = results?.first
    }
    return location
}

private func updateGroup(context: NSManagedObjectContext, group: JSONGroup) -> Group? {
    let g: Group!

    let fetchGroup: NSFetchRequest<Group> = Group.fetchRequest()
    fetchGroup.predicate = NSPredicate(format: "acronym = %@", group.acronym)

    let results = try? context.fetch(fetchGroup)

    if results?.count == 0 {
            // here you are inserting
        g = Group(context: context)
        g.acronym = group.acronym
    } else {
            // here you are updating
        g = results?.first
    }

    if let name = group.parent {
        g.area = findArea(context: context, name: name)
        g.areaKey = name
    } else {
        g.areaKey = "ietf"
    }
    if g.name != group.name {
        g.name = group.name
    }
    if g.state != group.state.rawValue {
        g.state = group.state.rawValue
    }
    if g.type != group.type {
        g.type = group.type
    }
    return g
}

private func updatePresentation(context: NSManagedObjectContext, presentation: JSONPresentation) -> Presentation? {
    let p: Presentation!

    let fetchPresentation: NSFetchRequest<Presentation> = Presentation.fetchRequest()
    fetchPresentation.predicate = NSPredicate(format: "resource_uri = %@", presentation.resource_uri)

    let results = try? context.fetch(fetchPresentation)

    if results?.count == 0 {
        // here you are inserting
        p = Presentation(context: context)
        p.resource_uri = presentation.resource_uri
    } else {
        // here you are updating
        p = results?.first
    }
    if p.name != presentation.name {
        p.name = presentation.name
    }
    if p.order != presentation.order {
        p.order = presentation.order
    }
    if p.title != presentation.title {
        p.title = presentation.title
    }
    if p.rev != presentation.rev {
        p.rev = presentation.rev
    }

    return p
}

private func updateSession(context: NSManagedObjectContext, baseURL: URL, dayFormatter: DateFormatter, rangeFormatter: DateFormatter, meeting: Meeting, session: JSONSession) {

    let fetchSession: NSFetchRequest<Session> = Session.fetchRequest()
    fetchSession.predicate = NSPredicate(format: "id = %d", session.id)

    var s: Session!
    var save = false
    let end = session.start.addingTimeInterval(session.duration.value)
    let start_time = rangeFormatter.string(from: session.start)
    let end_time = rangeFormatter.string(from: end)
    let results = try? context.fetch(fetchSession)

    if results?.count == 0 {
        // here you are inserting
        s = Session(context: context)
        s.id = session.id
        save = true
    } else {
        // here you are updating
        s = results?.first
    }
    let group_obj = updateGroup(context:context, group:session.group)
    if let group_obj = group_obj {
        if s.group != group_obj {
            s.group = group_obj
            save = true
        }
    }
    if let agenda = session.agenda {
        let url = URL(string: agenda)
        if s.agenda != url {
            s.agenda = url
            save = true
        }
    }
    if save || s.is_bof != session.is_bof {
        s.is_bof = session.is_bof
        save = true
    }
    let loc = findLocation(context: context, meeting:meeting, name:session.location)
    if s.location != loc {
        s.location = loc
        save = true
    }
    if let minutes = session.minutes {
        let url = URL(string: minutes)
        if s.minutes != url {
            s.minutes = url
            save = true
        }
    }
    if s.modified != session.modified {
        s.modified = session.modified
        save = true
    }
    if s.name != session.name {
        s.name = session.name
        save = true
    }
    if s.session_id != session.session_id {
        s.session_id = session.session_id
        save = true
    }
    let uri = URL(string: session.session_res_uri, relativeTo:baseURL)
    if s.session_res_uri != uri {
        s.session_res_uri = uri
        save = true
    }
    if s.start != session.start {
        s.start = session.start
        save = true
    }
    if s.end != end {
        s.end = end
        save = true
    }
    let day = dayFormatter.string(from: session.start)
    if s.day != day {
        s.day = day
        save = true
    }
    let timerange = "\(start_time)-\(end_time)"
    if s.timerange != timerange {
        s.timerange = timerange
        save = true
    }
    if s.status != session.status {
        s.status = session.status
        save = true
    }
    if s.meeting != meeting {
        s.meeting = meeting
        save = true
    }

    var new: Set<Presentation> = Set()
    if let new_json = session.presentations {
        for presentation in new_json {
            if let p = updatePresentation(context:context, presentation: presentation) {
                new.insert(p)
            }
        }
    }
    s.presentations = new as NSSet

    if save {
        do {
            try context.save()
        }
        catch {
            print("Unable to save Session or Group \(String(describing: s.name)), \(String(describing: group_obj?.acronym))")
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
