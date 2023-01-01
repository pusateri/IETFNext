//
//  GroupListRowView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/12/22.
//

import SwiftUI


struct GroupListRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var group: Group


    var body: some View {
        HStack {
            Button(action: {
                group.favorite.toggle()
                saveFavorites()
            }) {
                Image(systemName: group.favorite ? "star.fill" : "star")
                    .font(Font.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: areaColors[group.areaKey ?? "ietf"] ?? 0xf6c844))
            }
            .buttonStyle(BorderlessButtonStyle())
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
                print("Unable to save Group \(group.acronym!) favorite")
            }
        }
    }
}
