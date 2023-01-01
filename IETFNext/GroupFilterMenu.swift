//
//  GroupFilterMenu.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/30/22.
//

import SwiftUI

struct GroupFilterMenu: View {
    @Binding var groupFilterMode: GroupFilterMode

    var body: some View {
        Button(action: {
            withAnimation {
                if groupFilterMode == .none {
                    groupFilterMode = .favorites
                } else {
                    groupFilterMode = .none
                }
            }
        }) {
            Label("Filter", systemImage: groupFilterMode == .favorites ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }
}
