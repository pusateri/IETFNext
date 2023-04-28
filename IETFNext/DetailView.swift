//
//  DetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/7/22.
//

import SwiftUI

struct DetailView: View {
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedGroup: Group?
    @Binding var html: String
    @Binding var localFileURL: URL?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    var body: some View {
        if let meeting = selectedMeeting {
            if let group = selectedGroup {
                DetailViewUnwrapped(meeting: meeting, group: group, localFileURL: $localFileURL, columnVisibility:$columnVisibility)
            }
        }
    }
}
