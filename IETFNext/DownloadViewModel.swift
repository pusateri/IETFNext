//
//  DownloadViewModel.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/13/22.
//

import Foundation

@MainActor
class DownloadForegroundViewModel: NSObject, ObservableObject {
    let urlToDownloadFormat = "https://speed.hetzner.de/%1$@.bin"
    let availableDownloadSizes = ["100MB", "1GB", "10GB", "ERR"]
    var selectedDownloadSize: String = "100MB"
    var fileToDownload: String {
        get {
            String(format: urlToDownloadFormat, selectedDownloadSize)
        }
    }

    @Published private(set) var isBusy = false
    @Published private(set) var error: String? = nil
    @Published private(set) var percentage: Int? = nil
    @Published private(set) var fileName: String? = nil
    @Published private(set) var downloadedSize: UInt64? = nil

    // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
    func downloadInMemory() async {
        self.isBusy = true
        self.error = nil
        self.percentage = 0
        self.fileName = nil
        self.downloadedSize = nil

        defer {
            self.isBusy = false
        }

        do {
            let request = URLRequest(url: URL(string: fileToDownload)!)
            let (data, response) = try await URLSession.shared.compatibilityData(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                self.error = "No HTTP Result"
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                self.error =  "Http Result: \(httpResponse.statusCode)"
                return
            }

            self.error = nil
            self.percentage = 100
            self.fileName = nil
            self.downloadedSize = UInt64(data.count)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_from_websites
    func downloadToFile() async {
        self.isBusy = true
        self.error = nil
        self.percentage = 0
        self.fileName = nil
        self.downloadedSize = nil

        defer {
            self.isBusy = false
        }

        do {
            let (localURL, response) = try await URLSession.shared.compatibilityDownload(from: URL(string: fileToDownload)!)
            guard let httpResponse = response as? HTTPURLResponse else {
                self.error = "No HTTP Result"
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                self.error = "Http Result: \(httpResponse.statusCode)"
                return
            }

            let attributes = try FileManager.default.attributesOfItem(atPath: localURL.path)
            let fileSize = attributes[.size] as? UInt64

            self.error = nil
            self.percentage = 100
            self.fileName = localURL.path
            self.downloadedSize = fileSize
        } catch {
            self.error = error.localizedDescription
        }
    }
}
