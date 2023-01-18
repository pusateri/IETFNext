//
//  RFCFilterMenu.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/17/23.
//

import SwiftUI

struct RFCFilterMenu: View {
    @Binding var rfcFilterMode: RFCFilterMode

    var body: some View {
        Menu {
            Section("Filter") {
                Button(action: {
                    rfcFilterMode = .bcp
                }) {
                    Text(RFCFilterMode.bcp.label)
                    Image(systemName: RFCFilterMode.bcp.image)
                }
                Button(action: {
                    rfcFilterMode = .fyi
                }) {
                    Text(RFCFilterMode.fyi.label)
                    Image(systemName: RFCFilterMode.fyi.image)
                }
                Button(action: {
                    rfcFilterMode = .std
                }) {
                    Text(RFCFilterMode.std.label)
                    Image(systemName: RFCFilterMode.std.image)
                }
                Button(action: {
                    rfcFilterMode = .none
                }) {
                    Text(RFCFilterMode.none.label)
                    Image(systemName: RFCFilterMode.none.image)
                }
            }
        }
        label: {
            Label("More", systemImage: rfcFilterMode == .none ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }
}
