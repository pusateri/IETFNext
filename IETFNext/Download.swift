//
//  Download.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/11/22.
//

import Foundation
import OSLog

class DownloadManager: NSObject, ObservableObject {
    static var shared = DownloadManager()

    private var urlSession: URLSession!
    @Published var tasks: [URLSessionTask] = []

    override private init() {
        super.init()

        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")

        // Warning: Make sure that the URLSession is created only once (if an URLSession still
        // exists from a previous download, it doesn't create a new URLSession object but returns
        // the existing one with the old delegate object attached)
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())

        updateTasks()
    }

    func startDownload(url: URL) {
        let task = urlSession.downloadTask(with: url)
        task.resume()
        tasks.append(task)
    }

    private func updateTasks() {
        urlSession.getAllTasks { tasks in
            DispatchQueue.main.async {
                self.tasks = tasks
            }
        }
    }
}

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    /*
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten _: Int64, totalBytesExpectedToWrite _: Int64) {
        let log = Logger()
        log.debug("Progress \(downloadTask.progress.fractionCompleted) for \(downloadTask)")
    }
     */
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let log = Logger()
        log.info("Download finished: \(downloadTask.originalRequest!)") //\(location.absoluteString)")
        // The file at location is temporary and will be gone afterwards
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let log = Logger()
        if let error = error {
            log.error("Download error: \(String(describing: error))")
        }
    }
}
