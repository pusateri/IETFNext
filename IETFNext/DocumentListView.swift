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

    init(wg: String, urlString: Binding<String?>) {
        _documents = FetchRequest<Document>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Document.name, ascending: true),
                NSSortDescriptor(keyPath: \Document.rev, ascending: true),
            ],
            predicate: NSPredicate(format: "(ANY group.acronym = %@) AND (type contains \"draft\")", wg),
            animation: .default)
        self.wg = wg
        self._urlString = urlString
    }

    var body: some View {
        NavigationView {
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
            .navigationTitle("\(wg)")
            .navigationBarTitleDisplayMode(.inline)
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
                urlString = "https://www.ietf.org/archive/id/\(d.name!)-\(d.rev!).html"
            }
        }
    }
}
