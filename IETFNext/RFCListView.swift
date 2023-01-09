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
        formatter.dateFormat = "MM/YY"
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
                HStack {
                    Rectangle()
                        .fill(rfc.color)
                        .frame(width: 8, height: 42)
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(rfc.name2)")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(rfc.shortStatus) \(rfc.shortStream)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("\(rfc.title!)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            VStack {
                                Text("\(DateFormatter.simpleFormatter.string(from: rfc.published!))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if rfc.branch {
                                    Button(action: {
                                        print(rfc.name!)
                                    }) {
                                        Image(systemName: "arrow.triangle.pull")
                                            .font(Font.system(size: 24, weight: .bold))
                                            .foregroundColor(Color(hex: 0xf6c844))

                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .padding(.top, 2)
                                }
                            }
                        }
                    }
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
