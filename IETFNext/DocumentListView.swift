//
//  DocumentListView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/8/22.
//

import SwiftUI
import CoreData

struct DocumentListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @FetchRequest<Document> var documents: FetchedResults<Document>
    var wg: String
    @State var selectedDocument: Document? = nil
    @Binding var urlString: String?
    @Binding var titleString: String?
    var predicate: NSPredicate
    @Binding var kind: DocumentKind

    init(wg: String, urlString: Binding<String?>, titleString: Binding<String?>, kind: Binding<DocumentKind>) {
        self._kind = kind
        self.wg = wg
        self._urlString = urlString
        self._titleString = titleString

        switch(kind.wrappedValue) {
        case .charter:
            predicate = NSPredicate(value: false)
        case .draft:
            predicate = NSPredicate(format: "(ANY group.acronym = %@) AND (type contains \"draft\")", wg)
        case .related:
            predicate = NSPredicate(format: "(ANY relatedGroup.acronym = %@) AND (type contains \"draft\")", wg)
        case .rfc:
            predicate = NSPredicate(value: false)
        }

        _documents = FetchRequest<Document>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Document.name, ascending: true),
                NSSortDescriptor(keyPath: \Document.rev, ascending: true),
            ],
            predicate: predicate,
            animation: .default)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                Picker("", selection: $kind) {
                    Text("Active Drafts")
                        .tag(DocumentKind.draft)
                    Text("Related Drafts")
                        .tag(DocumentKind.related)
                }
                .pickerStyle(.segmented)
                .padding()
                List(selection: $selectedDocument) {
                    ForEach(documents, id: \.self) { d in
                        VStack(alignment: .leading) {
                            Text(d.title!)
                                .font(.title2)
                                .foregroundColor(.primary)
#if os(macOS)
                                .padding(.all, 3)
#endif
                            Text("\(d.name!)-\(d.rev!)")
                                .font(.headline)
                                .foregroundColor(.secondary)
#if os(macOS)
                                .padding(.bottom, 3)
#endif
                        }

                        .listRowSeparator(.visible)
                    }
                }
                .listStyle(.inset)
            }
            .navigationTitle("\(wg)")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
#if os(macOS)
        .frame(width: 600, height: 740)
#endif
        .onChange(of: selectedDocument) { newValue in
            if let d = newValue {
                dismiss()
                // htmlized
                // let urlString = "https://datatracker.ietf.org/doc/html/\(d.name!)-\(d.rev!)"
                // txt format
                // let urlString = "https://www.ietf.org/archive/id/\(d.name!)-\(d.rev!).txt"

                // set titleString before urlString since we are only acting on changes to urlString
                titleString = d.title
                // native html
                urlString = "https://www.ietf.org/archive/id/\(d.name!)-\(d.rev!).html"

            }
        }
        .onAppear {
            kind = .draft
        }
    }
}
