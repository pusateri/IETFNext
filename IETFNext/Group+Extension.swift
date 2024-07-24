//
//  Group+Extension.swift
//  IETFNext
//
//  Created by Tom Pusateri on 7/22/24.
//

import Foundation
import CoreData

extension Group {
    func groupSessionsIn(meeting: Meeting) -> [Session]? {

        let fetchSession: NSFetchRequest<Session> = Session.fetchRequest()
        fetchSession.predicate = NSPredicate(format: "meeting = %@ AND group = %@", meeting, self)
        fetchSession.sortDescriptors = [
            NSSortDescriptor(keyPath: \Session.start, ascending: true)
        ]
        return try? self.managedObjectContext?.fetch(fetchSession)
    }
}
