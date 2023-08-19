//
//  Download+Extension.swift
//  IETFNext
//
//  Created by Tom Pusateri on 8/18/23.
//

import SwiftUI
import CoreData

extension Download {

    class func create(context: NSManagedObjectContext, basename:String, filename:String, mimeType: String?, encoding: String?, fileSize: Int64, ETag: String?, group: Group?, kind:DownloadKind, title: String?) -> Download {

        var download: Download!

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

        return download
    }
}
