//
//  ScheduleListRowView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/30/22.
//

import SwiftUI


struct SessionListRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(EventStoreManager.self) private var storeManager
    @ObservedObject var session: Session
    @ObservedObject var group: Group
    @Binding var timerangeFormatter: DateFormatter?

    var body: some View {

        HStack {
            Button(action: {
                group.favorite.toggle()
                saveFavorite()
                storeManager.updateCalendar(for: group, in: session.meeting!)
            }) {
                Image(systemName: group.favorite == true ? "star.fill" : "star")
                    .font(Font.system(size: 24, weight: .bold))
                    .imageScale(.large)
                    .foregroundStyle(Color(hex: areaColors[group.areaKey ?? "ietf"] ?? 0xf6c844))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(group.favorite ? "Remove \(group.acronym ?? "group") from favorites" : "Add \(group.acronym ?? "group") to favorites")
            .accessibilityIdentifier("session.favorite")
            VStack(alignment: .leading) {
                HStack {
                    Text("\(session.name!) (\(group.acronym!))")
                        .bold()
                        .foregroundStyle(.primary)
                    if let loc = session.location {
                        Spacer()
                        Text("\(loc.level_name!)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack {
                    if let formatter = timerangeFormatter {
                        Text("\(formatter.string(from: session.start!))-\(formatter.string(from: session.end!))")
                            .foregroundStyle(.primary)
                            // Keep "0900-1100" on one line in narrow columns; the room name wraps instead.
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    Spacer()
                    if let loc = session.location {
                        Text("\(loc.name!)")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Unspecified")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func saveFavorite() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Unable to save Session group (\(group.acronym!)) favorite \(session.name!)")
            }
        }
    }
}

#if DEBUG
#Preview("Session row") {
    @Previewable @State var formatter: DateFormatter? = PreviewData.timerangeFormatter
    List {
        SessionListRowView(session: PreviewData.session, group: PreviewData.group, timerangeFormatter: $formatter)
    }
    .environment(\.managedObjectContext, PreviewData.context)
    .environment(EventStoreManager())
}
#endif

