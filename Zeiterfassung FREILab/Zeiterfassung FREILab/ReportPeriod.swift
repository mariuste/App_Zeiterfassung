//
//  ReportPeriod.swift
//  Zeiterfassung FREILab
//

import Foundation

enum ReportPeriod: CaseIterable, Identifiable {
    case currentMonth
    case lastMonth
    case lastThreeMonths
    case lastSixMonths
    case currentYear
    case lastYear
    case lastTwelveMonths
    case custom

    var id: String { displayLabel }

    var dateRange: (from: Date, to: Date) {
        let calendar = Calendar.current
        let now = Date()
        let todayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!

        switch self {
        case .currentMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (start, todayEnd)

        case .lastMonth:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            let end = calendar.date(byAdding: .second, value: -1, to: thisMonthStart)!
            return (start, end)

        case .lastThreeMonths:
            let start = calendar.date(byAdding: .month, value: -2, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)!
            return (start, todayEnd)

        case .lastSixMonths:
            let start = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)!
            return (start, todayEnd)

        case .currentYear:
            let start = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: 1, day: 1))!
            return (start, todayEnd)

        case .lastYear:
            let lastYear = calendar.component(.year, from: now) - 1
            let start = calendar.date(from: DateComponents(year: lastYear, month: 1, day: 1))!
            let end = calendar.date(from: DateComponents(year: lastYear, month: 12, day: 31, hour: 23, minute: 59, second: 59))!
            return (start, end)

        case .lastTwelveMonths:
            let start = calendar.date(byAdding: .month, value: -11, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)!
            return (start, todayEnd)

        case .custom:
            return (Date.distantPast, Date.distantFuture)
        }
    }

    var displayLabel: String {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")

        switch self {
        case .currentMonth:
            formatter.dateFormat = "MMMM yyyy"
            return "Aktueller Monat (\(formatter.string(from: now)))"

        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            formatter.dateFormat = "MMMM yyyy"
            return "Letzter Monat (\(formatter.string(from: lastMonth)))"

        case .lastThreeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now)!
            formatter.dateFormat = "MMM"
            let from = formatter.string(from: threeMonthsAgo)
            let to = formatter.string(from: now)
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: now)
            return "Letzte 3 Monate (\(from)–\(to) \(year))"

        case .lastSixMonths:
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -5, to: now)!
            formatter.dateFormat = "MMM"
            let from = formatter.string(from: sixMonthsAgo)
            let to = formatter.string(from: now)
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: now)
            return "Letzte 6 Monate (\(from)–\(to) \(year))"

        case .currentYear:
            formatter.dateFormat = "yyyy"
            return "Aktuelles Jahr (\(formatter.string(from: now)))"

        case .lastYear:
            formatter.dateFormat = "yyyy"
            let lastYear = calendar.date(byAdding: .year, value: -1, to: now)!
            return "Letztes Jahr (\(formatter.string(from: lastYear)))"

        case .lastTwelveMonths:
            return "Letzte 12 Monate"

        case .custom:
            return "Benutzerdefiniert …"
        }
    }
}
