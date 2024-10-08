//
//  DownloadDetailView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/1/23.
//

import SwiftUI

struct DownloadDetailView: View {
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Binding var selectedDownload: Download?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    var body: some View {
        WebView(download:$selectedDownload)
        .toolbar {
            if hSizeClass == .regular {
                ToolbarItem(placement: .principal) {
                    Text(selectedDownload?.title ?? "")
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
