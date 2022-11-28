//
//  MeetingListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/28/22.
//

import SwiftUI

struct MeetingListView: View {
    var body: some View {
        List {
            Text("IETF 115")
            Text("IETF 116")
            Text("IETF 117")
        }
    }
}

struct MeetingListView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingListView()
    }
}
