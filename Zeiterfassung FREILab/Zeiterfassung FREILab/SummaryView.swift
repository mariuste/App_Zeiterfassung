//
//  SummaryView.swift
//  Zeiterfassung FREILab
//
//  Created by Marius Tetard on 20.04.26.
//

import SwiftUI

struct SummaryView: View {
    @ObservedObject var viewModel: TimeTrackerViewModel
    let months = ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Übersicht")
                    .font(.headline)
                Spacer()
                Picker("Jahr", selection: $viewModel.selectedYear) {
                    ForEach(viewModel.availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
            HStack {
                Text("\(String(format: "%.2f", viewModel.yearlyTotal)) h")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                Spacer()
            }
            
            // Monate in zwei Zeilen gesplittet
            VStack(spacing: 12) {
                // Zeile 1: Januar bis Juni
                HStack {
                    ForEach(0..<6) { index in
                        monthCell(index: index)
                        if index < 5 { Spacer() }
                    }
                }
                
                Divider()
                    .opacity(0.3)
                
                // Zeile 2: Juli bis Dezember
                HStack {
                    ForEach(6..<12) { index in
                        monthCell(index: index)
                        if index < 11 { Spacer() }
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Hilfs-View für eine einzelne Monats-Zelle
    @ViewBuilder
    // In der monthCell Funktion in SummaryView.swift:
    private func monthCell(index: Int) -> some View {
        VStack(spacing: 2) {
            Text(months[index])
                .font(.system(size: 10, weight: .medium)) // Etwas kleiner für Mobile
                .foregroundColor(.secondary)
            
            Text(String(format: "%.1f", viewModel.monthlyTotals[index]))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(viewModel.monthlyTotals[index] > 0 ? .blue : .secondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity) // Nutzt den verfügbaren Platz gleichmäßig
    }
}
