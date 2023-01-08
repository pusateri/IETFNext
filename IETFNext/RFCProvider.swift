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

    // MARK: Core Data

    /// A shared RFC provider for use within the main app bundle.
    static let shared = RFCProvider()

    private var notificationToken: NSObjectProtocol?

    private init() {
        // Observe Core Data remote change notifications on the queue where the changes were made.
        notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil) { note in
            self.logger.debug("Received a persistent store remote change notification.")
            Task {
                await self.fetchPersistentHistory()
            }
        }
    }

    deinit {
        if let observer = notificationToken {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// A peristent history token used for fetching transactions from the store.
    private var lastToken: NSPersistentHistoryToken?

    /// A persistent container to set up the Core Data stack.
    lazy var container: NSPersistentContainer = {
        /// - Tag: persistentContainer
        let container = NSPersistentContainer(name: "IETFNext")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // Enable persistent store remote change notifications
        /// - Tag: persistentStoreRemoteChange
        description.setOption(true as NSNumber,
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Enable persistent history tracking
        /// - Tag: persistentHistoryTracking
        description.setOption(true as NSNumber,
                              forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // refresh UI by consuming store changes via persistent history tracking.
        /// - Tag: viewContextMergeParentChanges
        container.viewContext.automaticallyMergesChangesFromParent = false
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
            logger.debug("Received \(xml["rfc-index"].sequence.count) records.")

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

        await taskContext.perform {
            for rfc in from["rfc-entry"] {
                updateRFC(context: taskContext, xml: rfc)
            }
        }

        logger.debug("Successfully inserted data.")
    }

    /// Synchronously deletes given records in the Core Data store with the specified object IDs.
    func deleteRFCs(identifiedBy objectIDs: [NSManagedObjectID]) {
        let viewContext = container.viewContext
        logger.debug("Start deleting data from the store...")

        viewContext.perform {
            objectIDs.forEach { objectID in
                let rfc = viewContext.object(with: objectID)
                viewContext.delete(rfc)
            }
        }

        logger.debug("Successfully deleted data.")
    }

    /// Asynchronously deletes records in the Core Data store with the specified `RFC` managed objects.
    func deleteRFCs(_ rfcs: [RFC]) async throws {
        let objectIDs = rfcs.map { $0.objectID }
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "deleteContext"
        taskContext.transactionAuthor = "deleteRFCs"
        logger.debug("Start deleting data from the store...")

        try await taskContext.perform {
            // Execute the batch delete.
            let batchDeleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
            guard let fetchResult = try? taskContext.execute(batchDeleteRequest),
                  let batchDeleteResult = fetchResult as? NSBatchDeleteResult,
                  let success = batchDeleteResult.result as? Bool, success
            else {
                self.logger.debug("Failed to execute batch delete request.")
                throw IETFNextError.batchDeleteError
            }
        }

        logger.debug("Successfully deleted data.")
    }

    func fetchPersistentHistory() async {
        do {
            try await fetchPersistentHistoryTransactionsAndChanges()
        } catch {
            logger.debug("\(error.localizedDescription)")
        }
    }

    private func fetchPersistentHistoryTransactionsAndChanges() async throws {
        let taskContext = newTaskContext()
        taskContext.name = "persistentHistoryContext"
        logger.debug("Start fetching persistent history changes from the store...")

        try await taskContext.perform {
            // Execute the persistent history change since the last transaction.
            /// - Tag: fetchHistory
            let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
            let historyResult = try taskContext.execute(changeRequest) as? NSPersistentHistoryResult
            if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
               !history.isEmpty {
                self.mergePersistentHistoryChanges(from: history)
                return
            }

            self.logger.debug("No persistent history transactions found.")
            throw IETFNextError.persistentHistoryChangeError
        }

        logger.debug("Finished merging history changes.")
    }

    private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
        self.logger.debug("Received \(history.count) persistent history transactions.")
        // Update view context with objectIDs from history change request.
        /// - Tag: mergeChanges
        let viewContext = container.viewContext
        viewContext.perform {
            for transaction in history {
                viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                self.lastToken = transaction.token
            }
        }
    }
}

