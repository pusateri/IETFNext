//
//  ScheduleListRowView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/30/22.
//

import SwiftUI

struct SessionListRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var session: Session
    var body: some View {

        HStack {
            Button(action: {
                session.favorite.toggle()
                saveFavorite()
            }) {
                Image(systemName: session.favorite == true ? "star.fill" : "star")
                    .font(Font.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: areaColors[session.group?.areaKey ?? "ietf"] ?? 0xffff99))
            }
            VStack(alignment: .leading) {
                Text("\(session.name!) (\(session.group?.acronym ?? ""))")
                    .bold()
                    .foregroundColor(.primary)
                HStack {
                    Text("\(session.timerange!)")
                    Spacer()
                    if let loc = session.location {
                        Text("\(loc.name!)")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Unspecified")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    func saveFavorite() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Unable to save Session favorite \(session.name!)")
            }
        }
    }
}

struct ScheduleListRowView_Previews: PreviewProvider {
    static var session = Session()
    static var previews: some View {
        SessionListRowView(session: session)
    }
}
