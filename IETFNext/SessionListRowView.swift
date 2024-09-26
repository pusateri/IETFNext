//
//  ScheduleListRowView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 11/30/22.
//

import SwiftUI


struct SessionListRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var storeManager: EventStoreManager
    @ObservedObject var session: Session
    @ObservedObject var group: Group
    @Binding var timerangeFormatter: DateFormatter?

    var body: some View {

        HStack {
            Button(action: {
                group.favorite.toggle()
                saveFavorite()
                updateCalendar(group: group, meeting: session.meeting!)
            }) {
                Image(systemName: group.favorite == true ? "star.fill" : "star")
                    .font(Font.system(size: 24, weight: .bold))
                    .imageScale(.large)
                    .foregroundColor(Color(hex: areaColors[group.areaKey ?? "ietf"] ?? 0xf6c844))
            }
            .buttonStyle(BorderlessButtonStyle())
            VStack(alignment: .leading) {
                HStack {
                    Text("\(session.name!) (\(group.acronym!))")
                        .bold()
                        .foregroundColor(.primary)
                    if let loc = session.location {
                        Spacer()
                        Text("\(loc.level_name!)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    if let formatter = timerangeFormatter {
                        Text("\(formatter.string(from: session.start!))-\(formatter.string(from: session.end!))")
                            .foregroundColor(.primary)
                    }
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

    private func saveFavorite() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Unable to save Session group (\(group.acronym!)) favorite \(session.name!)")
            }
        }
    }
    func updateCalendar(group: Group, meeting: Meeting) {
        Task {
            do {
                if !storeManager.isWriteOnlyOrFullAccessAuthorized {
                    try await storeManager.setupEventStore()
                }
                await storeManager.setIETFNextCalendar()
                if let sessions = group.groupSessionsIn(meeting: meeting) {
                    for session in sessions {
                        if group.favorite == true {
                            await session.createEvent(storeManager: storeManager)
                        } else {
                            await session.deleteEvent(storeManager: storeManager)
                        }
                    }
                }
            } catch {
                print("pushToCalendar error: \(error.localizedDescription)")
            }
        }
    }
}

