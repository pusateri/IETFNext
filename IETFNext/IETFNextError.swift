//
//  IETFNextError.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/6/23.
//

import Foundation

enum IETFNextError: Error {
    case wrongDataFormat(error: Error)
    case missingData
    case creationError
    case batchInsertError
    case batchDeleteError
    case persistentHistoryChangeError
    case unexpectedError(error: Error)
    case http304Code
}

extension IETFNextError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .wrongDataFormat(let error):
            return NSLocalizedString("Could not digest the fetched data. \(error.localizedDescription)", comment: "")
        case .missingData:
            return NSLocalizedString("Found and will discard an entry missing data", comment: "")
        case .http304Code:
            return NSLocalizedString("Data hasn't changed", comment: "")
        case .creationError:
            return NSLocalizedString("Failed to create a new object.", comment: "")
        case .batchInsertError:
            return NSLocalizedString("Failed to execute a batch insert request.", comment: "")
        case .batchDeleteError:
            return NSLocalizedString("Failed to execute a batch delete request.", comment: "")
        case .persistentHistoryChangeError:
            return NSLocalizedString("Failed to execute a persistent history change request.", comment: "")
        case .unexpectedError(let error):
            return NSLocalizedString("Received unexpected error. \(error.localizedDescription)", comment: "")
        }
    }
}

extension IETFNextError: Identifiable {
    var id: String? {
        errorDescription
    }
}
