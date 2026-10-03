//
//  SessionsSnippetView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 10/2/26.
//

import SwiftUI
import AppIntents

/// The card Siri and Shortcuts show for a list of sessions. Its buttons run intents,
/// since closures in a snippet never run.
struct SessionsSnippetView: View {
    /// The most rows shown; the rest are summarized in a count.
    static let maxRows = 5

    let sessions: [SessionEntity]

    var body: some View {
        VStack(alignment: .leading) {
            if sessions.isEmpty {
                Text("No sessions")
                    .foregroundStyle(.secondary)
            }
            ForEach(sessions.prefix(Self.maxRows)) { session in
                SessionsSnippetRow(session: session)
                if session.id != sessions.prefix(Self.maxRows).last?.id {
                    Divider()
                }
            }
            if sessions.count > Self.maxRows {
                Text("And \(sessions.count - Self.maxRows) more")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

private struct SessionsSnippetRow: View {
    let session: SessionEntity

    var body: some View {
        HStack {
            Button(intent: OpenSessionIntent(session: session)) {
                VStack(alignment: .leading) {
                    Text(session.groupAcronym.uppercased())
                        .font(.headline)
                    Text(session.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    Text(session.timeRange)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let place = session.place {
                        Text(place)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the session in IETF Next")

            if session.locationID != nil {
                Button("Room Map", systemImage: "map", intent: ShowRoomMapIntent(session: session))
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
            }
        }
    }
}
