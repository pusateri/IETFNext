//
//  DetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/7/22.
//

import SwiftUI

struct DetailView: View {
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedSession: Session?
    @Binding var html: String
    @Binding var localFileURL: URL?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    var body: some View {
        if let meeting = selectedMeeting {
            if let session = selectedSession {
                DetailViewUnwrapped(meeting: meeting, session: session, html: $html, localFileURL: $localFileURL, columnVisibility:$columnVisibility)
            }
        }
    }
}
