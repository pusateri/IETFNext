//
//  RFC+CoreDataProperties.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/6/23.
//
//

import Foundation
import CoreData


extension RFC {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RFC> {
        return NSFetchRequest<RFC>(entityName: "RFC")
    }

    @NSManaged public var abstract: String?
    @NSManaged public var acronym: String?
    @NSManaged public var area: String?
    @NSManaged public var currentStatus: String?
    @NSManaged public var doi: String?
    @NSManaged public var draft: String?
    @NSManaged public var errata: URL?
    @NSManaged public var month: Int16
    @NSManaged public var name: String?
    @NSManaged public var pageCount: Int32
    @NSManaged public var publicationStatus: String?
    @NSManaged public var published: Date?
    @NSManaged public var stream: String?
    @NSManaged public var title: String?
    @NSManaged public var year: String?
    @NSManaged public var authors: NSSet?
    @NSManaged public var formats: NSSet?
    @NSManaged public var keywords: NSSet?

}

// MARK: Generated accessors for authors
extension RFC {

    @objc(addAuthorsObject:)
    @NSManaged public func addToAuthors(_ value: Author)

    @objc(removeAuthorsObject:)
    @NSManaged public func removeFromAuthors(_ value: Author)

    @objc(addAuthors:)
    @NSManaged public func addToAuthors(_ values: NSSet)

    @objc(removeAuthors:)
    @NSManaged public func removeFromAuthors(_ values: NSSet)

}

// MARK: Generated accessors for formats
extension RFC {

    @objc(addFormatsObject:)
    @NSManaged public func addToFormats(_ value: DocFormat)

    @objc(removeFormatsObject:)
    @NSManaged public func removeFromFormats(_ value: DocFormat)

    @objc(addFormats:)
    @NSManaged public func addToFormats(_ values: NSSet)

    @objc(removeFormats:)
    @NSManaged public func removeFromFormats(_ values: NSSet)

}

// MARK: Generated accessors for keywords
extension RFC {

    @objc(addKeywordsObject:)
    @NSManaged public func addToKeywords(_ value: Keyword)

    @objc(removeKeywordsObject:)
    @NSManaged public func removeFromKeywords(_ value: Keyword)

    @objc(addKeywords:)
    @NSManaged public func addToKeywords(_ values: NSSet)

    @objc(removeKeywords:)
    @NSManaged public func removeFromKeywords(_ values: NSSet)

}

extension RFC : Identifiable {

}
