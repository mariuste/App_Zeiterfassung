//
//  EditEntryView.swift
//  Zeiterfassung FREILab
//
//  Created by Marius Tetard on 20.04.26.
//

import SwiftUI

struct EditEntryView: View {
    @Environment(\.dismiss) var dismiss
    @State var entry: TimeEntry
    var onSave: (TimeEntry) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    DatePicker("Datum", selection: $entry.date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "de_DE"))
                    
                    DatePicker("Start", selection: $entry.startTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("Ende", selection: $entry.endTime, displayedComponents: .hourAndMinute)
                    
                    TextField("Tätigkeit", text: $entry.taskDescription)
                }
            }
            .navigationTitle("Eintrag bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSave(entry)
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}
