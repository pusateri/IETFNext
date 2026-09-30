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
                    .foregroundStyle(.primary)
                    .font(.title3.bold())
                Spacer()
                Text("\(meeting.date!)")
                    .foregroundStyle(.primary)
            }
            HStack {
                Text("\(meeting.city!)")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("(\(meeting.time_zone!))")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#if DEBUG
#Preview("Meeting row") {
    List {
        MeetingListRowView(meeting: PreviewData.meeting)
    }
}
#endif

