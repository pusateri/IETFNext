//
//  DownloadListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/11/22.
//

import SwiftUI
import CoreData

public enum DownloadKind: String {
    case agenda
    case charter
    case minutes
    case presentation
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
                let contents = try String(contentsOf:url, encoding: .utf8)
                if from.mimeType == "text/plain" {
                    return PLAIN_PRE + contents + PLAIN_POST
                } else if from.mimeType == "text/markdown" {
                    return PLAIN_PRE + contents + PLAIN_POST
                } else if from.mimeType == "text/html" {
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

public func fetchDownload(context:NSManagedObjectContext, kind:DownloadKind, url:URL) -> Download? {
    let download: Download?

    let fetchDownload: NSFetchRequest<Download> = Download.fetchRequest()
    fetchDownload.predicate = NSPredicate(format: "basename = %@", url.lastPathComponent)

    let results = try? context.fetch(fetchDownload)

    if results?.count == 0 {
        download = nil
    } else {
            // here you are updating
        download = results?.first
    }
    return download
}

struct DownloadListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var html: String
    @Binding var fileURL: URL?
    @Binding var title: String
    @State var selectedDownload: Download?
    @SectionedFetchRequest<String, Download>(
        sectionIdentifier: \.kind!,
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Download.kind, ascending: true),
            NSSortDescriptor(keyPath: \Download.basename, ascending: true),
        ],
        animation: .default)
    private var downloads: SectionedFetchResults<String, Download>

    func loadDownloadFile(from:Download) {
        if let mimeType = from.mimeType {
            if mimeType == "application/pdf" {
                if let filename = from.filename {
                    do {
                        let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                                       in: .userDomainMask,
                                                                       appropriateFor: nil,
                                                                       create: false)
                        fileURL = documentsURL.appendingPathComponent(filename)
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

    func sizeString(_ size: Int64) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        return String(format: "%4.0f %@", convertedValue, tokens[multiplyFactor])
    }

    var body: some View {
        List(downloads, selection: $selectedDownload) { section in
            Section(header: Text(section.id.capitalized).foregroundColor(.accentColor)) {
                ForEach(section, id: \.self) { download in
                    VStack(alignment: .leading) {
                        Text(download.title!)
                            .foregroundColor(.primary)
                        HStack {
                            Text(download.filename ?? "path/absent")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(sizeString(download.filesize))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedDownload) { newValue in
            if let download = selectedDownload {
                loadDownloadFile(from: download)
            }
        }
    }
}

