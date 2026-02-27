// Views/Workouts/WorkoutsViewModel.swift
// SkinIn-iOS
//
// ViewModel for the Workouts screen.
// Fetches the current-week workout schedule from the API and drives
// the week-day strip, timeline rows, and cooldown timer display.
// Architecture: MVVM — @Observable (iOS 17+). No @Published wrappers.

import Foundation
import Observation

// MARK: - WorkoutStatus

enum WorkoutStatus {
    case completed  // workout logged / past
    case today      // active session, timer visible
    case locked     // future / not yet unlocked
}

// MARK: - WorkoutSession

struct WorkoutSession: Identifiable {
    let id: UUID
    let workoutId: String
    let shortDay: String         // e.g. "MON, FEB 23" or "TODAY" or "DAY 3"
    let name: String
    let description: String
    let durationMinutes: Int
    let calories: Int
    let focusArea: String        // e.g. "Strength"
    let status: WorkoutStatus
    let loggedDate: String?      // "yyyy-MM-dd" from API, nil for future workouts
}

// MARK: - WeekDayItem

/// A single cell in the week-day strip at the top of the screen.
struct WeekDayItem: Identifiable {
    let id: UUID
    let abbreviation: String   // "SUN", "MON", …
    let dayNumber: Int         // calendar day of month
    let isToday: Bool
    let hasCompletedWorkout: Bool
}

// MARK: - WorkoutsViewModel

@Observable
final class WorkoutsViewModel {

    // MARK: Header State

    var month: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: Date()).uppercased()
    }

    var weekNumber: Int = 1

    var completedCount: Int { sessions.filter { $0.status == .completed }.count }
    var totalCount: Int { sessions.count }

    // MARK: Timer / Cooldown

    var cooldownActive: Bool = false
    var hoursRemaining: Double = 0

    var timerDisplay: String {
        guard cooldownActive, hoursRemaining > 0 else { return "" }
        let h = Int(hoursRemaining)
        let m = Int((hoursRemaining - Double(h)) * 60)
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    // MARK: Week Day Strip

    var weekDays: [WeekDayItem] = []

    // MARK: Sessions

    var sessions: [WorkoutSession] = []

    // MARK: Loading / Error State

    var isLoading: Bool = false
    var hasPlan: Bool = true
    var errorMessage: String? = nil

    // Variation (1–4) assigned at subscription time.
    // Returned by /api/workouts/current-week and passed to WorkoutDetailView
    // so exercises are filtered to the user's pre-assigned variation.
    var variation: Int = 1

    // MARK: - Fetch

    func fetch() async {
        guard let token = UserDefaults.standard.string(
            forKey: Config.UserDefaultsKey.supabaseSessionToken
        ) else {
            #if DEBUG
            print("[WorkoutsViewModel] No auth token found")
            #endif
            return
        }

        let urlString = Config.apiBaseURL + "/api/workouts/current-week"
        guard let url = URL(string: urlString) else {
            #if DEBUG
            print("[WorkoutsViewModel] Invalid URL: \(urlString)")
            #endif
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        #if DEBUG
        print("[WorkoutsViewModel] Fetching workouts from: \(urlString)")
        print("[WorkoutsViewModel] Auth token present: \(!token.isEmpty)")
        #endif

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let http = response as? HTTPURLResponse

            #if DEBUG
            print("[WorkoutsViewModel] Fetch response status: \(http?.statusCode ?? -1)")
            if let http = http {
                print("[WorkoutsViewModel] Response headers: \(http.allHeaderFields)")
            }
            #endif

            if http?.statusCode == 404 {
                // Try to surface the backend's error message (e.g. "No active subscription found.")
                let backendMessage = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                    .flatMap { $0["error"] as? String }
                if let backendMessage {
                    errorMessage = backendMessage
                } else {
                    hasPlan = false
                }
                #if DEBUG
                let responseBody = String(data: data, encoding: .utf8) ?? "no body"
                print("[WorkoutsViewModel] 404 Response body: \(responseBody)")
                #endif
                return
            }

            guard http?.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                errorMessage = "Failed to load workouts. Please try again."
                #if DEBUG
                print("[WorkoutsViewModel] Invalid response or JSON parse failed")
                #endif
                return
            }

            hasPlan = true
            weekNumber     = json["week_number"]     as? Int    ?? 1
            variation      = json["variation"]       as? Int    ?? 1
            cooldownActive = json["cooldown_active"] as? Bool   ?? false
            hoursRemaining = json["hours_remaining"] as? Double ?? 0

            let workoutsArr = json["workouts"] as? [[String: Any]] ?? []
            
            #if DEBUG
            print("[WorkoutsViewModel] Received \(workoutsArr.count) workouts from API")
            #endif

            let logDateFormatter = DateFormatter()
            logDateFormatter.dateFormat = "yyyy-MM-dd"

            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "EEE, MMM d"

            let mapped: [WorkoutSession] = workoutsArr.compactMap { w in
                guard let idString = w["id"] as? String,
                      let title = w["title"] as? String
                else {
                    #if DEBUG
                    print("[WorkoutsViewModel] Skipping workout - missing id or title: \(w)")
                    #endif
                    return nil
                }

                let description = w["description"] as? String ?? ""
                let dayNumber = w["day_number"] as? Int ?? 0
                let statusString = w["status"] as? String ?? ""
                let loggedDateString = w["logged_date"] as? String

                let status: WorkoutStatus
                switch statusString {
                case "completed": status = .completed
                case "next":      status = .today
                default:          status = .locked
                }

                let shortDay: String
                switch status {
                case .completed:
                    if let dateStr = loggedDateString,
                       let date = logDateFormatter.date(from: dateStr) {
                        shortDay = displayFormatter.string(from: date).uppercased()
                    } else {
                        shortDay = "DAY \(dayNumber)"
                    }
                case .today:
                    shortDay = "TODAY"
                case .locked:
                    shortDay = "DAY \(dayNumber)"
                }

                return WorkoutSession(
                    id: UUID(),
                    workoutId: idString,
                    shortDay: shortDay,
                    name: title,
                    description: description,
                    durationMinutes: 45,
                    calories: 320,
                    focusArea: "Strength",
                    status: status,
                    loggedDate: loggedDateString
                )
            }

            sessions = mapped
            weekDays = buildWeekDays()
            
            #if DEBUG
            print("[WorkoutsViewModel] Successfully mapped \(mapped.count) workout sessions")
            #endif

        } catch {
            errorMessage = "Network error. Check your connection and try again."
            #if DEBUG
            print("[WorkoutsViewModel] Fetch error: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Build Week Days

    private func buildWeekDays() -> [WeekDayItem] {
        let calendar = Calendar.current

        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return []
        }

        let logDateFormatter = DateFormatter()
        logDateFormatter.dateFormat = "yyyy-MM-dd"

        let matchFormatter = DateFormatter()
        matchFormatter.dateFormat = "yyyy-MM-dd"

        let abbrevFormatter = DateFormatter()
        abbrevFormatter.dateFormat = "EEE"

        let loggedDates: Set<String> = Set(
            sessions.compactMap { $0.loggedDate }
        )

        var items: [WeekDayItem] = []
        var current = weekInterval.start

        while current < weekInterval.end {
            let dayNumber = calendar.component(.day, from: current)
            let isToday = calendar.isDateInToday(current)
            let dateKey = matchFormatter.string(from: current)
            let hasCompleted = loggedDates.contains(dateKey)
            let abbreviation = abbrevFormatter.string(from: current).uppercased()

            items.append(WeekDayItem(
                id: UUID(),
                abbreviation: abbreviation,
                dayNumber: dayNumber,
                isToday: isToday,
                hasCompletedWorkout: hasCompleted
            ))

            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return items
    }
}
