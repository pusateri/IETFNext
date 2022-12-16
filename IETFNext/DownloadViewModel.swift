//
//  DownloadViewModel.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/13/22.
//

import Foundation
import CoreData
import UniformTypeIdentifiers


@MainActor
class DownloadViewModel: NSObject, ObservableObject {
    @Published private(set) var isBusy = false
    @Published private(set) var error: String? = nil

    // This should only be called if there's no Download state for the url
    // TODO: deal with an agenda changing from .md to .txt to .html (save and check Etag)
    func downloadToFile(context: NSManagedObjectContext, url: URL, mtg: String, group: Group, kind:DownloadKind) async -> Download? {
        var download: Download? = nil

        self.isBusy = true
        self.error = nil

        defer {
            self.isBusy = false
        }

        // see if the file was already downloaded
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            let basename = url.lastPathComponent
            // if not already downloaded, download it now

            var urlrequest = URLRequest(url: url)
            urlrequest.addValue("text/markdown, text/html;q=0.9, text/plain;q=0.8", forHTTPHeaderField: "Accept")
            let (localURL, response) = try await URLSession.shared.download(for: urlrequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                self.error = "No HTTP Result"
                return nil
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                self.error = "Http Result: \(httpResponse.statusCode)"
                return nil
            }
            if let suggested = response.suggestedFilename {
                let savedURL = documentsURL.appendingPathComponent(suggested)
                if FileManager.default.isReadableFile(atPath: savedURL.path) == false {
                    do {
                        print("before move: \(savedURL)")
                        try FileManager.default.moveItem(at: localURL, to: savedURL)
                    } catch {
                        self.error = error.localizedDescription
                        return nil
                    }

                    context.performAndWait {
                        download = createDownloadState(context:context, documentsURL:documentsURL, basename:basename, savedURL:savedURL, mimeType: httpResponse.mimeType, fileSize:httpResponse.expectedContentLength, mtg:mtg, group:group, kind:kind)
                    }
                } else {
                    self.error = "file found with no Download state: \(basename)"
                    // This shouldn't happen but the moveItem will fail if there's something already there
                    // TODO: delete the file since we won't have enough info to create Download state
                }
            } else {
                self.error = "no suggested filename from download for: \(basename)"
            }
        } catch {
            self.error = error.localizedDescription
        }
        return download
    }

    func createDownloadState(context: NSManagedObjectContext, documentsURL: URL, basename:String, savedURL:URL, mimeType: String?, fileSize: Int64, mtg: String, group: Group, kind:DownloadKind) -> Download {

        let fetchDownload: NSFetchRequest<Download> = Download.fetchRequest()
        fetchDownload.predicate = NSPredicate(format: "basename = %@", basename)

        var download: Download!
        let results = try? context.fetch(fetchDownload)

        if results?.count == 0 {
            // here you are inserting
            download = Download(context: context)
            download.basename = basename
            download.mimeType = mimeType
            download.fullpathname = savedURL
            download.ext = savedURL.pathExtension
            download.group = group
            download.kind = kind.rawValue
            let titleBase = "IETF \(mtg) \(group.acronym!.uppercased()) "
            switch(kind) {
            case .agenda:
                download.title = titleBase + "Agenda"
            case .charter:
                download.title = titleBase + "Charter"
            case .minutes:
                download.title = titleBase + "Minutes"
            case .presentation:
                download.title = titleBase + "Presentation"
            }
            do {
                try context.save()
            }
            catch {
                print("Unable to save Download: \(basename)")
            }
        } else {
            // here you are updating
            download = results?.first
            print("Download \(download.basename!) already exists")
        }
        return download
    }
}