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
    if let fullpathname = from.fullpathname {
        do {
            let contents = try String(contentsOf: fullpathname, encoding: .utf8)
            if from.mimeType == "text/plain" {
                return PLAIN_PRE + contents + PLAIN_POST
            } else if from.mimeType == "text/markdown" {
                return PLAIN_PRE + contents + PLAIN_POST
            } else if from.mimeType == "text/html" {
                return contents
            }
        } catch {
            return nil
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
    @State var selectedDownload: Download?
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Download.basename, ascending: true)],
        animation: .default)
    private var downloads: FetchedResults<Download>

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
        List(downloads, id: \.self, selection: $selectedDownload) { download in
            VStack(alignment: .leading) {
                Text(download.title!)
                    .foregroundColor(.primary)
                HStack {
                    Text(download.fullpathname?.lastPathComponent ?? "path/absent")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(sizeString(download.filesize))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onChange(of: selectedDownload) { newValue in
            if let download = selectedDownload {
                if let contents = contents2Html(from:download) {
                    print(contents)
                }
            }
        }
    }
}

