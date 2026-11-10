import Foundation
import SwiftUI

// MARK: - Watch Sync Profile
struct WatchSyncProfile: Identifiable, Equatable {
    let id: String
    let profileName: String
    let subtitle: String
    let badgeIcon: String
    let accentColor: Color
    
    // Apple Watch / Health Telemetry
    let restingHeartRateBPM: Int
    let bloodOxygenSpO2: Int
    let dailyExerciseMinutes: Int
    let vo2Max: Double
    let sleepHours: Double
    
    // Corresponding Blood Parameters
    let rbc: Double
    let wbc: Double
    let plt: Double
    let glucose: Double
    
    let healthSummary: String
    
    static let profiles: [WatchSyncProfile] = [
        WatchSyncProfile(
            id: "active_runner",
            profileName: "Active Runner",
            subtitle: "High VO2 Max & optimal insulin sensitivity",
            badgeIcon: "figure.run",
            accentColor: .green,
            restingHeartRateBPM: 54,
            bloodOxygenSpO2: 99,
            dailyExerciseMinutes: 55,
            vo2Max: 52.4,
            sleepHours: 7.8,
            rbc: 5.4,
            wbc: 6200.0,
            plt: 245000.0,
            glucose: 82.0,
            healthSummary: "Aerobic conditioning expands plasma volume, elevates cardiac stroke efficiency (low resting HR), and keeps blood sugar tightly controlled."
        ),
        WatchSyncProfile(
            id: "sedentary_sugar",
            profileName: "Sedentary + High Sugar Diet",
            subtitle: "Hyperglycemia & elevated clotting risk",
            badgeIcon: "sofa.fill",
            accentColor: .orange,
            restingHeartRateBPM: 86,
            bloodOxygenSpO2: 96,
            dailyExerciseMinutes: 8,
            vo2Max: 30.8,
            sleepHours: 5.8,
            rbc: 5.1,
            wbc: 10800.0,
            plt: 435000.0,
            glucose: 198.0,
            healthSummary: "Low physical activity and frequent simple sugar intake drive post-prandial hyperglycemia, mild vascular inflammation, and reactive thrombocytosis."
        ),
        WatchSyncProfile(
            id: "iron_deficient_student",
            profileName: "Iron Deficient Student",
            subtitle: "Anemia tachycardia & fatigue profile",
            badgeIcon: "book.fill",
            accentColor: .red,
            restingHeartRateBPM: 106,
            bloodOxygenSpO2: 92,
            dailyExerciseMinutes: 14,
            vo2Max: 33.2,
            sleepHours: 6.1,
            rbc: 3.1,
            wbc: 6800.0,
            plt: 260000.0,
            glucose: 74.0,
            healthSummary: "Depressed RBC count lowers arterial oxygen delivery, triggering elevated Watch resting heart rate and afternoon exhaustion."
        )
    ]
}
