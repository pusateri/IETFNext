//
//  ScheduleListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/27/22.
//

import SwiftUI

struct ScheduleListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Sess.start, ascending: true)],
        animation: .default)
    private var sessions: FetchedResults<Sess>

    var body: some View {
        Text("ScheduleListView")
    }
}

struct ScheduleListView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleListView()
    }
}
