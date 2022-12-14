//
//  DownloadViewModel.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/13/22.
//

import Foundation

@MainActor
class DownloadViewModel: NSObject, ObservableObject {
    static let shared = DownloadViewModel()
    @Published private(set) var isBusy = false
    @Published private(set) var error: String? = nil
    @Published private(set) var fileType: String? = nil
    @Published private(set) var fileName: String? = nil
    @Published private(set) var fileSize: UInt64? = nil
    @Published private(set) var downloadDate: Date? = nil

    // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
    func downloadInMemory(urlString: String) async {
        self.isBusy = true
        self.error = nil
        self.fileType = nil
        self.fileName = nil
        self.fileSize = nil

        defer {
            self.isBusy = false
        }

        do {
            let request = URLRequest(url: URL(string: urlString)!)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                self.error = "No HTTP Result"
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                self.error =  "Http Result: \(httpResponse.statusCode)"
                return
            }

            self.error = nil
            self.fileName = nil
            self.fileSize = UInt64(data.count)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_from_websites
    func downloadToFile(urlString: String) async {
        self.isBusy = true
        self.error = nil
        self.fileName = nil
        self.fileSize = nil

        defer {
            self.isBusy = false
        }

        do {
            let (localURL, response) = try await URLSession.shared.download(from: URL(string: urlString)!)
            guard let httpResponse = response as? HTTPURLResponse else {
                self.error = "No HTTP Result"
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                self.error = "Http Result: \(httpResponse.statusCode)"
                return
            }

            let attributes = try FileManager.default.attributesOfItem(atPath: localURL.path)

            self.error = nil
            self.fileName = localURL.path
            self.fileSize = attributes[.size] as! UInt64?
            self.fileType = attributes[.type] as! String?
            self.downloadDate = attributes[.creationDate] as! Date?
        } catch {
            self.error = error.localizedDescription
        }
    }

    func covertToFileString(with size: UInt64) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }
}
