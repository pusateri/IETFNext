//
//  RFCEntity.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents
import CoreData
import CoreSpotlight

/// A published RFC from the RFC Editor index.
///
/// The `id` is the index's `doc-id` (`RFC.name`, for example "RFC9000"), which is stable.
/// Saved shortcuts store it, so don't change what it means.
struct RFCEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "RFC",
        numericFormat: "\(placeholder: .int) RFCs"
    )
    static let defaultQuery = RFCEntityQuery()

    let id: String

    @Property(title: "Number")
    var number: Int

    @Property(title: "Title", indexingKey: \.contentDescription)
    var title: String

    @Property(title: "Status")
    var status: String?

    @Property(title: "Published")
    var published: Date?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "RFC \(number)", subtitle: "\(title)")
    }

    init?(rfc: RFC) {
        guard let name = rfc.name, let number = Self.number(fromName: name) else {
            return nil
        }
        self.id = name
        self.number = number
        self.title = rfc.title ?? name
        self.status = rfc.currentStatus?.capitalized
        self.published = rfc.published
    }

    /// The RFC number in a `doc-id` such as "RFC0791".
    static func number(fromName name: String) -> Int? {
        guard name.hasPrefix("RFC") else {
            return nil
        }
        return Int(name.dropFirst(3))
    }

    /// The `doc-id` for an RFC number: "RFC" followed by at least four digits.
    static func name(forNumber number: Int) -> String {
        let digits = String(number)
        return "RFC" + String(repeating: "0", count: max(0, 4 - digits.count)) + digits
    }

    /// The RFC number in search text such as "9000", "rfc9000", or "RFC 791", or `nil`
    /// if the text isn't just an RFC number.
    static func number(fromSearchText text: String) -> Int? {
        var digits = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if digits.hasPrefix("rfc") {
            digits = String(digits.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        }
        guard !digits.isEmpty, digits.allSatisfy(\.isASCII), let number = Int(digits), number > 0 else {
            return nil
        }
        return number
    }
}
