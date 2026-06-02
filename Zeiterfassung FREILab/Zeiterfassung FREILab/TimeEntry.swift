//
//  TimeEntry.swift
//  Zeiterfassung FREILab
//
//  Created by Marius Tetard on 20.04.26.
//

import Foundation

struct TimeEntry: Identifiable {
    let id = UUID()
    var date: Date
    var startTime: Date
    var endTime: Date
    var taskDescription: String
    var durationHours: Double
}
