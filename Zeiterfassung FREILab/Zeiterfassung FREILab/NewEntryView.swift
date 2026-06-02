//
//  NewEntryView.swift
//  Zeiterfassung FREILab
//
//  Created by Marius Tetard on 20.04.26.
//

import SwiftUI

struct NewEntryView: View {
    @ObservedObject var viewModel: TimeTrackerViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // Erste Zeile: Datum und Zeiten
            adaptiveInputStack
            
            // Zweite Zeile: Textfeld und Speicher-Button
            HStack {
                TextField("Tätigkeit...", text: $viewModel.newTask)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Speichern") {
                    viewModel.saveNewEntry()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.newTask.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Dieser Stack entscheidet je nach Gerät über das Layout
    private var adaptiveInputStack: some View {
        #if os(iOS)
        return VStack(spacing: 10) {
            HStack {
                Text("Datum:")
                Spacer()
                DatePicker("", selection: $viewModel.newDate, displayedComponents: .date)
                    .labelsHidden()
            }
            HStack {
                Text("Zeit:")
                Spacer()
                DatePicker("", selection: $viewModel.newStartTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Text("-")
                DatePicker("", selection: $viewModel.newEndTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
        }
        #else
        // Klassisches Mac-Layout (nebeneinander)
        return HStack {
            DatePicker("", selection: $viewModel.newDate, displayedComponents: .date)
                .labelsHidden()
                .frame(width: 150, alignment: .leading)
            
            Spacer()
            
            Text("Start:")
                .font(.caption)
            DatePicker("", selection: $viewModel.newStartTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .fixedSize()
            
            Text("Ende:")
                .font(.caption)
            DatePicker("", selection: $viewModel.newEndTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .fixedSize()
        }
        #endif
    }
}
