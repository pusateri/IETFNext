//
//  GroupEntity.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import AppIntents
import CoreData
import CoreSpotlight

/// An IETF working group, research group, or other group.
///
/// The `id` is the group's acronym (for example "quic"), which is unique and stable.
/// Saved shortcuts store it, so don't change what it means.
struct GroupEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Group",
        numericFormat: "\(placeholder: .int) groups"
    )
    static let defaultQuery = GroupEntityQuery()

    let id: String

    @Property(title: "Acronym", indexingKey: \.title)
    var acronym: String

    @Property(title: "Name", indexingKey: \.contentDescription)
    var name: String

    @Property(title: "Area")
    var area: String?

    @Property(title: "Favorite")
    var isFavorite: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(acronym.uppercased())", subtitle: "\(name)")
    }

    init?(group: Group) {
        guard let acronym = group.acronym else {
            return nil
        }
        self.id = acronym
        self.acronym = acronym
        self.name = group.name ?? acronym
        self.area = group.area?.name?.uppercased()
        self.isFavorite = group.favorite
    }
}
