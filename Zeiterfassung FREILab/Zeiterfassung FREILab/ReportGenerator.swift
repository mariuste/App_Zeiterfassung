//
//  ReportGenerator.swift
//  Zeiterfassung FREILab
//

import SwiftUI

struct ReportGenerator {

    static func filteredEntries(for period: ReportPeriod, from entries: [TimeEntry]) -> [TimeEntry] {
        let range = period.dateRange
        return entries
            .filter { $0.date >= range.from && $0.date <= range.to }
            .sorted { $0.startTime < $1.startTime }
    }

    @MainActor
    static func generatePDF(entries: [TimeEntry], period: ReportPeriod, authorName: String) -> Data? {
        let createdAt = Date()
        let content = PDFContentView(
            entries: entries,
            period: period,
            authorName: authorName,
            createdAt: createdAt
        )

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2.0  // 144dpi für scharfe Ausgabe

        let mutableData = NSMutableData()
        renderer.render { size, context in
            var mediaBox = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: mutableData),
                  let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
            else { return }

            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }

        return mutableData.length > 0 ? mutableData as Data : nil
    }

    static func suggestedFilename(for period: ReportPeriod) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())

        let periodSlug: String
        switch period {
        case .currentMonth:
            formatter.dateFormat = "yyyy-MM"
            periodSlug = formatter.string(from: Date())
        case .lastMonth:
            formatter.dateFormat = "yyyy-MM"
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            periodSlug = formatter.string(from: lastMonth)
        case .lastThreeMonths:
            periodSlug = "letzte-3-monate"
        case .lastSixMonths:
            periodSlug = "letzte-6-monate"
        case .currentYear:
            formatter.dateFormat = "yyyy"
            periodSlug = formatter.string(from: Date())
        case .lastYear:
            formatter.dateFormat = "yyyy"
            let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
            periodSlug = formatter.string(from: lastYear)
        case .lastTwelveMonths:
            periodSlug = "letzte-12-monate"
        case .custom:
            periodSlug = "benutzerdefiniert"
        }

        return "Stundenreport_\(periodSlug)_\(dateStr).pdf"
    }
}
