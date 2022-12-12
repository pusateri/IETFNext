//
//  GroupListRowView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/12/22.
//

import SwiftUI


struct GroupListRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedMeeting: Meeting?
    var group: Group
    @State var mode: FavoriteMode

    init(selectedMeeting: Binding<Meeting?>, group: Group) {
        self._selectedMeeting = selectedMeeting
        self.group = group
        self.mode = group.favoriteSymbolMode(meeting:selectedMeeting.wrappedValue)
    }

    var body: some View {
        HStack {
            Button(action: {
                if let meeting = selectedMeeting {
                    group.updateFavoriteSymbolMode(meeting:meeting)
                    saveFavorites()
                    mode = group.favoriteSymbolMode(meeting:meeting)
                }
            }) {
                Image(systemName: group.favoriteSymbol(mode:mode))
                    .font(Font.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: areaColors[group.areaKey ?? "ietf"] ?? 0xf6c844))
            }
            VStack(alignment: .leading) {
                Text(group.acronym!)
                    .foregroundColor(.primary)
                    .bold()
                Text(group.name!)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func saveFavorites() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Unable to save Group favorites")
            }
        }
    }
}
