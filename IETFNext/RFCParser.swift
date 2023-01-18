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

private func updateAuthor(context: NSManagedObjectContext, name: String?) -> Author? {
    if let name = name {
        let a: Author!

        let fetchAuthor: NSFetchRequest<Author> = Author.fetchRequest()
        fetchAuthor.predicate = NSPredicate(format: "name = %@", name)

        let results = try? context.fetch(fetchAuthor)

        if results?.count == 0 {
            // here you are inserting
            a = Author(context: context)
            a.name = name
        } else {
            // here you are updating
            a = results?.first
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

private func updateFormat(context: NSManagedObjectContext, format: String?) -> DocFormat? {
    if let format = format {
        let f: DocFormat!

        let fetchFormat: NSFetchRequest<DocFormat> = DocFormat.fetchRequest()
        fetchFormat.predicate = NSPredicate(format: "format = %@", format)

        let results = try? context.fetch(fetchFormat)

        if results?.count == 0 {
            // here you are inserting
            f = DocFormat(context: context)
            f.format = format
        } else {
            // here you are updating
            f = results?.first
        }

        return f
    }
    return nil
}

private func updateKeyword(context: NSManagedObjectContext, key: String?) -> Keyword? {
    if let key = key {
        let k: Keyword!

        let fetchKeyword: NSFetchRequest<Keyword> = Keyword.fetchRequest()
        fetchKeyword.predicate = NSPredicate(format: "key = %@", key)

        let results = try? context.fetch(fetchKeyword)

        if results?.count == 0 {
            // here you are inserting
            k = Keyword(context: context)
            k.key = key
        } else {
            // here you are updating
            k = results?.first
        }

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

func updateRFC(context: NSManagedObjectContext, xml: XML.Accessor, obsoletes: inout [String: [String]], updates: inout [String: [String]]) {
    var up = [String]()
    var ob = [String]()
    guard let name = xml["doc-id"].text else {
        return
    }
    if let _ = findRFC(context: context, name: name) {
        // Since older entries don't change, we just return if we have a match
        return
    }

    let rfc = RFC(context: context)
    rfc.name = name

    for author in xml["author"] {
        if let author_obj = updateAuthor(context: context, name:author["name"].text) {
            if rfc.authors?.contains(author_obj) != nil {
                rfc.addToAuthors(author_obj)
            }
        }
    }
    for format in xml["format"]["file-format"] {
        if let format_obj = updateFormat(context: context, format: format.text) {
            if rfc.formats?.contains(format_obj) != nil {
                rfc.addToFormats(format_obj)
            }
        }
    }
    for keyword in xml["keywords"]["kw"] {
        if let kw_obj = updateKeyword(context: context, key: keyword.text) {
            if rfc.keywords?.contains(kw_obj) != nil {
                rfc.addToKeywords(kw_obj)
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
    do {
        try context.save()
    }
    catch {
        print("Unable to save RFC \(xml["doc-id"].text!)")
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
}
