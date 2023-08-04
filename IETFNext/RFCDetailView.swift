//
//  RFCDetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/20/23.
//

import SwiftUI

struct RFCDetailView: View {
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Binding var selectedRFC: RFC?
    @Binding var selectedDownload: Download?
    @Binding var shortTitle: String?
    @Binding var longTitle: String?

    @Binding var columnVisibility: NavigationSplitViewVisibility

    var body: some View {
        WebView(download:$selectedDownload)
        .toolbar {
            ToolbarItemGroup {
                HStack {
                    Spacer()
                    if hSizeClass == .compact {
                        Text(shortTitle ?? "")
                    } else {
                        Text(longTitle ?? "")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    if let rfc = selectedRFC, rfc.branch == true {
                        Button(action: {
                            showGraph(rfc: rfc, colorScheme: colorScheme)
                        }) {
                            Image(systemName: "arrow.triangle.pull")
                                .bold()
                                .foregroundColor(Color(hex: 0xf6c844))
                        }
                    }
                }
            }
#if !os(macOS)
            if hSizeClass == .regular {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        switch (columnVisibility) {
                            case .detailOnly:
                                withAnimation {
                                    columnVisibility = .doubleColumn
                                }
                            default:
                                withAnimation {
                                    columnVisibility = .detailOnly
                                }
                        }
                    }) {
                        switch (columnVisibility) {
                            case .detailOnly:
                                Label("Expand", systemImage: "arrow.down.right.and.arrow.up.left")
                            default:
                                Label("Contract", systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                    }
                }
            }
#endif
        }
    }
}

extension RFCDetailView {
    func showGraph(rfc: RFC, colorScheme: ColorScheme) {
        let graph = buildGraph(start: rfc, colorScheme: colorScheme)
        graph.render(using: .dot, to: .svg) { result in
            guard case .success(let data) = result else { return }
            if let str = String(data: data, encoding: .utf8) {
                // XXX html = SVG_PRE + str + SVG_POST
            }
        }
    }
}

