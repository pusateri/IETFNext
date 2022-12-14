//
//  FileLoader.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/13/22.
//

import Foundation

struct FileLoader {
    var session = URLSession.shared

    func downloadFile(from url: URL) async throws -> URL {
        let (localURL, _) = try await session.download(from: url)
        return localURL
    }
}
