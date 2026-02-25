import Foundation
import Testing
@testable import FastingCore

@Suite("FastingPreset Tests")
struct FastingPresetTests {

    @Test("All presets have correct fasting hours")
    func fastingHours() {
        #expect(FastingPreset.sixteen8.fastingHours == 16)
        #expect(FastingPreset.eighteen6.fastingHours == 18)
        #expect(FastingPreset.twenty4.fastingHours == 20)
        #expect(FastingPreset.omad.fastingHours == 23)
        #expect(FastingPreset.custom.fastingHours == 16)
    }

    @Test("Eating window is 24 minus fasting hours")
    func eatingWindow() {
        for preset in FastingPreset.allCases {
            #expect(preset.eatingWindow == 24 - preset.fastingHours)
        }
    }

    @Test("All presets are Codable")
    func codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for preset in FastingPreset.allCases {
            let data = try encoder.encode(preset)
            let decoded = try decoder.decode(FastingPreset.self, from: data)
            #expect(decoded == preset)
        }
    }

    @Test("Raw values round-trip correctly")
    func rawValues() {
        for preset in FastingPreset.allCases {
            #expect(FastingPreset(rawValue: preset.rawValue) == preset)
        }
    }

    @Test("CaseIterable contains all 5 presets")
    func allCases() {
        #expect(FastingPreset.allCases.count == 5)
    }
}

@Suite("FastingStatus Tests")
struct FastingStatusTests {

    @Test("Status raw values match expected strings")
    func rawValues() {
        #expect(FastingStatus.inProgress.rawValue == "in_progress")
        #expect(FastingStatus.completed.rawValue == "completed")
        #expect(FastingStatus.cancelled.rawValue == "cancelled")
    }

    @Test("Status display names are correct")
    func displayNames() {
        #expect(FastingStatus.inProgress.displayName == "进行中")
        #expect(FastingStatus.completed.displayName == "已完成")
        #expect(FastingStatus.cancelled.displayName == "已取消")
    }

    @Test("Status is Codable")
    func codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let statuses: [FastingStatus] = [.inProgress, .completed, .cancelled]
        for status in statuses {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(FastingStatus.self, from: data)
            #expect(decoded == status)
        }
    }
}
