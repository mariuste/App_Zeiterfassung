//
//  CSVManager.swift
//  Zeiterfassung FREILab
//
//  Created by Marius Tetard on 20.04.26.
//

import Foundation

class CSVManager {
    let fileName = "zeiterfassung.csv"
    let maxBackups = 20

    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent(fileName)
        print("Speicherort: \(url.path)") // Hilft uns beim Debuggen in der Konsole
        return url
    }

    private var backupFolderURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(".backups")
    }

    init() {
        // Hauptdatei erstellen, falls nicht vorhanden
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let header = "Datum,Start,Ende,Taetigkeit,Dauer_Stunden\n"
            try? header.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        // Backup-Ordner erstellen (versteckt durch den Punkt .)
        try? FileManager.default.createDirectory(at: backupFolderURL, withIntermediateDirectories: true)
        
        // Backup beim Start ausführen
        createBackup()
    }

    func loadEntries() -> [TimeEntry] {
        var entries: [TimeEntry] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        do {
            let data = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = data.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            for row in rows.dropFirst() {
                let cleanedColumns = parseCSVRow(row)
                
                if cleanedColumns.count >= 5 {
                    let dateString = cleanedColumns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let startString = cleanedColumns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let endString = cleanedColumns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    let task = cleanedColumns[3].replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let durationStr = cleanedColumns[4].trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                    
                    let duration = Double(durationStr) ?? 0.0

                    if let startTime = dateFormatter.date(from: "\(dateString) \(startString)"),
                       let endTime = dateFormatter.date(from: "\(dateString) \(endString)"),
                       let dateOnly = dateFormatter.date(from: "\(dateString) 00:00") {
                        entries.append(TimeEntry(date: dateOnly, startTime: startTime, endTime: endTime, taskDescription: task, durationHours: duration))
                    }
                }
            }
        } catch { print("Fehler beim Laden: \(error)") }
        return entries
    }

    func saveEntry(entry: TimeEntry) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: entry.date)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let startStr = timeFormatter.string(from: entry.startTime)
        let endStr = timeFormatter.string(from: entry.endTime)

        let row = "\(dateStr),\(startStr),\(endStr),\"\(entry.taskDescription)\",\(entry.durationHours)\n"

        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            fileHandle.seekToEndOfFile()
            if let data = row.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } else {
            try? row.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    func rewriteAll(entries: [TimeEntry]) {
        let header = "Datum,Start,Ende,Taetigkeit,Dauer_Stunden\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        var csvString = header
        for entry in entries {
            let dateStr = dateFormatter.string(from: entry.date)
            let startStr = timeFormatter.string(from: entry.startTime)
            let endStr = timeFormatter.string(from: entry.endTime)
            let row = "\(dateStr),\(startStr),\(endStr),\"\(entry.taskDescription)\",\(entry.durationHours)\n"
            csvString.append(row)
        }
        
        try? csvString.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func createBackup() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let backupURL = backupFolderURL.appendingPathComponent("zeiterfassung_backup_\(timestamp).csv")
        
        try? FileManager.default.copyItem(at: fileURL, to: backupURL)
        cleanupOldBackups()
    }

    private func cleanupOldBackups() {
        do {
            let backupFiles = try FileManager.default.contentsOfDirectory(at: backupFolderURL, includingPropertiesForKeys: [.creationDateKey])
            let sortedBackups = backupFiles.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 < date2
            }
            
            if sortedBackups.count > maxBackups {
                let toDelete = sortedBackups.count - maxBackups
                for i in 0..<toDelete {
                    try FileManager.default.removeItem(at: sortedBackups[i])
                }
            }
        } catch { print("Backup-Fehler: \(error)") }
    }

    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for char in row {
            if char == "\"" { inQuotes.toggle() }
            else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result
    }
}
