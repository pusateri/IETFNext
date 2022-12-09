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
    @Binding var loadURL: URL?

    init(wg: String, loadURL: Binding<URL?>) {
        _documents = FetchRequest<Document>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Document.name, ascending: true)],
            predicate: NSPredicate(format: "ANY group.acronym = %@", wg),
            animation: .default)
        self.wg = wg
        self._loadURL = loadURL
    }

    var body: some View {
        NavigationView {
            List(selection: $selectedDocument) {
                Section("Drafts") {
                    ForEach(documents, id: \.self) { d in
                        VStack(alignment: .leading) {
                            Text(d.title!)
                            Text(d.name!)
                                .font(.subheadline)
                                .foregroundColor(Color(.gray))
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
                let urlString = "https://datatracker.ietf.org/doc/html/\(d.name!)-\(d.rev!)"
                loadURL = URL(string: urlString)!
            }
        }
    }
}
