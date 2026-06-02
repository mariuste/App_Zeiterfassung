//
//  ReportView.swift
//  Zeiterfassung FREILab
//

import SwiftUI
import UniformTypeIdentifiers

struct ReportView: View {
    @ObservedObject var viewModel: TimeTrackerViewModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("reportAuthorName") private var authorName: String = ""
    @State private var selectedPeriod: ReportPeriod = .currentMonth
    @State private var customFrom: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customTo: Date = Date()
    @State private var isGenerating = false
    @State private var errorMessage: String?

    #if os(macOS)
    @State private var showSavePanel = false
    #else
    @State private var pdfDataForShare: Data?
    @State private var showShareSheet = false
    #endif

    private var filteredEntries: [TimeEntry] {
        if selectedPeriod == .custom {
            let to = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: customTo) ?? customTo
            return viewModel.entries
                .filter { $0.date >= customFrom && $0.date <= to }
                .sorted { $0.startTime < $1.startTime }
        }
        return ReportGenerator.filteredEntries(for: selectedPeriod, from: viewModel.entries)
    }

    private var totalHours: Double {
        filteredEntries.reduce(0) { $0 + $1.durationHours }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Titelzeile
            HStack {
                Text("Report erstellen")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        TextField("Dein Name", text: $authorName)
                            #if os(iOS)
                            .textFieldStyle(.roundedBorder)
                            #else
                            .textFieldStyle(.roundedBorder)
                            #endif
                    }

                    // Zeitraum
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Zeitraum")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Picker("Zeitraum", selection: $selectedPeriod) {
                            ForEach(ReportPeriod.allCases) { period in
                                Text(period.displayLabel).tag(period)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        #if os(macOS)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        #endif
                    }

                    // Benutzerdefinierter Zeitraum
                    if selectedPeriod == .custom {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Zeitraum")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            DatePicker("Von", selection: $customFrom, in: ...customTo, displayedComponents: .date)
                            DatePicker("Bis", selection: $customTo, in: customFrom..., displayedComponents: .date)
                        }
                    }

                    // Vorschau-Karte
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Einträge")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(filteredEntries.count)")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Gesamtstunden")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f h", totalHours))
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                            }
                        }

                        if filteredEntries.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("Keine Einträge im gewählten Zeitraum")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }

            Divider()

            // Aktionsbutton
            Button(action: generateReport) {
                if isGenerating {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                } else {
                    Label("PDF erstellen", systemImage: "doc.richtext")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(authorName.trimmingCharacters(in: .whitespaces).isEmpty || filteredEntries.isEmpty || isGenerating)
            .padding()
        }
        #if os(macOS)
        .frame(width: 380, height: 420)
        #endif
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfDataForShare {
                ShareSheet(items: [data])
            }
        }
        #endif
    }

    // MARK: - PDF erzeugen

    private func generateReport() {
        isGenerating = true
        errorMessage = nil

        guard let pdfData = ReportGenerator.generatePDF(
            entries: filteredEntries,
            period: selectedPeriod,
            authorName: authorName.trimmingCharacters(in: .whitespaces)
        ) else {
            errorMessage = "PDF konnte nicht erstellt werden."
            isGenerating = false
            return
        }

        #if os(macOS)
        savePDFMacOS(data: pdfData)
        #else
        pdfDataForShare = pdfData
        showShareSheet = true
        #endif

        isGenerating = false
    }

    #if os(macOS)
    private func savePDFMacOS(data: Data) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = ReportGenerator.suggestedFilename(for: selectedPeriod)
        panel.title = "Report speichern"
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url)
                dismiss()
                NSWorkspace.shared.open(url)
            } catch {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
            }
        }
    }
    #endif
}

// MARK: - iOS Share Sheet

#if os(iOS)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let filename = "Stundenreport.pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        if let data = items.first as? Data {
            try? data.write(to: tempURL)
        }
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
