//
//  MeetingListRowView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/29/22.
//

import SwiftUI
import CoreData

struct MeetingListRowView: View {
    var meeting: Meeting
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("IETF \(meeting.number!)")
                    .foregroundColor(.primary)
                    .font(.title3.bold())
                Spacer()
                Text("\(meeting.date!)")
                    .foregroundColor(.primary)
            }
            HStack {
                Text("\(meeting.city!)")
                    .foregroundColor(.secondary)
                Spacer()
                Text("(\(meeting.time_zone!))")
                    .foregroundColor(.secondary)
            }
        }
    }
}

func makeMeeting(context: NSManagedObjectContext) -> Meeting {
    let mtg = Meeting(context: context)
    mtg.number = "115"
    mtg.city = "Yokohama"
    mtg.country = "JP"
    mtg.date = "2023-03-25"
    mtg.time_zone = "Asia/Tokyo"
    mtg.venue_addr = "1 Chome-1-1 Minatomirai, Nishi Ward, \r\nYokohama, Kanagawa 220-0012, Japan"
    mtg.venue_name = "PACIFICO"
    return mtg
}

struct MeetingListRowView_Previews: PreviewProvider {
    static var mtg = Meeting()
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let mtg = makeMeeting(context: context)

        MeetingListRowView(meeting: mtg)
            .environment(\.managedObjectContext, context)
    }
}
