//
//  RFCListRowView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/16/23.
//

import SwiftUI
import CoreData
import GraphViz

private extension DateFormatter {
    static let simpleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/YY"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: Locale.current.identifier)
        return formatter
    }()
}


struct RFCListRowView: View {
    @ObservedObject var rfc: RFC
    @Binding var rfcFilterMode: RFCFilterMode
    var listMode: SidebarOption
    @Binding var shortTitle: String?
    @Binding var longTitle: String?
    @Binding var selectedDownload: Download?

    var body: some View {
        HStack {
            Rectangle()
                .fill(rfc.color)
                .frame(width: 8, height: 42)
            VStack(alignment: .leading) {
                HStack {
                    switch(listMode) {
                        case .bcp:
                            Text("\(rfc.presentBCP)")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(rfc.name2)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        case .fyi:
                            Text("\(rfc.presentFYI)")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(rfc.name2)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        case .std:
                            Text("\(rfc.presentSTD)")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(rfc.name2)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        default:
                            Text("\(rfc.name2)")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            Spacer()
                            switch(rfcFilterMode) {
                                case .bcp:
                                    Text("\(rfc.presentBCP)")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                case .fyi:
                                    Text("\(rfc.presentFYI)")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                case .std:
                                    Text("\(rfc.presentSTD)")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                case .none:
                                    Text("\(rfc.shortStatus) \(rfc.shortStream)")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                            }
                    }
                }
                HStack {
                    Text("\(rfc.title!)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    VStack {
                        Text("\(DateFormatter.simpleFormatter.string(from: rfc.published!))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if rfc.branch {
#if !os(macOS)
                            if UIDevice.isIPhone {
                                Image(systemName: "arrow.triangle.pull")
                                    .font(Font.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(hex: 0xf6c844))
                                    .padding(.top, 2)
                            } else {
                                BranchButtonView(rfc: rfc, shortTitle: $shortTitle, longTitle: $longTitle, selectedDownload: $selectedDownload)
                            }
#else
                            BranchButtonView(rfc: rfc, shortTitle: $shortTitle, longTitle: $longTitle, selectedDownload: $selectedDownload)
#endif
                        }
                    }
                }
            }
        }
    }
}

struct BranchButtonView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var rfc: RFC
    @Binding var shortTitle: String?
    @Binding var longTitle: String?
    @Binding var selectedDownload: Download?

    var body: some View {
        Button(action: {
            longTitle = rfc.title
            shortTitle = rfc.name2
            rfc.showGraph(colorScheme: colorScheme) { result in
                switch result {
                    case .success(let data):
                        if let str = String(data: data, encoding: .utf8) {
                            if let context = rfc.managedObjectContext {
                                context.performAndWait {
                                    selectedDownload = rfc.buildSVG(body: str)
                                }
                            }
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }
        }) {
            Image(systemName: "arrow.triangle.pull")
                .font(Font.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: 0xf6c844))

        }
        .buttonStyle(BorderlessButtonStyle())
        .padding(.top, 2)
    }
}
