//
//  RFC+Extension.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/6/23.
//

import SwiftUI
import CoreData


extension RFC {
    var name2: String {
        if let compact = name {
            return compact.enumerated().compactMap({ ($0  == 3) ? " \($1)" : "\($1)" }).joined()
        }
        return "Unnamed"
    }

    // remove leading 0
    var shortLowerName: String {
        if let n = name {
            return n.replacingOccurrences(of: "RFC0", with: "rfc").lowercased()
        }
        return "error"
    }

    var shortStream: String {
        if let orig = stream {
            switch(orig) {
            case "IAB", "IETF", "IRTF":
                return orig
            case "INDEPENDENT":
                return "INDP"
            case "Legacy":
                return "LEGC"
            default:
                return orig
            }
        }
        return "NONE"
    }

    var shortStatus: String {
        switch(currentStatus) {
        case "BEST CURRENT PRACTICE":
            return "BCP"
        case "DRAFT STANDARD":
            return "DS"
        case "EXPERIMENTAL":
            return "EXP"
        case "HISTORIC":
            return "HIST"
        case "INFORMATIONAL":
            return "INFO"
        case "INTERNET STANDARD":
            return "IS"
        case "PROPOSED STANDARD":
            return "PS"
        default:
            return "UNKN"
        }
    }

    // insert space between BCP and 0001
    var presentBCP: String {
        if let name = bcp {
            return name.enumerated().compactMap({ ($0  == 3) ? " \($1)" : "\($1)" }).joined()
        }
        return ""
    }

    // insert space between FYI and 0001
    var presentFYI: String {
        if let name = fyi {
            return name.enumerated().compactMap({ ($0  == 3) ? " \($1)" : "\($1)" }).joined()
        }
        return ""
    }

    // insert space between STD and 0001
    var presentSTD: String {
        if let name = std {
            return name.enumerated().compactMap({ ($0  == 3) ? " \($1)" : "\($1)" }).joined()
        }
        return ""
    }

    var color: Color {
        switch(currentStatus) {
        case "BEST CURRENT PRACTICE":
            return Color(hex: 0x795548) // brown
        case "DRAFT STANDARD":
            return Color(hex: 0xf44336) // red
        case "EXPERIMENTAL":
            return Color(hex: 0x9c27b0) // magenta
        case "HISTORIC":
            return Color(hex: 0x444444) // gray
        case "INFORMATIONAL":
            return Color(hex: 0x009688) // green
        case "INTERNET STANDARD":
            return Color(hex: 0x673ab7) // purple
        case "PROPOSED STANDARD":
            return Color(hex: 0x3f51b5) // dark blue
        default:
            return Color.secondary
        }
    }

    var branch: Bool {
        return updates?.count ?? 0 > 0 ||
            updatedBy?.count ?? 0 > 0 ||
            obsoletes?.count ?? 0 > 0 ||
            obsoletedBy?.count ?? 0 > 0
    }

    func showGraph(colorScheme: ColorScheme, completion: @escaping ((Result<Data, Error>) -> Void)) {
        let graph = buildGraph(start: self, colorScheme: colorScheme)
        graph.render(using: .dot, to: .svg, completion: completion)
    }

    func buildSVG(body: String) -> Download? {
        var dl: Download? = nil
        if let context = self.managedObjectContext {
            do {
                let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                               in: .userDomainMask,
                                                               appropriateFor: nil,
                                                               create: false)
                let basename = "\(self.shortLowerName).svg"
                let url = documentsURL.appendingPathComponent(basename)
                let download = fetchDownload(context: context, kind:.svg, url:url)
                if let download = download {
                    dl = download
                } else {
                    let data = Data(body.utf8)
                    if FileManager.default.createFile(atPath: url.path, contents: data) {
                        dl = Download.create(context:context, basename:basename, filename:basename, mimeType: "image/svg+xml", encoding: "utf-8", fileSize:Int64(body.count), ETag: nil, group:nil, kind:DownloadKind.svg, title:self.name2 + " SVG")
                        do {
                            try context.save()
                        }
                        catch {
                            print("Unable to save Download: \(basename)")
                        }
                    } else {
                        print("save failed for SVG file: \(self.shortLowerName).svg")
                    }
                }
            } catch {
                print("Unable to open documents directory for: \(self.shortLowerName).svg")
            }
        }
        return dl
    }
}
