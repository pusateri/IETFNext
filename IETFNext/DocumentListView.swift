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
                Picker("Document Type", selection: $kind) {
                    Text("Active Drafts").tag(DocumentKind.draft)
                    Text("Related Drafts").tag(DocumentKind.related)
                }
                .pickerStyle(.segmented)
                List(selection: $selectedDocument) {
                    Section("Drafts") {
                        ForEach(documents, id: \.self) { d in
                            VStack(alignment: .leading) {
                                Text(d.title!)
                                    .foregroundColor(.primary)
                                Text("\(d.name!)-\(d.rev!)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .headerProminence(.increased)
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
        .onChange(of: selectedDocument) { newValue in
            if let d = selectedDocument {
                dismiss()
                // htmlized
                // let urlString = "https://datatracker.ietf.org/doc/html/\(d.name!)-\(d.rev!)"
                // native html

                // set titleString before urlString since we are only acting on changes to urlString
                titleString = d.title
                urlString = "https://www.ietf.org/archive/id/\(d.name!)-\(d.rev!).html"

            }
        }
    }
}
