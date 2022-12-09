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
            List(documents, id: \.self, selection: $selectedDocument) { d in
                VStack {
                    Text(d.title!)
                    Text(d.group?.acronym ?? "None")
                }
            }
            .navigationTitle("\(wg) Documents")
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
                //let urlString = "https://datatracker.ietf.org/doc/html/\(d.name!)-\(d.rev!)"
                let urlString = "https://www.ietf.org/archive/id/\(d.name!)-\(d.rev!).html"
                // https://www.ietf.org/archive/id/draft-clemm-nmrg-dist-intent-03.html
                print(urlString)
                loadURL = URL(string: urlString)!
            }
        }
    }
}
