//
//  RFCListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/4/23.
//

import SwiftUI
import CoreData

private extension DateFormatter {
    static let simpleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: Locale.current.identifier)
        return formatter
    }()
}

struct RFCListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @State var selected: RFC? = nil

    @SectionedFetchRequest<String, RFC>(
        sectionIdentifier: \.year!,
        sortDescriptors: [
            NSSortDescriptor(keyPath: \RFC.year, ascending: false),
            NSSortDescriptor(keyPath: \RFC.name, ascending: false),
        ],
        animation: .default)
    private var rfcs: SectionedFetchResults<String, RFC>


    private func makeSpace(rfc: String?) -> String {
        if let rfc = rfc {
            return rfc.enumerated().compactMap({ ($0  == 3) ? " \($1)" : "\($1)" }).joined()
        } else {
            return ""
        }
    }

    private func shortenStatus(status: String?) -> String {
        if let status = status {
            switch(status) {
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
        return "UNKN"
    }

    private func shortenStream(stream: String?) -> String {
        if let stream = stream {
            switch(stream) {
            case "IAB", "IETF", "IRTF":
                return stream
            case "INDEPENDENT":
                return "INDP"
            case "Legacy":
                return "LEGC"
            default:
                return stream
            }
        }
        return ""
    }

    var body: some View {
        List(rfcs, selection: $selected) { section in
            Section {
                ForEach(section, id: \.self) { rfc in
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(makeSpace(rfc: rfc.name))")
                                .foregroundColor(.primary)
                                .font(.title3.bold())
                            Spacer()
                            Text("\(shortenStatus(status: rfc.currentStatus)) \(shortenStream(stream: rfc.stream))")
                                .foregroundColor(.secondary)
                        }
                        Text("\(rfc.title!)")
                            .foregroundColor(.secondary)
                        // future arrow.triangle.pull
                    }
                    .listRowSeparator(.visible)
                }
            } header: {
                Text(section.id)
                    .foregroundColor(.accentColor)
            }
            .headerProminence(.increased)
        }
        .listStyle(.inset)
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onChange(of: selected) { newValue in
            if let doc = newValue {
                print(doc.name!)
            }
        }
        .onAppear {
            if columnVisibility == .all {
                columnVisibility = .doubleColumn
            }
        }
    }
}
