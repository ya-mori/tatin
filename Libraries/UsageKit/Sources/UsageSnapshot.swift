import Foundation

/// 使用率の取得元。
public enum UsageSource: String, Sendable, CaseIterable, Identifiable {
    case claude
    case codex

    public var id: String { rawValue }

    /// メニューに出す表示名。
    public var displayName: String {
        switch self {
        case .claude: "Claude"
        case .codex: "Codex"
        }
    }

    /// メニューバーに並べるための短い名前。幅が限られるので 2 文字に収める。
    public var shortName: String {
        switch self {
        case .claude: "CL"
        case .codex: "CX"
        }
    }
}

/// ある時点での上限消化の状況。
public struct UsageSnapshot: Sendable, Equatable {
    public let source: UsageSource
    /// 上限に対する消化率（%）。
    public let usedPercent: Int
    /// "$25.00 / $100.00" のような内訳。表示専用で、計算には使わない。
    public let detail: String
    /// 次に上限がリセットされる時刻。取得元が返さない場合は請求サイクルから補う。
    public let resetAt: Date?
    public let fetchedAt: Date

    public init(
        source: UsageSource,
        usedPercent: Int,
        detail: String,
        resetAt: Date?,
        fetchedAt: Date = Date()
    ) {
        self.source = source
        self.usedPercent = usedPercent
        self.detail = detail
        self.resetAt = resetAt
        self.fetchedAt = fetchedAt
    }

    /// "あと 15 日" のような、リセットまでの残り。
    ///
    /// 日単位では潰れてしまう最終日だけ時間で出す。
    public func resetDescription(now: Date = Date()) -> String? {
        guard let resetAt else { return nil }
        let remaining = resetAt.timeIntervalSince(now)
        guard remaining > 0 else { return "まもなくリセット" }

        let hours = Int(remaining / 3600)
        if hours >= 24 {
            return "あと \(hours / 24) 日"
        }
        if hours >= 1 {
            return "あと \(hours) 時間"
        }
        return "あと \(max(1, Int(remaining / 60))) 分"
    }
}
