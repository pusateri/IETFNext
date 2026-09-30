//
//  DownloadViewModel.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/13/22.
//

import Foundation
import CoreData
import UniformTypeIdentifiers
import Observation


@MainActor
@Observable
final class DownloadViewModel {
    private(set) var isBusy = false
    var download: Download? = nil
    private(set) var error: String? = nil

    /// The in-flight download started by `startDownload`. Owned here so it can be cancelled.
    @ObservationIgnored private var downloadTask: Task<Void, Never>?

    /// Starts a download owned by this model. A newer request cancels an older one that is
    /// still in flight, so the most recent selection is the one that ends up displayed.
    func startDownload(context: NSManagedObjectContext, url: URL, group: Group?, kind: DownloadKind, title: String?) {
        downloadTask?.cancel()
        downloadTask = Task {
            await downloadToFile(context: context, url: url, group: group, kind: kind, title: title)
        }
    }

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
            // A newer request superseded this one; don't overwrite its result.
            try Task.checkCancellation()
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

                    // Pass the group by objectID (Sendable) and re-resolve it inside the context's queue.
                    // Return the result instead of mutating main-actor state from inside the closure.
                    let groupID = group?.objectID
                    self.download = context.performAndWait { () -> Download? in
                        let fetch: NSFetchRequest<Download> = Download.fetchRequest()
                        fetch.predicate = NSPredicate(format: "basename = %@", basename)
                        let results = try? context.fetch(fetch)

                        if results?.count == 0 {
                            let contextGroup = groupID.flatMap { context.object(with: $0) as? Group }
                            let dl = Download.create(context:context, basename:basename, filename:suggested, mimeType: httpResponse.mimeType, encoding: httpResponse.textEncodingName, fileSize:httpResponse.expectedContentLength, ETag: httpResponse.value(forHTTPHeaderField: "ETag"), group:contextGroup, kind:kind, title:title)
                            do {
                                try context.save()
                            }
                            catch {
                                print("Unable to save Download: \(basename)")
                            }
                            return dl
                        } else {
                            print("Download \(basename) already exists")
                            return results?.first
                        }
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
        } catch is CancellationError {
            // Superseded or the screen went away; not an error worth surfacing.
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession reports task cancellation as URLError.cancelled.
        } catch {
            self.error = error.localizedDescription
        }
    }
}
