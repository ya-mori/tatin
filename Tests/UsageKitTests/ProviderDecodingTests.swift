import Foundation
import Testing

@testable import UsageKit

/// 取得元が実際に返す形をそのまま縮めたもの。
/// 応答の構造が変わったらここで落ちる。
@Suite("応答の読み取り")
struct ProviderDecodingTests {
    private let now = Date(timeIntervalSince1970: 1_792_000_000)  // 2026-10-15 頃

    @Test("Claude の応答から消化率と内訳を組み立てる")
    func claudeSnapshot() throws {
        let json = Data(
            """
            {
              "five_hour": null,
              "spend": {
                "used": {"amount_minor": 2500, "currency": "USD", "exponent": 2},
                "limit": {"amount_minor": 10000, "currency": "USD", "exponent": 2},
                "percent": 25,
                "severity": "normal"
              }
            }
            """.utf8)

        let snapshot = try ClaudeUsageProvider.snapshot(from: json, now: now)

        #expect(snapshot.source == .claude)
        #expect(snapshot.usedPercent == 25)
        #expect(snapshot.detail == "$25.00 / $100.00")
        // Claude 側はリセット時刻を返さないため、請求サイクルから補う。
        #expect(snapshot.resetAt == BillingCycle.nextReset(after: now))
    }

    @Test("Claude の percent が無ければ使用量から割る")
    func claudePercentFallback() throws {
        let json = Data(
            """
            {"spend": {
              "used": {"amount_minor": 5000, "currency": "USD", "exponent": 2},
              "limit": {"amount_minor": 10000, "currency": "USD", "exponent": 2}
            }}
            """.utf8)

        #expect(try ClaudeUsageProvider.snapshot(from: json, now: now).usedPercent == 50)
    }

    @Test("Claude の spend が空なら応答の形として扱う")
    func claudeMissingSpend() {
        let json = Data(#"{"five_hour": null, "limits": []}"#.utf8)

        #expect(throws: UsageError.unexpectedResponse("spend が空です")) {
            try ClaudeUsageProvider.snapshot(from: json, now: now)
        }
    }

    @Test("Codex の応答から消化率とリセット時刻を組み立てる")
    func codexSnapshot() throws {
        let json = Data(
            """
            {
              "plan_type": "business",
              "rate_limit": null,
              "spend_control": {
                "reached": false,
                "individual_limit": {
                  "source": "workspace_spend_controls",
                  "unit": "credit",
                  "limit": "1000",
                  "used": "234.5678901234",
                  "used_percent": 23,
                  "remaining_percent": 77,
                  "reset_at": 1793491200
                }
              }
            }
            """.utf8)

        let snapshot = try CodexUsageProvider.snapshot(from: json, now: now)

        #expect(snapshot.source == .codex)
        #expect(snapshot.usedPercent == 23)
        // 小数込みで返るので、表示では丸めて桁区切りを入れる。
        #expect(snapshot.detail == "235 / 1,000 クレジット")
        #expect(snapshot.resetAt == Date(timeIntervalSince1970: 1_793_491_200))
    }

    @Test("Codex の上限情報が空なら応答の形として扱う")
    func codexMissingLimit() {
        let json = Data(#"{"plan_type": "business", "spend_control": {"reached": false}}"#.utf8)

        #expect(throws: UsageError.unexpectedResponse("individual_limit が空です")) {
            try CodexUsageProvider.snapshot(from: json, now: now)
        }
    }
}
