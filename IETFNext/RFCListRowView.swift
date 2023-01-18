//
//  RFCListRowView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/16/23.
//

import SwiftUI
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
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var rfc: RFC
    @Binding var rfcFilterMode: RFCFilterMode
    @Binding var html: String

    @State var oldColorScheme: ColorScheme? = nil

    var body: some View {
        HStack {
            Rectangle()
                .fill(rfc.color)
                .frame(width: 8, height: 42)
            VStack(alignment: .leading) {
                HStack {
                    Text("\(rfc.name2)")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    Spacer()
                    switch(rfcFilterMode) {
                        case .bcp:
                            Text("\(rfc.bcp ?? "")")
                                .font(.body)
                                .foregroundColor(.secondary)
                        case .fyi:
                            Text("\(rfc.fyi ?? "")")
                                .font(.body)
                                .foregroundColor(.secondary)
                        case .std:
                            Text("\(rfc.std ?? "")")
                                .font(.body)
                                .foregroundColor(.secondary)
                        case .none:
                        Text("\(rfc.shortStatus) \(rfc.shortStream)")
                            .font(.body)
                            .foregroundColor(.secondary)
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
                            Button(action: {
                                showGraph(rfc: rfc, colorScheme: colorScheme)
                            }) {
                                Image(systemName: "arrow.triangle.pull")
                                    .font(Font.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(hex: 0xf6c844))

                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.top, 2)
                        }
                    }
                }
            }
        }
    }
}

extension RFCListRowView {
    func showGraph(rfc: RFC, colorScheme: ColorScheme) {
        let graph = buildGraph(start: rfc, colorScheme: colorScheme)
        graph.render(using: .dot, to: .svg) { result in
            guard case .success(let data) = result else { return }
            if let str = String(data: data, encoding: .utf8) {
                html = SVG_PRE + str + SVG_POST
            }
        }
    }
}
