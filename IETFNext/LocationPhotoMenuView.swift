//
//  LocationPhotoMenuView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/31/22.
//

import SwiftUI

struct LocationPhotoMenuView: View {
    @Binding var selectedMeeting: Meeting?
    @Binding var locationDetailMode: LocationDetailMode

    var body: some View {
        if let meeting = selectedMeeting {
            if let _ = venuePhotos[meeting.number!] {
                Button(action: {
                    locationDetailMode = .none
                }) {
                    Text("Show Venue Photo")
                    Image(systemName: "photo")
                }
            }
        }
    }
}
