//
//  NotesView.swift
//  Journy
//
//  Created by Dylan Elliott on 11/10/2023.
//

import SwiftUI
import DylKit

struct NotesViewModel {
    private let notes: NotesDatabase = .init()
    var hasSelectedDirectory: Bool { notes.hasSelectedDirectory }
    
    var noteFiles: [Note] = []
    
    init() {
        load()
    }
    
    mutating func didSelectNotesFolder(_ url: URL) {
        notes.notesDirectoryURL = url
        load()
    }
    
    private mutating func load() {
        noteFiles = Array(notes.getNotes(in: "/")!.sorted(by: { $0.title > $1.title }))
    }
}

struct NotesView: View {
    
    @State var viewModel: NotesViewModel = .init()
    @State var showImporter: Bool = false
    
    var body: some View {
//        ScrollView(.horizontal) {
//            LazyHStack {
//                ForEach(viewModel.noteFiles, id: \.self) { note in
        NoteDetailView(note: viewModel.noteFiles[0])
                        .frame(width: UIScreen.main.bounds.width)
//                }
//            }
//        }
//        .paged()
        .if(!viewModel.hasSelectedDirectory) {
            $0.fileImporter(isPresented: $showImporter, allowedContentTypes: [.folder]) { result in
                showImporter = false
                
                switch result {
                case let .success(url): viewModel.didSelectNotesFolder(url)
                case .failure: break
                }
            }
        }.onAppear {
            showImporter = true
        }
    }
}
