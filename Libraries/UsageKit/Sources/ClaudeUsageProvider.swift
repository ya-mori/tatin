import Foundation

/// Claude の月次クレジット消化率を取る。
///
/// Claude Code の `/usage` が参照しているのと同じ API を、本体がキーチェーンに
/// 置いた OAuth トークンで呼ぶ。ローカルのセッションログからコストを積むやり方は
/// 定価での計算になり実際の請求額と合わないため、取得元の値をそのまま使う。
public struct ClaudeUsageProvider: UsageProvider {
    public let source = UsageSource.claude

    static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    static let keychainService = "Claude Code-credentials"

    public init() {}

    public func fetch() async throws -> UsageSnapshot {
        let token = try Self.accessToken()
        let data = try await UsageHTTP.get(
            Self.endpoint,
            headers: [
                "Authorization": "Bearer \(token)",
                "anthropic-beta": "oauth-2025-04-20",
                "Accept": "application/json",
            ]
        )
        return try Self.snapshot(from: data, now: Date())
    }

    static func accessToken() throws -> String {
        let data = try Keychain.genericPassword(service: keychainService)
        guard let credentials = try? JSONDecoder().decode(StoredCredentials.self, from: data) else {
            throw UsageError.credentialsUnavailable("\(keychainService): 形式が想定と違います")
        }
        return credentials.claudeAiOauth.accessToken
    }

    static func snapshot(from data: Data, now: Date) throws -> UsageSnapshot {
        let response: UsageResponse
        do {
            response = try UsageHTTP.decoder().decode(UsageResponse.self, from: data)
        } catch {
            throw UsageError.unexpectedResponse(error.localizedDescription)
        }
        guard let spend = response.spend, let used = spend.used, let limit = spend.limit else {
            throw UsageError.unexpectedResponse("spend が空です")
        }

        // percent は取得元が丸めた値。無い場合だけ自前で割る。
        let percent = spend.percent ?? limit.percent(of: used)
        return UsageSnapshot(
            source: .claude,
            usedPercent: percent,
            detail: "\(used.formatted()) / \(limit.formatted())",
            resetAt: BillingCycle.nextReset(after: now),
            fetchedAt: now
        )
    }
}

extension ClaudeUsageProvider {
    struct StoredCredentials: Decodable {
        struct OAuth: Decodable {
            let accessToken: String
        }
        let claudeAiOauth: OAuth
    }

    struct UsageResponse: Decodable {
        struct Spend: Decodable {
            let used: Money?
            let limit: Money?
            let percent: Int?
        }
        let spend: Spend?
    }

    /// 最小単位（セント）で表された金額。
    struct Money: Decodable {
        let amountMinor: Int
        let currency: String?
        let exponent: Int

        var amount: Double {
            Double(amountMinor) / pow(10, Double(exponent))
        }

        func percent(of other: Money) -> Int {
            guard amountMinor > 0 else { return 0 }
            return Int((Double(other.amountMinor) / Double(amountMinor) * 100).rounded())
        }

        func formatted() -> String {
            let value = String(format: "%.\(exponent)f", amount)
            return currency == "USD" ? "$\(value)" : "\(value) \(currency ?? "")"
        }
    }
}
