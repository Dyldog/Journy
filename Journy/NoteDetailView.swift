//
//  NoteDetailView.swift
//  Journy
//
//  Created by Dylan Elliott on 11/10/2023.
//

import SwiftUI
import DylKit
import HighlightedTextEditor

struct JournalEntry: Hashable, Equatable {
    let time: Date
    let text: String
}

class NoteDetailViewModel: NSObject, ObservableObject {
    struct Row: Hashable, Equatable {
        let time: String
        let text: Binding<String>
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(time)
            hasher.combine(text.wrappedValue)
        }
        
        static func ==(lhs: Row, rhs: Row) -> Bool {
            return lhs.time == rhs.time && lhs.text.wrappedValue == rhs.text.wrappedValue
        }
    }
    private var note: Note
    private let database: NotesDatabase = .init()
    
    private var journalSectionIndex: Int?
    private var entries: [JournalEntry] = []
    
    var title: String { note.title }
    private(set) var rows: [Row] = []
    
    private let journalRegex: NSRegularExpression = try! .init(
        pattern: "^- \\*\\*(\\d+:\\d+(?:am|pm))\\*\\*: ?([\\s\\S]*?)\\n(?=^-|\\Z)",
        options: .anchorsMatchLines
    )
        
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mma"
        return formatter
    }()
    
    init(note: Note) {
        self.note = note
        super.init()
        load()
    }
    
    var noteIsForToday: Bool {
        return dateFormatter.string(from: .now) == title
    }
    
    func onAppear() {
        load(reloadNote: true)
    }
    
    private func load(reloadNote: Bool = false) {
        if reloadNote, let note = database.getNote(note.path) {
            self.note = note
        }
        
        guard let index = note.sections.firstIndex(where: { $0.title == "Journal" }) else { return }
        
        journalSectionIndex = index
        let journalSection = note.sections[index]
        
        entries = journalRegex.matches(in: journalSection.contents).map {
            entry(from: $0, in: journalSection.contents)
        }.sorted(by: { $0.time > $1.time })
        
        rows = entries.enumerated().map { index, entry in
            .init(
                time: timeFormatter.string(from: entry.time),
                text: .init(get: { [weak self] in
                    self!.entries[index].text
                }, set: { [weak self] in
                    guard let existing = self?.entries[index] else { return }
                    self?.entries[index] = .init(time: existing.time, text: $0)
                    self?.saveNoteFromEntries(reload: false)
                })
            )
        }
        
        if reloadNote {
            objectWillChange.send()
        }
    }
    
    private func entry(from result: NSTextCheckingResult, in string: String) -> JournalEntry {
        let timeString = string.substring(with: result.range(at: 1))
        let date = timeFormatter.date(from: timeString.uppercased())!
        
        return .init(
            time: date,
            text: string.substring(with: result.range(at: 2))
        )
    }
    
    func newEntry(content: String = "") {
        entries.append(.init(time: .now, text: content))
        saveNoteFromEntries(reload: true)
    }
    
    private func saveNoteFromEntries(reload: Bool) {
        func reloadNoteFromEntries() {
            guard let journalSectionIndex = journalSectionIndex else { return }
            note = note.replaceSectionContents(
                at: journalSectionIndex,
                with: entries.sorted(by: { $0.time < $1.time }).map {
                    "- **\(timeFormatter.string(from: $0.time))**: \($0.text)"
                }
                .joined(separator: "\n")
            )
        }
        
        reloadNoteFromEntries()
        database.writeNote(note.contents, in: note.path)
        load(reloadNote: reload)
    }
    
    func handleURLScheme(url: URL) {
        guard let content = url.host else { return }
        newEntry(content: content)
    }
}

struct NoteDetailView: View {
    
    @StateObject var viewModel: NoteDetailViewModel
    @Environment(\.scenePhase) var scenePhase

    
    // TODO: Move to view model
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mma"
        return formatter
    }()
    
    init(note: Note) {
        self._viewModel = .init(wrappedValue: .init(note: note))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(viewModel.title)
                .font(.youngSerif(size: 24))
                .padding([.horizontal, .bottom])
            
            if viewModel.rows.isEmpty {
                emptyView
            } else {
                listView
            }
            
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.onAppear()
            }
        }.if(viewModel.noteIsForToday) {
            $0.onOpenURL { url in
                viewModel.handleURLScheme(url: url)
            }
        }
    }
    
    var listView: some View {
        List {
            ForEach(Array(viewModel.rows.enumerated()), id: \.offset) { index, entry in
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.time)
                        .font(.youngSerif(size: 18))
                        .foregroundColor(.red)
                        .brightness(-0.4)
                    TextView("Entry", text: entry.text)
                        .font(.youngSerif(size: 24))
                        .placeholderFont(.youngSerif(size: 24))
                        .enableScrolling(false)
//                        .if(index == 0 && entry.text.wrappedValue.isEmpty) {
//                            $0.becomeFirstResponder()
//                        }
                }
            }
        }
        .listStyle(.plain)
        .resignKeyboardOnDragGesture()
        .refreshable {
            viewModel.newEntry()
        }
    }
    
    var emptyView: some View {
        VStack {
            Spacer()
            Button {
                viewModel.newEntry()
            } label: {
                Text("No entries.\nWhy not add one?")
                    .font(.youngSerif(size: 18))
            }

            Spacer()
        }
    }
}
