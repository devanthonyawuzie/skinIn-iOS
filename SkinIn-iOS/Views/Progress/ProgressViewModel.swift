// Views/Progress/ProgressViewModel.swift
// SkinIn-iOS
//
// ViewModel for the Progress tab.
// Owns weight trend data, lift metrics, radar chart state, and time-range selection.

import Foundation
import Observation

// MARK: - TimeRange

enum TimeRange: String, CaseIterable {
    case oneWeek    = "1W"
    case oneMonth   = "1M"
    case threeMonths = "3M"
    case ytd        = "YTD"
}

// MARK: - WeightDataPoint

struct WeightDataPoint: Identifiable {
    let id: UUID
    let date: Date
    let weightLbs: Double
}

// MARK: - LiftMetric

struct LiftMetric: Identifiable {
    let id: UUID
    let name: String           // "BENCH PRESS", "SQUAT", etc.
    let currentWeight: String  // "225×8", "20 reps", etc.
    let changeLabel: String    // "+15lbs", "Same", "PR", "+2"
    let changeTrend: Trend     // .up .neutral .pr .down
    let radarValue: Double     // 0.0–1.0 for radar chart (week 12 score)
    let radarValueWeek1: Double // 0.0–1.0 for radar chart (week 1 score)

    enum Trend { case up, neutral, pr, down }
}

// MARK: - ProgressViewModel

@Observable
final class ProgressViewModel {

    // MARK: Trend Analysis state
    var selectedTimeRange: TimeRange = .oneMonth
    var isTrendChartExpanded: Bool = true

    // MARK: Radar Chart state
    var isRadarChartExpanded: Bool = true
    /// Name of the tapped lift for tooltip display; nil when nothing is selected.
    var selectedRadarLift: String? = nil

    // MARK: Weight chart data (mock)

    /// Generates ~30 days of mock weight data ending at today.
    /// Gentle downward trend from ~180 → ~176.4 lbs with slight noise.
    var weightData: [WeightDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            let base = 180.0 - (Double(30 - daysAgo) * 0.12)
            // Deterministic noise keyed to daysAgo so data doesn't re-randomise on every view refresh.
            let noiseSeed = Double((daysAgo * 17) % 10) / 10.0   // 0.0 … 0.9
            let noise = noiseSeed * 0.8 - 0.4                     // −0.4 … +0.4
            return WeightDataPoint(id: UUID(), date: date, weightLbs: base + noise)
        }
    }

    var avgWeeklyChange: Double { -0.8 }
    var trendLabel: String { "Consistent" }

    // MARK: Lift metrics (8 lifts for radar + detail grid)

    let lifts: [LiftMetric] = [
        LiftMetric(id: UUID(), name: "BENCH PRESS",  currentWeight: "225×8",   changeLabel: "+15lbs",  changeTrend: .up,      radarValue: 0.78, radarValueWeek1: 0.62),
        LiftMetric(id: UUID(), name: "SQUAT",        currentWeight: "315×6",   changeLabel: "+20lbs",  changeTrend: .up,      radarValue: 0.88, radarValueWeek1: 0.70),
        LiftMetric(id: UUID(), name: "DEADLIFT",     currentWeight: "405×5",   changeLabel: "+20lbs",  changeTrend: .up,      radarValue: 0.92, radarValueWeek1: 0.72),
        LiftMetric(id: UUID(), name: "OHP",          currentWeight: "135×8",   changeLabel: "Same",    changeTrend: .neutral, radarValue: 0.55, radarValueWeek1: 0.55),
        LiftMetric(id: UUID(), name: "PULL-UPS",     currentWeight: "12 reps", changeLabel: "+2",      changeTrend: .up,      radarValue: 0.60, radarValueWeek1: 0.48),
        LiftMetric(id: UUID(), name: "LEG PRESS",    currentWeight: "450×12",  changeLabel: "PR",      changeTrend: .pr,      radarValue: 0.95, radarValueWeek1: 0.75),
        LiftMetric(id: UUID(), name: "DIPS",         currentWeight: "20 reps", changeLabel: "+5",      changeTrend: .up,      radarValue: 0.65, radarValueWeek1: 0.50),
        LiftMetric(id: UUID(), name: "ROWS",         currentWeight: "185×10",  changeLabel: "Same",    changeTrend: .neutral, radarValue: 0.70, radarValueWeek1: 0.70),
    ]

    /// Clockwise axis label order starting from the top of the radar chart.
    var radarOrder: [String] {
        ["BENCH PRESS", "SQUAT", "DEADLIFT", "OHP", "PULL-UPS", "LEG PRESS", "DIPS", "ROWS"]
    }
}
