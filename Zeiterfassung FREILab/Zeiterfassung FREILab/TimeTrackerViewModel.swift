//
//  TimeTrackerViewModel.swift
//  Zeiterfassung FREILab
//
//  Created by Marius Tetard on 20.04.26.
//

import Foundation
import Combine

class TimeTrackerViewModel: ObservableObject {
    @Published var entries: [TimeEntry] = []
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    // Für das Bearbeitungs-Fenster (Sheet)
    @Published var editingEntry: TimeEntry?
    
    // Eingabefelder
    @Published var newDate: Date = Date()
    @Published var newStartTime: Date = Date()
    @Published var newEndTime: Date = Date()
    @Published var newTask: String = ""

    private let csvManager = CSVManager()

    init() {
        loadData()
        
        // Wir bleiben standardmäßig im aktuellen Kalenderjahr.
        // Nur wenn die Liste für 2026 komplett leer ist, schauen wir,
        // ob es historische Daten gibt, um nicht auf einer leeren Seite zu starten.
        let currentYear = Calendar.current.component(.year, from: Date())
        if !entries.contains(where: { Calendar.current.component(.year, from: $0.date) == currentYear }) {
            if let lastYear = entries.map({ Calendar.current.component(.year, from: $0.date) }).max() {
                selectedYear = lastYear
            }
        }
        
        resetNewEntryForm()
    }

    func loadData() {
        let loaded = csvManager.loadEntries()
        // Sortiert nach der Startzeit, damit die Reihenfolge im Tag (und Jahr) stimmt
        DispatchQueue.main.async {
            self.entries = loaded.sorted(by: { $0.startTime < $1.startTime })
        }
    }

    var monthlyTotals: [Double] {
        let calendar = Calendar.current
        var totals = Array(repeating: 0.0, count: 12)
        
        // filteredEntries nutzt das aktuell gewählte Jahr aus dem Picker
        for entry in filteredEntries {
            let month = calendar.component(.month, from: entry.date)
            if month >= 1 && month <= 12 {
                totals[month - 1] += entry.durationHours
            }
        }
        return totals
    }

    // Hilfseigenschaft: Nur Einträge für das gewählte Jahr (für die Liste in Bereich B)
    var filteredEntries: [TimeEntry] {
        entries.filter { Calendar.current.component(.year, from: $0.date) == selectedYear }
    }

    var availableYears: [Int] {
        let years = entries.map { Calendar.current.component(.year, from: $0.date) }
        let uniqueYears = Set(years + [Calendar.current.component(.year, from: Date())])
        return Array(uniqueYears).sorted(by: >)
    }

    var yearlyTotal: Double {
        filteredEntries.reduce(0) { $0 + $1.durationHours }
    }

    func resetNewEntryForm() {
        newDate = Date()
        newTask = ""
        let now = Date()
        let calendar = Calendar.current
        
        // Aufrunden auf 15 Minuten
        let minute = calendar.component(.minute, from: now)
        let remainder = minute % 15
        let addMinutes = remainder == 0 ? 0 : (15 - remainder)
        
        if let roundedEnd = calendar.date(byAdding: .minute, value: addMinutes, to: now) {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: roundedEnd)
            let finalEnd = calendar.date(from: components) ?? roundedEnd
            newEndTime = finalEnd
            newStartTime = calendar.date(byAdding: .hour, value: -2, to: finalEnd) ?? finalEnd
        }
    }

    func saveNewEntry() {
        guard !newTask.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        var duration = newEndTime.timeIntervalSince(newStartTime) / 3600.0
        if duration < 0 { duration += 24.0 }
        
        let entry = TimeEntry(
            date: newDate,
            startTime: newStartTime,
            endTime: newEndTime,
            taskDescription: newTask,
            durationHours: duration
        )
        
        csvManager.saveEntry(entry: entry)
        loadData()
        
        // Automatisch zum Jahr des neuen Eintrags wechseln
        let entryYear = Calendar.current.component(.year, from: newDate)
        selectedYear = entryYear
        
        resetNewEntryForm()
    }
    
    // Lösch-Funktion
    func deleteEntry(at offsets: IndexSet, undoManager: UndoManager?) {
        // 1. Die Einträge finden, die gelöscht werden sollen
        let entriesToDelete = offsets.map { filteredEntries[$0] }
        
        // 2. Dem UndoManager sagen, wie er das rückgängig macht
        undoManager?.registerUndo(withTarget: self) { target in
            // Die "Gegen-Aktion" zum Löschen ist das Einfügen
            target.insertEntries(entriesToDelete, undoManager: undoManager)
        }
        undoManager?.setActionName("Eintrag löschen")

        // 3. Tatsächliches Löschen
        entries.removeAll { entry in
            entriesToDelete.contains(where: { $0.id == entry.id })
        }
        
        csvManager.rewriteAll(entries: entries)
        loadData()
    }
    // Hilfsfunktion für das Undo (fügt gelöschte Einträge wieder ein)
    func insertEntries(_ entriesToInsert: [TimeEntry], undoManager: UndoManager?) {
        // Wiederum dem UndoManager sagen, wie er DAS rückgängig macht (erneutes Löschen)
        undoManager?.registerUndo(withTarget: self) { target in
            let ids = entriesToInsert.map { $0.id }
            let offsets = IndexSet(target.filteredEntries.enumerated()
                .filter { ids.contains($1.id) }
                .map { $0.offset })
            target.deleteEntry(at: offsets, undoManager: undoManager)
        }
        
        entries.append(contentsOf: entriesToInsert)
        entries.sort(by: { $0.startTime < $1.startTime })
        
        csvManager.rewriteAll(entries: entries)
        loadData()
    }
    
    // Update-Funktion für einen bearbeiteten Eintrag
        func updateEntry(_ updatedEntry: TimeEntry) {
            if let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) {
                var finalEntry = updatedEntry
                // Dauer neu berechnen
                var duration = finalEntry.endTime.timeIntervalSince(finalEntry.startTime) / 3600.0
                if duration < 0 { duration += 24.0 }
                finalEntry.durationHours = duration
                
                entries[index] = finalEntry
                csvManager.rewriteAll(entries: entries)
                loadData()
            }
        }
    func importExternalCSV(from url: URL) {
        // 1. Zugriff auf die externe Datei (z.B. in der iCloud) anfordern
        guard url.startAccessingSecurityScopedResource() else {
            print("Zugriff verweigert")
            return
        }
        
        // 2. Sicherstellen, dass der Sicherheits-Zugriff am Ende wieder freigegeben wird
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            // Den Inhalt der externen Datei lesen
            let content = try String(contentsOf: url, encoding: .utf8)
            
            // Pfad zur lokalen "zeiterfassung.csv" innerhalb der App bestimmen
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let localURL = paths[0].appendingPathComponent("zeiterfassung.csv")
            
            // Die lokale Datei mit dem neuen Inhalt überschreiben
            try content.write(to: localURL, atomically: true, encoding: .utf8)
            
            // 3. UI aktualisieren: loadData() sorgt dafür, dass die Liste die neuen Einträge zeigt
            loadData()
            
        } catch {
            print("Fehler beim Importieren: \(error)")
        }
    }
}
