// Views/Progress/ProgressViewModel.swift
// SkinIn-iOS
//
// ViewModel for the Progress tab.
// Owns weight trend data, body-area radar state, summary metrics, and
// local progress photo management (stored in app Documents — no backend needed).

import Foundation
import Observation
import UIKit

// MARK: - TimeRange

enum TimeRange: String, CaseIterable {
    case oneWeek     = "1W"
    case oneMonth    = "1M"
    case threeMonths = "3M"
    case ytd         = "YTD"
}

// MARK: - WeightDataPoint

struct WeightDataPoint: Identifiable {
    let id: UUID
    let date: Date
    let weightLbs: Double
}

// MARK: - BodyAreaStat

/// One axis on the body radar. radarValue is 0.0–1.0 based on
/// how many workouts targeting this area have been logged this week.
struct BodyAreaStat: Identifiable {
    let id: UUID
    let name: String       // "CHEST", "BACK", "LEGS", etc.
    let radarValue: Double // 0.0–1.0
}

// MARK: - ProgressStat

struct ProgressStat: Identifiable {
    let id: UUID
    let label: String
    let value: String
    let subtitle: String
}

// MARK: - ProgressPhotoMeta

/// Lightweight metadata stored in UserDefaults.
/// The actual JPEG lives on disk at ProgressPhotos/<filename>.
struct ProgressPhotoMeta: Identifiable, Codable {
    let id: UUID
    let date: Date
    let filename: String
    let weekNumber: Int
}

// MARK: - ProgressViewModel

@Observable
final class ProgressViewModel {

    // MARK: UI state

    var selectedTimeRange: TimeRange = .oneMonth
    var isTrendChartExpanded: Bool   = true
    var isRadarChartExpanded: Bool   = true

    // MARK: Real data (from API)

    var totalStake: Double     = 0.0
    var currentWeek: Int       = 1
    var completedThisWeek: Int = 0
    var totalThisWeek: Int     = 4

    // Day-level completion flags — used to compute body area radar values.
    var day1Done: Bool = false
    var day2Done: Bool = false
    var day3Done: Bool = false
    var day4Done: Bool = false

    // MARK: Weight chart data (mock until weight-tracking is added)

    var weightData: [WeightDataPoint] {
        let calendar = Calendar.current
        let today    = Date()
        return (0..<30).reversed().map { daysAgo in
            let date      = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            let base      = 180.0 - (Double(30 - daysAgo) * 0.12)
            let noiseSeed = Double((daysAgo * 17) % 10) / 10.0
            let noise     = noiseSeed * 0.8 - 0.4
            return WeightDataPoint(id: UUID(), date: date, weightLbs: base + noise)
        }
    }

    var avgWeeklyChange: Double { -0.8 }
    var trendLabel: String { "Consistent" }

    // MARK: Body area radar (derived from day completion flags)
    //
    // Mapping logic (upper/lower 4-day split):
    //   Day 1 — Upper A: chest/shoulders (push) + triceps
    //   Day 2 — Lower A: quads/glutes + core
    //   Day 3 — Upper B: back/biceps (pull) + rear delts
    //   Day 4 — Lower B: hamstrings/glutes + core

    var bodyAreas: [BodyAreaStat] {
        [
            BodyAreaStat(id: UUID(), name: "CHEST",
                         radarValue: day1Done ? 1.0 : 0.0),
            BodyAreaStat(id: UUID(), name: "BACK",
                         radarValue: day3Done ? 1.0 : 0.0),
            BodyAreaStat(id: UUID(), name: "LEGS",
                         radarValue: (day2Done ? 0.5 : 0.0) + (day4Done ? 0.5 : 0.0)),
            BodyAreaStat(id: UUID(), name: "SHOULDERS",
                         radarValue: (day1Done ? 0.8 : 0.0) + (day3Done ? 0.2 : 0.0)),
            BodyAreaStat(id: UUID(), name: "ARMS",
                         radarValue: (day1Done ? 0.5 : 0.0) + (day3Done ? 0.5 : 0.0)),
            BodyAreaStat(id: UUID(), name: "CORE",
                         radarValue: (day2Done ? 0.5 : 0.0) + (day4Done ? 0.5 : 0.0)),
        ]
    }

    var radarOrder: [String] {
        ["CHEST", "BACK", "LEGS", "SHOULDERS", "ARMS", "CORE"]
    }

    // MARK: Detailed stats grid

    var progressStats: [ProgressStat] {
        let programPct = Int((Double(currentWeek - 1) / 12.0) * 100)
        return [
            ProgressStat(id: UUID(), label: "WORKOUTS",
                         value: "\(completedThisWeek)/\(totalThisWeek)",
                         subtitle: "this week"),
            ProgressStat(id: UUID(), label: "WEEK",
                         value: "\(currentWeek)",
                         subtitle: "of 12"),
            ProgressStat(id: UUID(), label: "STAKE",
                         value: "$\(Int(totalStake))",
                         subtitle: "protected"),
            ProgressStat(id: UUID(), label: "PROGRAM",
                         value: "\(programPct)%",
                         subtitle: "complete"),
        ]
    }

    // MARK: - Photo Progress

    private static let photosMetaKey = "skinin_progress_photos_meta"

    private static var photosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask).first!
        let dir  = docs.appendingPathComponent("ProgressPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir,
                                                 withIntermediateDirectories: true)
        return dir
    }

    var progressPhotos: [ProgressPhotoMeta] = []

    func loadPhotos() {
        guard let data = UserDefaults.standard.data(forKey: Self.photosMetaKey),
              let photos = try? JSONDecoder().decode([ProgressPhotoMeta].self, from: data)
        else { return }
        // Newest first
        progressPhotos = photos.sorted { $0.date > $1.date }
    }

    func addPhoto(_ image: UIImage) {
        let id       = UUID()
        let filename = "\(id.uuidString).jpg"
        let url      = Self.photosDirectory.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 0.82) else { return }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            print("[ProgressViewModel] Failed to save photo: \(error)")
            return
        }

        let meta = ProgressPhotoMeta(
            id:         id,
            date:       Date(),
            filename:   filename,
            weekNumber: currentWeek
        )
        progressPhotos.insert(meta, at: 0) // newest first
        savePhotosMetadata()
    }

    func deletePhoto(_ id: UUID) {
        guard let meta = progressPhotos.first(where: { $0.id == id }) else { return }
        let url = Self.photosDirectory.appendingPathComponent(meta.filename)
        try? FileManager.default.removeItem(at: url)
        progressPhotos.removeAll { $0.id == id }
        savePhotosMetadata()
    }

    func loadImage(filename: String) -> UIImage? {
        let url = Self.photosDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func savePhotosMetadata() {
        guard let data = try? JSONEncoder().encode(progressPhotos) else { return }
        UserDefaults.standard.set(data, forKey: Self.photosMetaKey)
    }

    // MARK: - Fetch

    func fetchProgressData() async {
        loadPhotos()

        guard let token = UserDefaults.standard.string(
            forKey: Config.UserDefaultsKey.supabaseSessionToken
        ) else { return }

        guard let url = URL(string: Config.apiBaseURL + "/api/workouts/current-week") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        await MainActor.run {
            if let paid = json["amount_paid"] as? Double { totalStake = paid }
            if let week = json["week_number"] as? Int    { currentWeek = week }

            if let workouts = json["workouts"] as? [[String: Any]] {
                completedThisWeek = workouts.filter {
                    ($0["status"] as? String) == "completed"
                }.count
                totalThisWeek = workouts.count

                day1Done = workouts.contains {
                    $0["day_number"] as? Int == 1 && ($0["status"] as? String) == "completed"
                }
                day2Done = workouts.contains {
                    $0["day_number"] as? Int == 2 && ($0["status"] as? String) == "completed"
                }
                day3Done = workouts.contains {
                    $0["day_number"] as? Int == 3 && ($0["status"] as? String) == "completed"
                }
                day4Done = workouts.contains {
                    $0["day_number"] as? Int == 4 && ($0["status"] as? String) == "completed"
                }
            }
        }
    }
}
