//
//  ContentView.swift
//  Zeiterfassung FREILab
//
//  Created by Marius Tetard on 20.04.26.
//

import SwiftUI
import UniformTypeIdentifiers // WICHTIG für den fileImporter

struct ContentView: View {
    @StateObject private var viewModel = TimeTrackerViewModel()
    @Environment(\.undoManager) var undoManager
    
    #if os(iOS)
    @State private var showFileImporter = false
    #endif
    
    var body: some View {
        VStack(spacing: 0) {
            // Kopfzeile
            HStack {
                Text("Zeiterfassung")
                    .font(.title2.bold())
                
                Spacer()
                
                // 1. IMPORT BUTTON (Nur iOS)
                #if os(iOS)
                Button(action: { showFileImporter = true }) {
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.title2)
                }
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: [.commaSeparatedText],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            viewModel.importExternalCSV(from: url)
                        }
                    case .failure(let error):
                        print("Import Fehler: \(error.localizedDescription)")
                    }
                }
                #endif
                
                // 2. BEENDEN BUTTON (Nur macOS)
                #if os(macOS)
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                #endif
            }
            .padding()

            SummaryView(viewModel: viewModel)
                .padding([.horizontal, .bottom])

            // ... Rest der View (Liste, NewEntryView etc.) bleibt gleich ...
            ScrollViewReader { proxy in
                List {
                    ForEach(viewModel.filteredEntries) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.taskDescription)
                                Text(itemFormatter.string(from: entry.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.2f h", entry.durationHours))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.editingEntry = entry
                        }
                        .id(entry.id)
                    }
                    .onDelete { offsets in
                        viewModel.deleteEntry(at: offsets, undoManager: undoManager)
                    }
                }
                .onChange(of: viewModel.filteredEntries.count) {
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }
            
            Divider()
            NewEntryView(viewModel: viewModel).padding()
        }
        #if os(macOS)
        .frame(minWidth: 550, minHeight: 600)
        #endif
    }
    
    // Hilfsfunktionen (scrollToBottom, itemFormatter) hier lassen...
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let lastId = viewModel.filteredEntries.last?.id {
                withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
            }
        }
    }
    
    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
}
