//
//  RFCListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/4/23.
//

import SwiftUI
import CoreData

private extension DateFormatter {
    static let simpleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: Locale.current.identifier)
        return formatter
    }()
}

struct RFCListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedRFC: RFC?
    @Binding var selectedDownload: Download?
    @Binding var html: String
    @Binding var localFileURL: URL?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    
    @State private var searchText = ""
    @ObservedObject var model: DownloadViewModel = DownloadViewModel.shared

    @FetchRequest<RFC>(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \RFC.name, ascending: false),
        ],
        animation: .default)
    private var rfcs: FetchedResults<RFC>


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

    private func makeSpace(rfc: String?) -> String {
        if let rfc = rfc {
            return rfc.enumerated().compactMap({ ($0  == 3) ? " \($1)" : "\($1)" }).joined()
        } else {
            return ""
        }
    }

    public func fetchDownload(kind:DownloadKind, url:URL) -> Download? {
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

    func loadRFC(doc: RFC) {
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

    private func shortenStatus(status: String?) -> String {
        if let status = status {
            switch(status) {
            case "BEST CURRENT PRACTICE":
                return "BCP"
            case "DRAFT STANDARD":
                return "DS"
            case "EXPERIMENTAL":
                return "EXP"
            case "HISTORIC":
                return "HIST"
            case "INFORMATIONAL":
                return "INFO"
            case "INTERNET STANDARD":
                return "IS"
            case "PROPOSED STANDARD":
                return "PS"
            default:
                return "UNKN"
            }
        }
        return "UNKN"
    }

    private func shortenStream(stream: String?) -> String {
        if let stream = stream {
            switch(stream) {
            case "IAB", "IETF", "IRTF":
                return stream
            case "INDEPENDENT":
                return "INDP"
            case "Legacy":
                return "LEGC"
            default:
                return stream
            }
        }
        return ""
    }

    private func updatePredicate() {
        if searchText.isEmpty {
            rfcs.nsPredicate = NSPredicate(value: true)
        } else {
            rfcs.nsPredicate = NSPredicate(
                format: "(name contains[cd] %@) OR (title contains[cd] %@)", searchText, searchText)
        }
    }

    var body: some View {
        ScrollViewReader { scrollViewReader in
            List(rfcs, id: \.self, selection: $selectedRFC) { rfc in
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(makeSpace(rfc: rfc.name))")
                            .foregroundColor(.primary)
                            .font(.title3.bold())
                        Spacer()
                        Text("\(shortenStatus(status: rfc.currentStatus)) \(shortenStream(stream: rfc.stream))")
                            .foregroundColor(.secondary)
                    }
                    Text("\(rfc.title!)")
                        .foregroundColor(.secondary)
                    // future arrow.triangle.pull
                }
                .listRowSeparator(.visible)
            }
            .listStyle(.inset)
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .keyboardType(.alphabet)
            .disableAutocorrection(true)
#endif
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
                    withAnimation {
                        scrollViewReader.scrollTo(doc)
                    }
                    loadRFC(doc: doc)
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
