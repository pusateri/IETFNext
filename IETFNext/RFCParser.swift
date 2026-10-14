//
//  RFCParser.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/2/23.
//

import SwiftUI
import CoreData
import SwiftyXMLParser


enum RFCFormat: String {
    case ASCII
    case HTML
    case XML
}

private extension DateFormatter {
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

/// In-memory lookup tables used during a bulk RFC import. Fetching each table once up front
/// avoids running a fetch request (a full table scan, since these attributes are unindexed)
/// for every RFC, author, format and keyword in the index.
final class RFCImportCache {
    var rfcs: [String: RFC] = [:]
    var authors: [String: Author] = [:]
    var formats: [String: DocFormat] = [:]
    var keywords: [String: Keykeyword] = [:]

    init(context: NSManagedObjectContext) {
        rfcs = Self.load(RFC.fetchRequest(), context: context, key: \.name)
        authors = Self.load(Author.fetchRequest(), context: context, key: \.name)
        formats = Self.load(DocFormat.fetchRequest(), context: context, key: \.format)
        keywords = Self.load(Keykeyword.fetchRequest(), context: context, key: \.key)
    }

    private static func load<T: NSManagedObject>(_ request: NSFetchRequest<T>, context: NSManagedObjectContext, key: KeyPath<T, String?>) -> [String: T] {
        let results = (try? context.fetch(request)) ?? []
        var map: [String: T] = [:]
        map.reserveCapacity(results.count)
        for object in results {
            if let k = object[keyPath: key], map[k] == nil {
                map[k] = object
            }
        }
        return map
    }
}

private func updateAuthor(context: NSManagedObjectContext, cache: RFCImportCache, name: String?) -> Author? {
    if let name = name {
        let a: Author

        if let existing = cache.authors[name] {
            a = existing
        } else {
            a = Author(context: context)
            a.name = name
            cache.authors[name] = a
        }
        /*
         * this is too naive

        let parts = name.components(separatedBy: " ")
        if a.firstInitial != parts[0] {
            a.firstInitial = parts[0]
        }
        if a.surname != parts[1] {
            a.surname = parts[1]
        }
        let sName = "\(parts[1]), \(parts[0])"
        if a.sortName != sName {
            a.sortName = sName
        }
         */
        return a
    }
    return nil
}

private func updateFormat(context: NSManagedObjectContext, cache: RFCImportCache, format: String?) -> DocFormat? {
    if let format = format {
        if let existing = cache.formats[format] {
            return existing
        }
        let f = DocFormat(context: context)
        f.format = format
        cache.formats[format] = f
        return f
    }
    return nil
}

private func updateKeyword(context: NSManagedObjectContext, cache: RFCImportCache, key: String?) -> Keykeyword? {
    if let key = key {
        if let existing = cache.keywords[key] {
            return existing
        }
        let k = Keykeyword(context: context)
        k.key = key
        cache.keywords[key] = k
        return k
    }
    return nil
}

func findRFC(context: NSManagedObjectContext, name: String) -> RFC? {
    let fetchRFC: NSFetchRequest<RFC> = RFC.fetchRequest()

    fetchRFC.predicate = NSPredicate(format: "name = %@", name)

    let results = try? context.fetch(fetchRFC)
    return results?.first
 }

func updateRFC(context: NSManagedObjectContext, cache: RFCImportCache, xml: XML.Accessor, obsoletes: inout [String: [String]], updates: inout [String: [String]]) {
    var up = [String]()
    var ob = [String]()
    guard let name = xml["doc-id"].text else {
        return
    }
    if cache.rfcs[name] != nil {
        // Since older entries don't change, we just return if we have a match
        return
    }

    let rfc = RFC(context: context)
    rfc.name = name
    cache.rfcs[name] = rfc

    for author in xml["author"] {
        if let author_obj = updateAuthor(context: context, cache: cache, name:author["name"].text) {
            if rfc.authors?.contains(author_obj) != nil {
                rfc.addToAuthors(author_obj)
            }
        }
    }
    for format in xml["format"]["file-format"] {
        if let format_obj = updateFormat(context: context, cache: cache, format: format.text) {
            if rfc.formats?.contains(format_obj) != nil {
                rfc.addToFormats(format_obj)
            }
        }
    }
    for keyword in xml["keywords"]["kw"] {
        if let kw_obj = updateKeyword(context: context, cache: cache, key: keyword.text) {
            if rfc.keykeywords?.contains(kw_obj) != nil {
                rfc.addToKeykeywords(kw_obj)
            }
        }
    }
    // TODO: need to add see-also?
    for docid in xml["obsoletes"]["doc-id"] {
        if let name = docid.text {
            ob.append(name)
        }
    }
    if ob.count > 0 {
        obsoletes[name] = ob
    }

    for docid in xml["updates"]["doc-id"] {
        if let name = docid.text {
            up.append(name)
        }
    }
    if up.count > 0 {
        updates[name] = up
    }
    // create a date object from month and year
    // and also keep them separate as int objects for section sorting
    if let month = xml["date"]["month"].text {
        if let year = xml["date"]["year"].text {
            if let pubDate = DateFormatter.monthYearFormatter.date(from: month + " " + year) {
                rfc.published = pubDate
                let number = DateFormatter.monthFormatter.string(from: pubDate)
                if let number = Int16(number) {
                    rfc.month = number
                }
                rfc.year = year
            }
        }
    }
    // make sure rfc.published is set
    if rfc.published == nil {
        return
    }

    if let abstract = xml.abstract.text {
        rfc.abstract = abstract
    }
    if let area = xml.area.text {
        rfc.area = area
    }
    if let status = xml["current-status"].text {
        rfc.currentStatus = status
    }
    if let doi = xml.doi.text {
        rfc.doi = doi
    }
    if let draft = xml.draft.text {
        rfc.draft = draft
    }
    if let errata = xml["errata-url"].text {
        if let url = URL(string: errata) {
            rfc.errata = url
        }
    }
    if let pages = xml["page-count"].int {
        rfc.pageCount = Int32(pages)
    }
    if let status = xml["publication-status"].text {
        rfc.publicationStatus = status
    }
    if let stream = xml.stream.text {
        rfc.stream = stream
    }
    if let title = xml.title.text {
        rfc.title = title
    }
    if let wg = xml.wg_acronym.text {
        rfc.acronym = wg
    }
    for docid in xml["is-also"]["doc-id"] {
        if let name = docid.text {
            if name.starts(with: "BCP") {
                rfc.bcp = name
            } else if name.starts(with: "FYI") {
                rfc.fyi = name
            } else if name.starts(with: "STD") {
                rfc.std = name
            }
        }
    }
    // Saving is done in bulk by the caller rather than once per RFC.
}
