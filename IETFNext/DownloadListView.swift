//
//  DownloadListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/11/22.
//

import SwiftUI
import CoreData
import MarkdownKit

public enum DownloadKind: String {
    case agenda
    case charter
    case draft
    case minutes
    case presentation
    case rfc
}

public func httpEcoding2StringEncoding(encoding: String?) -> String.Encoding {
    if let encoding = encoding {
        if encoding == "us-ascii" {
            return .ascii
        } else if encoding == "utf-8" {
            return .utf8
        } else if encoding == "iso-8859-1" {
            //return .isoLatin1
            return .macOSRoman
        }
    }
    return .utf8
}

public func fetchDownload(context: NSManagedObjectContext, kind:DownloadKind, url:URL) -> Download? {
    var download: Download?

    context.performAndWait {
        let fetch: NSFetchRequest<Download> = Download.fetchRequest()
        fetch.predicate = NSPredicate(format: "basename = %@", url.lastPathComponent)

        let results = try? context.fetch(fetch)

        if results?.count == 0 {
            download = nil
        } else {
                // here you are updating
            download = results?.first
        }
    }
    return download
}

public func contents2Html(from: Download) -> String? {
    if let filename = from.filename {
        do {
            let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: false)
            let url = documentsURL.appendingPathComponent(filename)
            do {
                let enc = httpEcoding2StringEncoding(encoding: from.encoding)
                let contents = try String(contentsOf:url, encoding: enc)
                if from.mimeType == "text/plain" {
                    return PLAIN_PRE + contents + PLAIN_POST
                } else if from.mimeType == "text/markdown" {
                    //return PLAIN_PRE + contents + PLAIN_POST
                    let markdown = MarkdownParser.standard.parse(contents)

                    return MD_PRE + HtmlGenerator.standard.generate(doc: markdown) + MD_POST
                } else if from.mimeType == "text/html" {
                    if !contents.contains("<style") {
                        if let regex = try? NSRegularExpression(pattern: "<head>", options: .dotMatchesLineSeparators) {
                            let range = NSRange(contents.startIndex..., in: contents)
                            let subrange = regex.rangeOfFirstMatch(in: contents, options: [], range: range)
                            if subrange.location != NSNotFound {
                                let fixedString = (contents as NSString).replacingCharacters(in: subrange, with: "<head> " + HTML_INSERT_STYLE)
                                return fixedString
                            }
                        }
                    }
                    return contents
                }
            } catch {
                return "Unable to read downloaded file: \(url.absoluteString)"
            }
        } catch {
            return "Unable to download filename: \(filename)"
        }
    }
    return nil
}

extension SectionedFetchResults where Result == Download {
    var totalSize: Int64 {
        self.reduce(0) { sum, section in
            section.reduce(into: sum) { $0 += $1.filesize }
        }
    }
}

extension SectionedFetchResults.Section where Result == Download {
    var sectionSize: Int64 {
        self.reduce(0) { $0 + $1.filesize }
    }
}

struct DownloadListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDownload: Download?
    @Binding var html: String
    @Binding var localFileURL: URL?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @SectionedFetchRequest<String, Download>(
        sectionIdentifier: \.kind!,
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Download.kind, ascending: true),
            NSSortDescriptor(keyPath: \Download.basename, ascending: true),
        ],
        animation: .default)
    private var downloads: SectionedFetchResults<String, Download>

    /*
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
                    html = "Error reading \(from.filename!)"
                }
            }
        }
    }
*/
    func sizeString(_ size: Int64) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        if multiplyFactor == 0 {
            return String(format: "%4.0f %@", convertedValue, tokens[multiplyFactor])
        } else {
            return String(format: "%4.1f %@", convertedValue, tokens[multiplyFactor])
        }
    }

    func removeDownload(section: SectionedFetchResults<String, Download>.Section, indexset: IndexSet) {
        viewContext.performAndWait {
            for i in indexset {
                let download: Download = section[i]
                if let filename = download.filename {
                    do {
                        let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                                       in: .userDomainMask,
                                                                       appropriateFor: nil,
                                                                       create: false)
                        
                        let savedURL = documentsURL.appendingPathComponent(filename)
                        do {
                            try FileManager.default.removeItem(at: savedURL)
                            viewContext.delete(download)
                        } catch {
                            print(error.localizedDescription)
                        }
                    } catch {
                        print("couldn't create fileURL to delete download: \(filename), error \(error.localizedDescription)")
                    }
                }
            }
            do {
                try viewContext.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    var body: some View {
        ScrollViewReader { scrollViewReader in
            List(downloads, selection: $selectedDownload) { section in
                Section {
                    ForEach(section, id: \.self) { download in
                        VStack(alignment: .leading) {
                            HStack {
                                Text("\(download.title ?? download.group?.acronym ?? "Unknown")")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(download.group?.acronym ?? "")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.all, 2)
                            HStack {
                                Text(download.filename ?? "path/absent")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(sizeString(download.filesize))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.all, 2)
                        }
                    }
                    .onDelete { indexSet in
                        removeDownload(section: section, indexset: indexSet)
                    }
                    .listRowSeparator(.visible)
                } header: {
                    HStack {
                        Text(section.id == "rfc" ? "RFC" : section.id.capitalized)
                            .foregroundColor(.accentColor)
                        Spacer()
                        Text("\(sizeString(section.sectionSize))")
                            .foregroundColor(.accentColor)
                            .font(.subheadline)
                    }
                }
                .headerProminence(.increased)
            }
            .listStyle(.inset)
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .navigation) {
                    Text("Downloads")
                        .foregroundColor(.primary)
                        .font(.headline)
                }
#else
                ToolbarItem(placement: .principal) {
                    Text("Downloads")
                        .foregroundColor(.primary)
                        .font(.headline)
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
                ToolbarItem(placement: .bottomBar) {
                    Text("Total: \(sizeString(downloads.totalSize))")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
#endif
            }
            .onChange(of: selectedDownload) { newValue in
                if let download = newValue {
                    //loadDownloadFile(from: download)
                }
            }
            .onAppear() {
                if let download = selectedDownload {
                    //loadDownloadFile(from: download)
                    withAnimation {
                        scrollViewReader.scrollTo(download, anchor: .center)
                    }
                } else {
                    html = BLANK
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

