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
    @Published var download: Download? = nil
    @Published private(set) var error: String? = nil

    // This should only be called if there's no Download state for the url
    // TODO: deal with an agenda changing from .md to .txt to .html (save and check Etag)
    func downloadToFile(context: NSManagedObjectContext, url: URL, group: Group?, kind:DownloadKind, title: String?) async {

        self.isBusy = true
        self.error = nil
        self.download = nil

        defer {
            self.isBusy = false
        }

        // see if the file was already downloaded
        do {
            let documentsURL = try FileManager.default.url(for: .documentDirectory,
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
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                self.error = "Http Result \(httpResponse.statusCode): \(url.absoluteString)"
                return
            }
            if let suggested = response.suggestedFilename {
                let savedURL = documentsURL.appendingPathComponent(suggested)
                if FileManager.default.isReadableFile(atPath: savedURL.path) == false {
                    do {
                        try FileManager.default.moveItem(at: localURL, to: savedURL)
                    } catch {
                        self.error = error.localizedDescription
                        return
                    }

                    context.performAndWait {
                        self.download = createDownloadState(context:context, basename:basename, filename:suggested, mimeType: httpResponse.mimeType, encoding: httpResponse.textEncodingName, fileSize:httpResponse.expectedContentLength, ETag: httpResponse.value(forHTTPHeaderField: "ETag"), group:group, kind:kind, title:title)
                    }
                } else {
                    // This shouldn't happen but the moveItem will fail if there's something already there
                    self.error = "file found with no Download state, removing: \(basename)"
                    do {
                        try FileManager.default.removeItem(at: savedURL)
                    } catch {
                        self.error = "error with file: \(basename)"
                    }
                }
            } else {
                self.error = "no suggested filename from download for: \(basename)"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createDownloadState(context: NSManagedObjectContext, basename:String, filename:String, mimeType: String?, encoding: String?, fileSize: Int64, ETag: String?, group: Group?, kind:DownloadKind, title: String?) -> Download {

        let fetch: NSFetchRequest<Download> = Download.fetchRequest()
        fetch.predicate = NSPredicate(format: "basename = %@", basename)

        var download: Download!
        let results = try? context.fetch(fetch)

        if results?.count == 0 {
            // here you are inserting
            let name:NSString = filename as NSString
            download = Download(context: context)
            download.basename = basename
            download.mimeType = mimeType
            download.filename = filename
            download.filesize = fileSize
            download.etag = ETag
            download.ext = name.pathExtension
            download.group = group
            download.kind = kind.rawValue
            download.encoding = encoding
            download.title = title
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
