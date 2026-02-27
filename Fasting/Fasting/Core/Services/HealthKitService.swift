//
//  HealthKitService.swift
//  Fasting
//
//  HealthKit 集成 — 读取运动/活动数据
//

import Foundation
import HealthKit

@Observable
final class HealthKitService {
    static let shared = HealthKitService()
    
    private let store = HKHealthStore()
    
    var isAuthorized = false
    var todayActiveCalories: Double = 0
    var todaySteps: Int = 0
    var weekWorkouts: [WorkoutSummary] = []
    var weekActiveCalories: Double = 0
    
    // MARK: - Authorization
    
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.stepCount),
            HKQuantityType(.basalEnergyBurned),
            HKObjectType.workoutType()
        ]
        
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }
    
    // MARK: - Fetch Today's Data
    
    func fetchTodayData() async {
        async let calories = fetchTodayActiveCalories()
        async let steps = fetchTodaySteps()
        
        let (cal, stp) = await (calories, steps)
        
        await MainActor.run {
            todayActiveCalories = cal
            todaySteps = stp
        }
    }
    
    // MARK: - Fetch Week Data
    
    func fetchWeekData() async {
        async let workouts = fetchWeekWorkouts()
        async let weekCal = fetchWeekActiveCalories()
        
        let (w, c) = await (workouts, weekCal)
        
        await MainActor.run {
            weekWorkouts = w
            weekActiveCalories = c
        }
    }
    
    // MARK: - Active Calories
    
    private func fetchTodayActiveCalories() async -> Double {
        let type = HKQuantityType(.activeEnergyBurned)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
    
    private func fetchWeekActiveCalories() async -> Double {
        let type = HKQuantityType(.activeEnergyBurned)
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
    
    // MARK: - Steps
    
    private func fetchTodaySteps() async -> Int {
        let type = HKQuantityType(.stepCount)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(value))
            }
            store.execute(query)
        }
    }
    
    // MARK: - Workouts
    
    private func fetchWeekWorkouts() async -> [WorkoutSummary] {
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 50,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let workouts = (samples as? [HKWorkout]) ?? []
                let summaries = workouts.map { workout -> WorkoutSummary in
                    WorkoutSummary(
                        type: workout.workoutActivityType,
                        duration: workout.duration,
                        calories: workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0,
                        date: workout.startDate
                    )
                }
                continuation.resume(returning: summaries)
            }
            store.execute(query)
        }
    }
}

// MARK: - Workout Summary

struct WorkoutSummary: Identifiable {
    let id = UUID()
    let type: HKWorkoutActivityType
    let duration: TimeInterval
    let calories: Double
    let date: Date
    
    var typeName: String {
        switch type {
        case .running: return "Running".localized
        case .walking: return "Walking".localized
        case .cycling: return "Cycling".localized
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "Strength Training".localized
        case .yoga: return "Yoga".localized
        case .swimming: return "Swimming".localized
        case .highIntensityIntervalTraining: return "HIIT".localized
        case .coreTraining: return "Core Training".localized
        case .elliptical: return "Elliptical".localized
        case .rowing: return "Rowing".localized
        default: return "Workout".localized
        }
    }
    
    var typeIcon: String {
        switch type {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        case .swimming: return "figure.pool.swim"
        case .highIntensityIntervalTraining: return "flame.fill"
        case .coreTraining: return "figure.core.training"
        default: return "figure.mixed.cardio"
        }
    }
    
    var durationFormatted: String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}
