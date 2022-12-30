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
                    Label(SessionFilterMode.favorites.label, systemImage: SessionFilterMode.favorites.image)
                }
                Button(action: {
                    sessionFilterMode = .bofs
                }) {
                    Label(SessionFilterMode.bofs.label, systemImage: SessionFilterMode.bofs.image)
                }
                Button(action: {
                    sessionFilterMode = .now
                }) {
                    Label(SessionFilterMode.now.label, systemImage: SessionFilterMode.now.image)
                }
                Button(action: {
                    sessionFilterMode = .today
                }) {
                    Label(SessionFilterMode.today.label, systemImage: SessionFilterMode.today.image)
                }
                Button(action: {
                    sessionFilterMode = .none
                }) {
                    Label(SessionFilterMode.none.label, systemImage: SessionFilterMode.none.image)
                }
            }
            Section("Filter by Area") {
                Button(action: {
                    sessionFilterMode = .area_art
                }) {
                    Label(SessionFilterMode.area_art.label, systemImage: SessionFilterMode.area_art.image)
                        .foregroundColor(.red)
                }
                Button(action: {
                    sessionFilterMode = .area_gen
                }) {
                    Label(SessionFilterMode.area_gen.label, systemImage: SessionFilterMode.area_gen.image)
                }
                Button(action: {
                    sessionFilterMode = .area_int
                }) {
                    Label(SessionFilterMode.area_int.label, systemImage: SessionFilterMode.area_int.image)
                }
                Button(action: {
                    sessionFilterMode = .area_irtf
                }) {
                    Label(SessionFilterMode.area_irtf.label, systemImage: SessionFilterMode.area_irtf.image)
                }
                Button(action: {
                    sessionFilterMode = .area_ops
                }) {
                    Label(SessionFilterMode.area_ops.label, systemImage: SessionFilterMode.area_ops.image)
                }
                Button(action: {
                    sessionFilterMode = .area_rtg
                }) {
                    Label(SessionFilterMode.area_rtg.label, systemImage: SessionFilterMode.area_rtg.image)
                }
                Button(action: {
                    sessionFilterMode = .area_sec
                }) {
                    Label(SessionFilterMode.area_sec.label, systemImage: SessionFilterMode.area_sec.image)
                }
                Button(action: {
                    sessionFilterMode = .area_tsv
                }) {
                    Label(SessionFilterMode.area_tsv.label, systemImage: SessionFilterMode.area_tsv.image)
                }
            }
        }
        label: {
            Label("More", systemImage: sessionFilterMode == .none ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }
}
