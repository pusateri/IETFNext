//
//  GroupListTitleView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/30/22.
//

import SwiftUI

struct GroupListTitleView: View {
    @Binding var groupFilterMode: GroupFilterMode

    var body: some View {
        VStack {
            Text("Groups")
                .foregroundColor(.primary)
                .font(.headline)
            if groupFilterMode == .favorites {
                Text("\("Filter: Favorites")")
                    .font(.footnote)
                    .foregroundColor(.accentColor)
            }
        }
    }
}
