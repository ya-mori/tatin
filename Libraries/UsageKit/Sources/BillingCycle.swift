import Foundation

/// 月次の請求サイクル。
///
/// Claude の使用量 API はリセット時刻を返さないため、ここで補う。
/// 実際の画面表示は「11月1日 9:00 JST にリセット」で、Codex が返す
/// `reset_at` も同じ時刻を指すことから、毎月 1 日 00:00 UTC で切り替わるとみなす。
enum BillingCycle {
    static func nextReset(after date: Date) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        guard let utc = TimeZone(identifier: "UTC") else { return nil }
        calendar.timeZone = utc

        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        guard let thisMonth = calendar.date(from: components) else { return nil }

        // 当月 1 日はすでに過ぎているので、次の切り替わりは翌月 1 日。
        return calendar.date(byAdding: .month, value: 1, to: thisMonth)
    }
}
