//
//  RFCListTitleView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/17/23.
//

import SwiftUI

struct RFCListTitleView: View {
    @Binding var rfcFilterMode: RFCFilterMode

    var body: some View {
        VStack {
            Text("Standards")
                .foregroundColor(.primary)
                .font(.headline)
            if rfcFilterMode != .none {
                Text("\("Filter: \(rfcFilterMode.short)")")
                    .font(.footnote)
                    .foregroundColor(.accentColor)
            }
        }
    }
}
