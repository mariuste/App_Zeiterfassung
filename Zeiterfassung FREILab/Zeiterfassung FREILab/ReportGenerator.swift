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
        let content = PDFContentView(
            entries: entries,
            period: period,
            authorName: authorName,
            createdAt: Date()
        )

        let renderer = ImageRenderer(content: content)
        renderer.scale = 1.0  // Punkte, nicht Pixel — PDF ist vektorbasiert

        let a4Width: CGFloat = 595   // A4 bei 72dpi
        let a4Height: CGFloat = 842
        let mutableData = NSMutableData()

        renderer.render { size, drawContent in
            let totalPages = max(1, Int(ceil(size.height / a4Height)))
            var mediaBox = CGRect(x: 0, y: 0, width: a4Width, height: a4Height)

            guard let consumer = CGDataConsumer(data: mutableData),
                  let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
            else { return }

            for page in 0..<totalPages {
                // Verschiebung: Seite N zeigt den Bereich von y=(size.height - (N+1)*a4Height)
                // bis y=(size.height - N*a4Height) des Inhalts (PDF: y=0 unten)
                let yOffset = CGFloat(page + 1) * a4Height - size.height

                pdfContext.beginPDFPage(nil)
                pdfContext.saveGState()
                pdfContext.clip(to: CGRect(x: 0, y: 0, width: a4Width, height: a4Height))
                pdfContext.translateBy(x: 0, y: yOffset)
                drawContent(pdfContext)
                pdfContext.restoreGState()
                pdfContext.endPDFPage()
            }

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
