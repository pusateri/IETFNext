//
//  RFCListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/4/23.
//

import SwiftUI
import CoreData
import GraphViz


struct RFCListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedRFC: RFC?
    @Binding var selectedDownload: Download?
    @Binding var rfcFilterMode: RFCFilterMode
    @Binding var html: String
    @Binding var localFileURL: URL?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @FetchRequest<RFC> var rfcs: FetchedResults<RFC>
    @State private var searchText = ""
    @ObservedObject var model: DownloadViewModel = DownloadViewModel.shared

    init(selectedRFC: Binding<RFC?>, selectedDownload: Binding<Download?>, rfcFilterMode: Binding<RFCFilterMode>, html: Binding<String>, localFileURL:Binding<URL?>, columnVisibility: Binding<NavigationSplitViewVisibility>) {
        var predicate: NSPredicate?

        switch(rfcFilterMode.wrappedValue) {
        case .bcp:
            predicate = NSPredicate(format: "bcp != nil")
        case .fyi:
            predicate = NSPredicate(format: "fyi != nil")
        case .std:
            predicate = NSPredicate(format: "std != nil")
        case .none:
            predicate = nil
        }

        _rfcs = FetchRequest<RFC>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \RFC.name, ascending: false),
            ],
            predicate: predicate,
            animation: .default
        )
        self._selectedRFC = selectedRFC
        self._selectedDownload = selectedDownload
        self._rfcFilterMode = rfcFilterMode
        self._html = html
        self._localFileURL = localFileURL
        self._columnVisibility = columnVisibility
    }

    private func updatePredicate() {
        if searchText.isEmpty {
            rfcs.nsPredicate = nil
        } else {
            rfcs.nsPredicate = NSPredicate(
                format: "(name contains[cd] %@) OR (title contains[cd] %@)", searchText, searchText)
        }
    }

    var body: some View {
        ScrollViewReader { scrollViewReader in
            List(rfcs, id: \.self, selection: $selectedRFC) { rfc in
                RFCListRowView(rfc: rfc, rfcFilterMode: $rfcFilterMode, html: $html)
                .listRowSeparator(.visible)
            }
            .listStyle(.inset)
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .automatic, prompt: "Number or Title string")
            .keyboardType(.alphabet)
            .disableAutocorrection(true)
#endif
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .navigation) {
                    RFCListTitleView(rfcFilterMode: $rfcFilterMode)
                }
                ToolbarItem(placement: .navigation) {
                    RFCFilterMenu(rfcFilterMode: $rfcFilterMode)
                }
#else
                ToolbarItem(placement: .principal) {
                    RFCListTitleView(rfcFilterMode: $rfcFilterMode)
                }
                ToolbarItem(placement: .primaryAction) {
                    RFCFilterMenu(rfcFilterMode: $rfcFilterMode)
                }
#endif
            }
            .onChange(of: selectedRFC) { newValue in
                if let doc = newValue {
                    loadRFC(doc: doc)
                }
            }
            .onChange(of: model.download) { newValue in
                if let download = newValue {
                    selectedDownload = download
                    loadDownloadFile(from:download)
                }
            }
            .onChange(of: model.error) { newValue in
                if let err = newValue {
                    html = PLAIN_PRE + err + PLAIN_POST
                }
            }
            .onChange(of: searchText) { newValue in
                updatePredicate()
            }
            .onAppear {
                if let doc = selectedRFC {
                    loadRFC(doc: doc)
                    withAnimation {
                        scrollViewReader.scrollTo(doc, anchor: .center)
                    }
                } else {
                    html = BLANK
                }
                if columnVisibility == .all {
                    columnVisibility = .doubleColumn
                }
            }
        }
    }
}

extension RFCListView {
    private func loadDownloadFile(from:Download) {
        if let mimeType = from.mimeType {
            if mimeType == "application/pdf" {
                if let filename = from.filename {
                    do {
                        let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                                       in: .userDomainMask,
                                                                       appropriateFor: nil,
                                                                       create: false)
                        html = ""
                        localFileURL = documentsURL.appendingPathComponent(filename)
                    } catch {
                        html = "Error reading pdf file: \(from.filename!)"
                    }
                }
            } else {
                if let contents = contents2Html(from:from) {
                    html = contents
                } else {
                    html = "Error reading \(from.filename!) error: \(String(describing: model.error))"
                }
            }
        }
    }

    private func fetchDownload(kind:DownloadKind, url:URL) -> Download? {
        var download: Download?

        viewContext.performAndWait {
            let fetch: NSFetchRequest<Download> = Download.fetchRequest()
            fetch.predicate = NSPredicate(format: "basename = %@", url.lastPathComponent)

            let results = try? viewContext.fetch(fetch)

            if results?.count == 0 {
                download = nil
            } else {
                // here you are updating
                download = results?.first
            }
        }
        return download
    }

    private func loadRFC(doc: RFC) {
        let urlString = "https://www.rfc-editor.org/rfc/\(doc.name!.lowercased()).html"
        if let url = URL(string: urlString) {
            let download = fetchDownload(kind:.rfc, url:url)
            if let download = download {
                selectedDownload = download
                loadDownloadFile(from: download)
            } else {
                Task {
                    await model.downloadToFile(context:viewContext, url:url, group: nil, kind:.rfc, title: doc.title!)
                }
            }
        }
    }
}
