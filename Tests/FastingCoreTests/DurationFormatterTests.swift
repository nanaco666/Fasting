import Foundation
import Testing
@testable import FastingCore

@Suite("DurationFormatter Tests")
struct DurationFormatterTests {

    @Test("Format zero duration")
    func formatZero() {
        #expect(DurationFormatter.format(0) == "00:00:00")
    }

    @Test("Format hours, minutes, seconds")
    func formatHMS() {
        let duration: TimeInterval = 16 * 3600 + 30 * 60 + 45
        #expect(DurationFormatter.format(duration) == "16:30:45")
    }

    @Test("Format exactly one hour")
    func formatOneHour() {
        #expect(DurationFormatter.format(3600) == "01:00:00")
    }

    @Test("Short format with hours")
    func shortFormatWithHours() {
        let duration: TimeInterval = 2 * 3600 + 30 * 60
        #expect(DurationFormatter.formatShort(duration) == "2小时30分钟")
    }

    @Test("Short format minutes only")
    func shortFormatMinutesOnly() {
        let duration: TimeInterval = 45 * 60
        #expect(DurationFormatter.formatShort(duration) == "45分钟")
    }

    @Test("Short format zero")
    func shortFormatZero() {
        #expect(DurationFormatter.formatShort(0) == "0分钟")
    }

    @Test("Progress calculation normal case")
    func progressNormal() {
        let progress = DurationFormatter.progress(current: 8 * 3600, target: 16 * 3600)
        #expect(progress == 0.5)
    }

    @Test("Progress capped at 1.0")
    func progressCapped() {
        let progress = DurationFormatter.progress(current: 20 * 3600, target: 16 * 3600)
        #expect(progress == 1.0)
    }

    @Test("Progress with zero target")
    func progressZeroTarget() {
        let progress = DurationFormatter.progress(current: 100, target: 0)
        #expect(progress == 0)
    }
}
