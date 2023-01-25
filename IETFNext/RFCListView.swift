//
//  RFCListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/4/23.
//

import SwiftUI
import CoreData
import GraphViz

extension DynamicFetchRequestView where T : RFC {

    init(withMode listMode: SidebarOption, searchText: String, filterMode: Binding<RFCFilterMode>, @ViewBuilder content: @escaping (FetchedResults<T>) -> Content) {

        var sortDescriptors: [NSSortDescriptor]
        var search_criteria = searchText.isEmpty ? "" : "(name contains[cd] %@) OR (title contains[cd] %@)"
        let args = searchText.isEmpty ? [] : [searchText, searchText]

        switch(filterMode.wrappedValue) {
            case .bcp:
                if !search_criteria.isEmpty {
                    search_criteria += " AND "
                }
                search_criteria += "bcp != nil"
                sortDescriptors = [NSSortDescriptor(keyPath: \RFC.bcp, ascending: false)]
            case .fyi:
                if !search_criteria.isEmpty {
                    search_criteria += " AND "
                }
                search_criteria += "fyi != nil"
                sortDescriptors = [NSSortDescriptor(keyPath: \RFC.fyi, ascending: false)]
            case .std:
                if !search_criteria.isEmpty {
                    search_criteria += " AND "
                }
                search_criteria += "std != nil"
                sortDescriptors = [NSSortDescriptor(keyPath: \RFC.std, ascending: false)]
            case .none:
                if listMode == .bcp {
                    if !search_criteria.isEmpty {
                        search_criteria += " AND "
                    }
                    search_criteria += "bcp != nil"
                    sortDescriptors = [NSSortDescriptor(keyPath: \RFC.bcp, ascending: true)]
                } else if listMode == .fyi {
                    if !search_criteria.isEmpty {
                        search_criteria += " AND "
                    }
                    search_criteria += "fyi != nil"
                    sortDescriptors = [NSSortDescriptor(keyPath: \RFC.fyi, ascending: true)]
                } else if listMode == .std {
                    if !search_criteria.isEmpty {
                        search_criteria += " AND "
                    }
                    search_criteria += "std != nil"
                    sortDescriptors = [NSSortDescriptor(keyPath: \RFC.std, ascending: true)]
                } else {
                    sortDescriptors = [NSSortDescriptor(keyPath: \RFC.name, ascending: false)]
                }
        }

        if !search_criteria.isEmpty {
            let predicate = NSPredicate(format: search_criteria, argumentArray: args)
            self.init( withPredicate: predicate, andSortDescriptor: sortDescriptors, content: content)
        } else {
            let predicate = NSPredicate(value: true)
            self.init( withPredicate: predicate, andSortDescriptor: sortDescriptors, content: content)
        }
    }
}


struct RFCListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedRFC: RFC?
    @Binding var selectedDownload: Download?
    @Binding var rfcFilterMode: RFCFilterMode
    var listMode: SidebarOption
    @Binding var shortTitle: String?
    @Binding var longTitle: String?
    @Binding var html: String
    @Binding var localFileURL: URL?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @State private var searchText = ""
    @ObservedObject var model: DownloadViewModel = DownloadViewModel.shared

    var body: some View {
        ScrollViewReader { scrollViewReader in
            DynamicFetchRequestView(withMode: listMode, searchText: searchText, filterMode: $rfcFilterMode) { rfcs in
                List(rfcs, id: \.self, selection: $selectedRFC) { rfc in
                    RFCListRowView(
                        rfc: rfc,
                        rfcFilterMode: $rfcFilterMode,
                        listMode: listMode,
                        shortTitle: $shortTitle,
                        longTitle: $longTitle,
                        html: $html
                    )
                    .listRowSeparator(.visible)
                }
                .listStyle(.inset)
                .searchable(text: $searchText, placement: .automatic, prompt: "Number or Title string")
                .disableAutocorrection(true)
#if !os(macOS)
                .autocapitalization(.none)
                .keyboardType(.alphabet)
                .navigationBarTitleDisplayMode(.inline)
#endif
            }
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .navigation) {
                    RFCListTitleView(rfcFilterMode: $rfcFilterMode)
                }
                if listMode == .rfc {
                    ToolbarItem(placement: .navigation) {
                        RFCFilterMenu(rfcFilterMode: $rfcFilterMode)
                    }
                }
#else
                ToolbarItem(placement: .principal) {
                    RFCListTitleView(rfcFilterMode: $rfcFilterMode)
                }
                if listMode == .rfc {
                    ToolbarItem(placement: .primaryAction) {
                        RFCFilterMenu(rfcFilterMode: $rfcFilterMode)
                    }
                }
#endif
            }
            .onChange(of: selectedRFC) { newValue in
                if let rfc = newValue {
                    longTitle = rfc.title
                    shortTitle = rfc.name2
                    loadRFC(doc: rfc)
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
            .onAppear {
                if let doc = selectedRFC {
                    loadRFC(doc: doc)
                    withAnimation {
                        scrollViewReader.scrollTo(doc, anchor: .center)
                    }
                }
                if columnVisibility == .all {
                    withAnimation {
                        columnVisibility = .doubleColumn
                    }
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
        let urlString = "https://www.rfc-editor.org/rfc/\(doc.shortLowerName).html"
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
