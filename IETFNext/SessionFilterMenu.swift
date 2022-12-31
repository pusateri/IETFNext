//
//  SessionFilterMenu.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/30/22.
//

import SwiftUI

struct SessionFilterMenu: View {
    @Binding var sessionFilterMode: SessionFilterMode

    var body: some View {
        Menu {
            Section("Common Filters") {
                Button(action: {
                    sessionFilterMode = .favorites
                }) {
                    Text(SessionFilterMode.favorites.label)
                    Image(systemName: SessionFilterMode.favorites.image)
                }
                Button(action: {
                    sessionFilterMode = .bofs
                }) {
                    Text(SessionFilterMode.bofs.label)
                    Image(systemName: SessionFilterMode.bofs.image)
                }
                Button(action: {
                    sessionFilterMode = .now
                }) {
                    Text(SessionFilterMode.now.label)
                    Image(systemName: SessionFilterMode.now.image)
                }
                Button(action: {
                    sessionFilterMode = .today
                }) {
                    Text(SessionFilterMode.today.label)
                    Image(systemName: SessionFilterMode.today.image)
                }
                Button(action: {
                    sessionFilterMode = .none
                }) {
                    Text(SessionFilterMode.none.label)
                    Image(systemName: SessionFilterMode.none.image)
                }
            }
            Section("Filter by Area") {
                Button(action: {
                    sessionFilterMode = .area_art
                }) {
                    Text(SessionFilterMode.area_art.label)
                    Image(systemName: SessionFilterMode.area_art.image)
                }
                Button(action: {
                    sessionFilterMode = .area_gen
                }) {
                    Text(SessionFilterMode.area_gen.label)
                    Image(systemName: SessionFilterMode.area_gen.image)
                }
                Button(action: {
                    sessionFilterMode = .area_int
                }) {
                    Text(SessionFilterMode.area_int.label)
                    Image(systemName: SessionFilterMode.area_int.image)
                }
                Button(action: {
                    sessionFilterMode = .area_irtf
                }) {
                    Text(SessionFilterMode.area_irtf.label)
                    Image(systemName: SessionFilterMode.area_irtf.image)
                }
                Button(action: {
                    sessionFilterMode = .area_ops
                }) {
                    Text(SessionFilterMode.area_ops.label)
                    Image(systemName: SessionFilterMode.area_ops.image)
                }
                Button(action: {
                    sessionFilterMode = .area_rtg
                }) {
                    Text(SessionFilterMode.area_rtg.label)
                    Image(systemName: SessionFilterMode.area_rtg.image)
                }
                Button(action: {
                    sessionFilterMode = .area_sec
                }) {
                    Text(SessionFilterMode.area_sec.label)
                    Image(systemName: SessionFilterMode.area_sec.image)
                }
                Button(action: {
                    sessionFilterMode = .area_tsv
                }) {
                    Text(SessionFilterMode.area_tsv.label)
                    Image(systemName: SessionFilterMode.area_tsv.image)
                }
            }
        }
        label: {
            Label("More", systemImage: sessionFilterMode == .none ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }
}
