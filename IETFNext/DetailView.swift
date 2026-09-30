//
//  DetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/7/22.
//

import SwiftUI

struct DetailView: View {
    // Read-only inputs are passed by value, not as bindings. Passing the values makes the
    // owner (ContentView) depend on them, so the split view's detail column updates when a
    // group is picked. With bindings, the first group or session picked after launch never
    // reached this view and the detail pane stayed blank.
    let selectedMeeting: Meeting?
    let selectedGroup: Group?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    var body: some View {
        if let meeting = selectedMeeting {
            if let group = selectedGroup {
                DetailViewUnwrapped(meeting: meeting, group: group, columnVisibility:$columnVisibility)
            }
        }
    }
}
