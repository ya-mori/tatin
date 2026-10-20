import Foundation
import Testing

@testable import UsageKit

@Suite("請求サイクルと残り時間")
struct BillingCycleTests {
    private func utc(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: components)!
    }

    @Test("次のリセットは翌月 1 日 00:00 UTC")
    func nextResetIsFirstOfNextMonth() {
        #expect(BillingCycle.nextReset(after: utc(2026, 10, 16, 6)) == utc(2026, 11, 1))
        // 当月 1 日のうちでも、次の切り替わりは翌月。
        #expect(BillingCycle.nextReset(after: utc(2026, 10, 1, 0)) == utc(2026, 11, 1))
    }

    @Test("年をまたぐ")
    func nextResetCrossesYear() {
        #expect(BillingCycle.nextReset(after: utc(2026, 12, 20)) == utc(2027, 1, 1))
    }

    @Test("残り時間は日・時間・分で粒度を変える")
    func resetDescriptionChangesGranularity() {
        func snapshot(resetAt: Date) -> UsageSnapshot {
            UsageSnapshot(source: .claude, usedPercent: 25, detail: "", resetAt: resetAt)
        }
        let now = utc(2026, 10, 16)

        #expect(snapshot(resetAt: utc(2026, 11, 1)).resetDescription(now: now) == "あと 16 日")
        #expect(snapshot(resetAt: utc(2026, 10, 16, 3)).resetDescription(now: now) == "あと 3 時間")
        #expect(
            snapshot(resetAt: now.addingTimeInterval(600)).resetDescription(now: now) == "あと 10 分")
        // 過ぎていても負の残り時間は見せない。
        #expect(snapshot(resetAt: utc(2026, 10, 15)).resetDescription(now: now) == "まもなくリセット")
    }

    @Test("残りの割合は消化率の裏返しで、上限を超えても負にしない")
    func remainingPercentNeverGoesNegative() {
        func snapshot(used: Int) -> UsageSnapshot {
            UsageSnapshot(source: .claude, usedPercent: used, detail: "", resetAt: nil)
        }

        #expect(snapshot(used: 25).remainingPercent == 75)
        #expect(snapshot(used: 0).remainingPercent == 100)
        #expect(snapshot(used: 100).remainingPercent == 0)
        #expect(snapshot(used: 130).remainingPercent == 0)
    }

    @Test("リセット時刻が無ければ残り時間も出さない")
    func noResetMeansNoDescription() {
        let snapshot = UsageSnapshot(source: .codex, usedPercent: 23, detail: "", resetAt: nil)

        #expect(snapshot.resetDescription() == nil)
    }
}
