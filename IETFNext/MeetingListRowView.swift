//
//  MeetingListRowView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/29/22.
//

import SwiftUI
import CoreData

struct MeetingListRowView: View {
    @ObservedObject var meeting: Meeting

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

