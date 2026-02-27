// Views/Progress/ProgressViewModel.swift
// SkinIn-iOS
//
// ViewModel for the Progress tab.
// Owns weight trend data, body-area radar state, summary metrics, and
// progress photo management backed by Supabase Storage via the API.

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

struct BodyAreaStat: Identifiable {
    let id: UUID
    let name: String
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

/// Metadata returned by the API for each progress photo.
/// The actual image is loaded on demand via the signed `url`.
struct ProgressPhotoMeta: Identifiable {
    let id: UUID           // server-generated UUID
    let weekNumber: Int
    let createdAt: Date
    let url: String?       // 1-hour signed Supabase Storage URL
}

// MARK: - ProgressViewModel

@Observable
final class ProgressViewModel {

    // MARK: UI state

    var selectedTimeRange: TimeRange = .oneMonth
    var isTrendChartExpanded: Bool   = true
    var isRadarChartExpanded: Bool   = true

    // MARK: Real data (from /api/workouts/current-week)

    var totalStake: Double     = 0.0
    var currentWeek: Int       = 1
    var completedThisWeek: Int = 0
    var totalThisWeek: Int     = 4

    var day1Done: Bool = false
    var day2Done: Bool = false
    var day3Done: Bool = false
    var day4Done: Bool = false

    // MARK: Photo state

    var progressPhotos: [ProgressPhotoMeta] = []
    var isUploadingPhoto: Bool = false

    // MARK: Weight chart (mock until weight-tracking is added)

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

    // MARK: Body area radar
    //
    // Day 1 — Upper A: chest/shoulders/triceps
    // Day 2 — Lower A: quads/glutes/core
    // Day 3 — Upper B: back/biceps/rear delts
    // Day 4 — Lower B: hamstrings/glutes/core

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

    // MARK: - API helpers

    private func authToken() -> String? {
        UserDefaults.standard.string(forKey: Config.UserDefaultsKey.supabaseSessionToken)
    }

    private func authedRequest(url: URL, method: String = "GET") -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let token = authToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    // MARK: - Fetch workout data

    func fetchProgressData() async {
        async let _ = fetchWorkoutData()
        async let _ = fetchPhotos()
    }

    private func fetchWorkoutData() async {
        guard let token = authToken(),
              let url   = URL(string: Config.apiBaseURL + "/api/workouts/current-week")
        else { return }

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

    // MARK: - Photo API

    /// Fetches all photos for the current user from the API (newest first).
    func fetchPhotos() async {
        guard let token = authToken(),
              let url   = URL(string: Config.apiBaseURL + "/api/progress-photos")
        else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawArray = json["photos"] as? [[String: Any]]
        else { return }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let photos: [ProgressPhotoMeta] = rawArray.compactMap { p in
            guard let idStr    = p["id"] as? String,
                  let id       = UUID(uuidString: idStr),
                  let week     = p["week_number"] as? Int,
                  let dateStr  = p["created_at"] as? String
            else { return nil }

            // Try fractional seconds first, fall back to whole seconds
            let date = formatter.date(from: dateStr)
                ?? ISO8601DateFormatter().date(from: dateStr)
                ?? Date()

            return ProgressPhotoMeta(
                id:         id,
                weekNumber: week,
                createdAt:  date,
                url:        p["url"] as? String
            )
        }

        await MainActor.run {
            progressPhotos = photos
        }
    }

    /// Uploads a photo to Supabase Storage via the API.
    /// Sets `isUploadingPhoto` while the request is in flight.
    func addPhoto(_ image: UIImage) async {
        guard let token    = authToken(),
              let imageData = image.jpegData(compressionQuality: 0.82),
              let url       = URL(string: Config.apiBaseURL + "/api/progress-photos/upload")
        else { return }

        await MainActor.run { isUploadingPhoto = true }
        defer { Task { @MainActor in isUploadingPhoto = false } }

        // Build multipart/form-data body
        let boundary = UUID().uuidString
        var body     = Data()

        // week_number field
        body.appendFormField(name: "week_number", value: "\(currentWeek)", boundary: boundary)

        // photo file field
        body.appendFormFile(
            name:        "photo",
            filename:    "photo.jpg",
            mimeType:    "image/jpeg",
            data:        imageData,
            boundary:    boundary
        )
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 201,
              let json  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idStr = json["id"] as? String,
              let id    = UUID(uuidString: idStr),
              let week  = json["week_number"] as? Int
        else { return }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateStr = json["created_at"] as? String ?? ""
        let date    = formatter.date(from: dateStr)
            ?? ISO8601DateFormatter().date(from: dateStr)
            ?? Date()

        let meta = ProgressPhotoMeta(
            id:         id,
            weekNumber: week,
            createdAt:  date,
            url:        json["url"] as? String
        )

        await MainActor.run {
            progressPhotos.insert(meta, at: 0)
        }
    }

    /// Deletes a photo from Supabase Storage and removes it from the local list.
    func deletePhoto(_ id: UUID) async {
        guard let token = authToken(),
              let url   = URL(string: Config.apiBaseURL + "/api/progress-photos/\(id.uuidString)")
        else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (_, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return }

        await MainActor.run {
            progressPhotos.removeAll { $0.id == id }
        }
    }
}

// MARK: - Data multipart helpers

private extension Data {
    mutating func appendFormField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func appendFormFile(name: String, filename: String,
                                 mimeType: String, data: Data, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
