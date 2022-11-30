//
//  ScheduleListRowView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/30/22.
//

import SwiftUI

struct ScheduleListRowView: View {
    var session: Session
    var body: some View {

        VStack(alignment: .leading) {
            Text("\(session.name!)")
                .bold()
                .foregroundColor(.primary)
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(.gray)
                Spacer()
            }
            HStack {
                Text("\(session.timerange!)")
                Spacer()
                if let loc = session.location {
                    Text("\(loc.name!)")
                        .foregroundColor(.secondary)
                } else {
                    Text("Unspecified")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ScheduleListRowView_Previews: PreviewProvider {
    static var session = Session()
    static var previews: some View {
        ScheduleListRowView(session: session)
    }
}
