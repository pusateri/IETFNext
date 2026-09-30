//
//  SessionListTitleView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/30/22.
//

import SwiftUI

struct SessionListTitleView: View {
    @Binding var sessionFilterMode: SessionFilterMode

    var body: some View {
        VStack {
            Text("Schedule")
                .foregroundStyle(.primary)
                .font(.headline)
            if sessionFilterMode != .none {
                Text("\("Filter: \(sessionFilterMode.short)")")
                    .font(.footnote)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}
