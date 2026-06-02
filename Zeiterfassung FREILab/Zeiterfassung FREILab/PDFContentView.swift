//
//  PDFContentView.swift
//  Zeiterfassung FREILab
//

import SwiftUI

struct PDFContentView: View {
    let entries: [TimeEntry]
    let period: ReportPeriod
    let authorName: String
    let createdAt: Date

    private let pageWidth: CGFloat = 595  // A4 bei 72dpi
    private let pagePadding: CGFloat = 40

    private var groupedByMonth: [(key: String, entries: [TimeEntry], total: Double)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "MMMM yyyy"

        var dict: [(key: String, sortKey: Date, entries: [TimeEntry])] = []
        for entry in entries {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date))!
            let label = formatter.string(from: entry.date)
            if let idx = dict.firstIndex(where: { $0.sortKey == monthStart }) {
                dict[idx].entries.append(entry)
            } else {
                dict.append((key: label, sortKey: monthStart, entries: [entry]))
            }
        }
        return dict.sorted { $0.sortKey < $1.sortKey }.map {
            (key: $0.key, entries: $0.entries, total: $0.entries.reduce(0) { $0 + $1.durationHours })
        }
    }

    private var grandTotal: Double {
        entries.reduce(0) { $0 + $1.durationHours }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider().padding(.vertical, 12)
            entriesSection
            Divider().padding(.top, 16)
            totalSection
        }
        .padding(pagePadding)
        .frame(width: pageWidth)
        .background(Color.white)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stundenreport")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    Text("FREILab")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(period.displayLabel
                        .replacingOccurrences(of: "Aktueller Monat (", with: "")
                        .replacingOccurrences(of: "Aktuelles Jahr (", with: "")
                        .replacingOccurrences(of: "Letztes Jahr (", with: "")
                        .replacingOccurrences(of: ")", with: "")
                        .replacingOccurrences(of: "Letzte 3 Monate (", with: "")
                        .replacingOccurrences(of: "Letzte 6 Monate (", with: "")
                        .replacingOccurrences(of: "Letzte 12 Monate", with: "Letzte 12 Monate")
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)
                }
            }

            Divider().padding(.vertical, 8)

            HStack(spacing: 24) {
                labeledValue(label: "Name", value: authorName)
                labeledValue(label: "Erstellt am", value: formattedCreationDate)
                Spacer()
                labeledValue(label: "Gesamt", value: String(format: "%.2f h", grandTotal))
            }
        }
    }

    private var formattedCreationDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy, HH:mm 'Uhr'"
        return formatter.string(from: createdAt)
    }

    private func labeledValue(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.black)
        }
    }

    // MARK: - Entries

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            tableHeader
            Divider()
            ForEach(Array(groupedByMonth.enumerated()), id: \.offset) { _, group in
                ForEach(group.entries) { entry in
                    tableRow(entry: entry)
                }
                monthSummaryRow(month: group.key, total: group.total)
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("Datum")
                .frame(width: 80, alignment: .leading)
            Text("Von")
                .frame(width: 48, alignment: .leading)
            Text("Bis")
                .frame(width: 48, alignment: .leading)
            Text("Aufgabe")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Std")
                .frame(width: 50, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
        .textCase(.uppercase)
        .padding(.vertical, 6)
    }

    private func tableRow(entry: TimeEntry) -> some View {
        HStack(spacing: 0) {
            Text(dateString(entry.date))
                .frame(width: 80, alignment: .leading)
            Text(timeString(entry.startTime))
                .frame(width: 48, alignment: .leading)
            Text(timeString(entry.endTime))
                .frame(width: 48, alignment: .leading)
            Text(entry.taskDescription)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Text(String(format: "%.2f", entry.durationHours))
                .frame(width: 50, alignment: .trailing)
        }
        .font(.system(size: 11))
        .foregroundColor(.black)
        .padding(.vertical, 4)
    }

    private func monthSummaryRow(month: String, total: Double) -> some View {
        HStack {
            Text(month)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
            Spacer()
            Text(String(format: "%.2f h", total))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .background(Color(red: 0.94, green: 0.94, blue: 0.96))
        .cornerRadius(4)
        .padding(.bottom, 8)
    }

    // MARK: - Total

    private var totalSection: some View {
        HStack {
            Spacer()
            Text("Gesamt:")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black)
            Text(String(format: "%.2f h", grandTotal))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.18, green: 0.38, blue: 0.75))
        }
        .padding(.top, 12)
    }

    // MARK: - Formatters

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
