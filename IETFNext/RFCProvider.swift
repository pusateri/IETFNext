//
//  RFCProvider.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/6/23.
//

import CoreData
import OSLog
import SwiftyXMLParser

class RFCProvider {

    let url = URL(string: "https://www.rfc-editor.org/rfc-index.xml")!

    // MARK: Logging

    let logger = Logger(subsystem: "com.bangj.IETFNext", category: "persistence")

    /// A shared RFC provider for use within the main app bundle.
    static let shared = RFCProvider()

    /// A peristent history token used for fetching transactions from the store.
    private var lastToken: NSPersistentHistoryToken?

    /// A persistent container to set up the Core Data stack.
    lazy var container: NSPersistentContainer = {
        /// - Tag: persistentContainer
        let container = NSPersistentContainer(name: "IETFNext")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        return container
    }()

    /// Creates and configures a private queue context.
    private func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }

    func fetchRFCs() async throws {
        var urlrequest = URLRequest(url: url)

        urlrequest.addValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        if let lastEtag = UserDefaults.standard.string(forKey:"rfcIndexEtag") {
            urlrequest.addValue(lastEtag, forHTTPHeaderField: "If-None-Match")
            urlrequest.cachePolicy = .reloadIgnoringLocalCacheData
        }

        let (data, response) = try await URLSession.shared.data(for: urlrequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.debug("Failed to received valid response and/or data.")
            throw IETFNextError.missingData
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            logger.debug("Http Result \(httpResponse.statusCode): \(self.url.absoluteString)")
            if httpResponse.statusCode != 304 {
                throw IETFNextError.missingData
            } else {
                throw IETFNextError.http304Code
            }
        }
        if let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
            let newEtag = etag.replacingOccurrences(of: "-gzip", with: "")
            UserDefaults.standard.set(newEtag, forKey:"rfcIndexEtag")
        }
        if let modified = httpResponse.value(forHTTPHeaderField: "Last-Modified") {
            UserDefaults.standard.set(modified, forKey:"rfcIndexLastModified")
        }
        let string = String(decoding: data, as: UTF8.self)
        do {
            let xml = try XML.parse(string)
            let num = xml["rfc-index"]["rfc-entry"].all?.count
            logger.debug("Received \(num ?? 0) records.")

            logger.debug("Start importing rfc data to the store...")
            try await importRFCs(from: xml["rfc-index"])
            logger.debug("Finished importing rfc data.")

        } catch XMLError.interruptedParseError {
            print("XML parse of RFC index failed: invalid character")
        } catch {
            print("XML parse of RFC index failed")
        }
    }

    private func importRFCs(from: XML.Accessor) async throws {

        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importContext"
        taskContext.transactionAuthor = "importRFCs"

        var updates: [String: [String]] = [:]
        var obsoletes: [String: [String]] = [:]
        await taskContext.perform {
            for rfc in from["rfc-entry"] {
                updateRFC(context: taskContext, xml: rfc, obsoletes: &obsoletes, updates: &updates)
            }
            for update in updates {
                if let rfc = findRFC(context: taskContext, name: update.key) {
                    for item in update.value {
                        if let updated = findRFC(context: taskContext, name: item) {
                            //print("\(rfc.name!) updates \(updated.name!)")
                            rfc.addToUpdates(updated)
                        }
                    }
                }
            }
            for obsolete in obsoletes {
                if let rfc = findRFC(context: taskContext, name: obsolete.key) {
                    for item in obsolete.value {
                        if let obsoleted = findRFC(context: taskContext, name: item) {
                            //print("\(rfc.name!) obsoletes \(obsoleted.name!)")
                            rfc.addToObsoletes(obsoleted)
                        }
                    }
                }
            }
            do {
                try taskContext.save()
            }
            catch {
                self.logger.debug("Unable to save after adding updates/obsoletes")
            }
        }
        logger.debug("Successfully inserted data.")
    }
}

