//
//  DynamicFetchRequestView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/19/23.
//

import SwiftUI
import CoreData

struct DynamicFetchRequestView<T: NSManagedObject, Content: View>: View {

        // That will store our fetch request, so that we can loop over it inside the body.
        // However, we don’t create the fetch request here, because we still don’t know what we’re searching for.
        // Instead, we’re going to create custom initializer(s) that accepts filtering information to set the fetchRequest property.
    @FetchRequest var fetchRequest: FetchedResults<T>

        // this is our content closure; we'll call this once the fetch results is available
    let content: (FetchedResults<T>) -> Content

    var body: some View {
        self.content(fetchRequest)
    }

        // This is a generic initializer that allow to provide all filtering information
    init( withPredicate predicate: NSPredicate, andSortDescriptor sortDescriptors: [NSSortDescriptor] = [],  @ViewBuilder content: @escaping (FetchedResults<T>) -> Content) {
        _fetchRequest = FetchRequest<T>(sortDescriptors: sortDescriptors, predicate: predicate)
        self.content = content
    }

        // This initializer allows to provide a complete custom NSFetchRequest
    init( withFetchRequest request:NSFetchRequest<T>,  @ViewBuilder content: @escaping (FetchedResults<T>) -> Content) {
        _fetchRequest = FetchRequest<T>(fetchRequest: request)
        self.content = content
    }
}

