//
//  GroupFilterMenu.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/30/22.
//

import SwiftUI

struct GroupFilterMenu: View {
    @Binding var groupFavorites: Bool

    var body: some View {
        Button(action: {
            withAnimation {
                groupFavorites.toggle()
            }
        }) {
            Label("Filter", systemImage: groupFavorites == true ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }
}
