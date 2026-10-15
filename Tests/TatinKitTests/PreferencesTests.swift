import Foundation
import Testing

@testable import TatinKit

/// テストごとに独立した suite を使い、標準の設定や他のテストを汚さずに検証する。
private func withTemporarySuite(_ body: (Preferences) -> Void) {
    let suiteName = "dev.tatin.tests.\(UUID().uuidString)"
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    body(Preferences(suiteName: suiteName))
}

@Suite("Preferences")
struct PreferencesTests {
    @Test("未設定のキーでは指定した既定値を返す")
    func unsetKeyReturnsGivenDefault() {
        withTemporarySuite { preferences in
            // UserDefaults 本来の bool(forKey:) は未設定で false を返すため、
            // 既定値 true がそのまま返ることを確かめる。
            #expect(preferences.bool(forKey: "missing", default: true))
            #expect(preferences.integer(forKey: "missing", default: 42) == 42)
            #expect(preferences.string(forKey: "missing", default: "none") == "none")
        }
    }

    @Test("保存された false は未設定と区別される")
    func storedFalseIsDistinguishedFromUnset() {
        withTemporarySuite { preferences in
            preferences.set(false, forKey: "flag")

            // 既定値が true でも、保存された false が優先される。
            #expect(preferences.bool(forKey: "flag", default: true) == false)
        }
    }

    @Test("書いた値をそのまま読み戻せる")
    func roundTrip() {
        withTemporarySuite { preferences in
            preferences.set(true, forKey: "enabled")
            preferences.set(7, forKey: "count")
            preferences.set("tatin", forKey: "label")

            #expect(preferences.bool(forKey: "enabled"))
            #expect(preferences.integer(forKey: "count") == 7)
            #expect(preferences.string(forKey: "label") == "tatin")
        }
    }

    @Test("削除すると既定値に戻る")
    func removeValueFallsBackToDefault() {
        withTemporarySuite { preferences in
            preferences.set(true, forKey: "enabled")
            preferences.removeValue(forKey: "enabled")

            #expect(preferences.bool(forKey: "enabled", default: false) == false)
            #expect(preferences.bool(forKey: "enabled", default: true))
        }
    }
}
