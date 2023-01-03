//
//  RFCParser.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/2/23.
//

import Foundation
import CoreData


enum RFCFormat: String {
    case ASCII
    case HTML
    case XML
}

struct RFC {
    init(details: [String: Any]) {
        docid = details["doc-id"] as? String ?? ""
        title = details["title"] as? String ?? ""
        authors = []
        published = Date()
        formats = []
        pageCount = details["page-count"] as? Int ?? 0
        curStatus = details["current-status"] as? String ?? ""
        pubStatus = details["publication-status"] as? String ?? ""
        stream = details["stream"] as? String ?? ""
        doi = details["doi"] as? String ?? ""
    }

    let docid: String
    let title: String
    let authors: [String]
    let published: Date
    let formats: Set<RFCFormat>
    let pageCount: Int
    let curStatus: String
    let pubStatus: String
    let stream: String
    let doi: String
}
enum EntryType {
    case bcp
    case child
    case fyi
    case rfc
    case rfc_not_issued
    case std
    case unknown
}

enum Entry {
    case bcp(RFC)
    case fyi(RFC)
    case rfc(RFC)
    case rfc_not_issued(RFC)
    case std(RFC)
    case unknown
}

class RFCParser: NSObject, XMLParserDelegate {
    var parentType: EntryType = .unknown
    var xmlDict = [String: Any]()
    var xmlChildDict = [String: Any]()
    var xmlDictArr = [[String: Any]]()
    var currentElement = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        var type: EntryType = .child

        switch(elementName) {
        case "bcp-entry":
            type = .bcp
        case "fyi-entry":
            type = .fyi
        case "rfc-entry":
            type = .rfc
        case "rfc-not-issued-entry":
            type = .rfc_not_issued
        case "std-entry":
            type = .std

        default:
            if elementName.contains("-entry") {
                // unknown new top level entry
                type = .unknown
            }
        }
        xmlDict = ["type": type]

        if type == .child {
            currentElement = elementName
            xmlChildDict = [:]
        } else {
            parentType = type
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if parentType != .child {
                if xmlDict[currentElement] == nil {
                    xmlDict.updateValue(string, forKey: currentElement)
                }
            } else {
                // TODO: handle array
                if xmlChildDict[currentElement] == nil {
                    xmlChildDict.updateValue(string, forKey: currentElement)
                }
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch(elementName) {
        case "bcp-entry", "fyi-entry", "rfc-entry", "rfc-not-issued-entry", "std-entry":
            xmlDictArr.append(xmlDict)
        default:
            if elementName.contains("-entry") {
                // unknown new top level entry
                xmlDictArr.append(xmlDict)
                print("New top level element type in RFC Index: \(elementName)")
            } else {
                xmlDict.updateValue(xmlChildDict, forKey: elementName)
            }
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        for d in self.xmlDictArr {
            if d["type"] as? EntryType == .bcp {
                print(d.keys.sorted())
            }
        }
        /*
        let entries: [Entry] = self.xmlDictArr.map {
            switch($0["type"] as? String) {
            case "rfc-entry":
                return Entry.rfc(RFC(details: $0))
            default:
                return Entry.unknown
            }
        }
         */
    }

    func loadRFCindex(/*context: NSManagedObjectContext*/) async {

        /*
        let backgroundQueue = DispatchQueue(label: "com.bangj.queue",
                                                    qos: .background,
                                                    target: nil)
        backgroundQueue.async {
            //call to 'parse' function of XMLParser
            DispatchQueue.main.async {
                //pass parsing result to UI on main thread
            }
        }
         */
        let urlString = "https://www.rfc-editor.org/rfc-index.xml"

        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        var urlrequest = URLRequest(url: url)
        urlrequest.addValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        do {
            let (data, _) = try await URLSession.shared.data(for: urlrequest)
            let parser = XMLParser(data: data)
            parser.delegate = self
            let success = parser.parse()
            if success {
                print("done")
            } else {
                print("error \(parser.parserError!)")
            }
        } catch {
            print("Unable to download rfc index")
        }
    }
}
