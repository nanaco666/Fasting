import Testing
@testable import FastingCore

@Suite("AppLanguage Tests")
struct AppLanguageTests {

    @Test("English language properties")
    func english() {
        let lang = AppLanguage.english
        #expect(lang.rawValue == "en")
        #expect(lang.displayName == "English")
        #expect(lang.id == "en")
    }

    @Test("Chinese language properties")
    func chinese() {
        let lang = AppLanguage.chinese
        #expect(lang.rawValue == "zh-Hans")
        #expect(lang.displayName == "中文")
        #expect(lang.id == "zh-Hans")
    }

    @Test("All cases count")
    func allCases() {
        #expect(AppLanguage.allCases.count == 2)
    }
}
