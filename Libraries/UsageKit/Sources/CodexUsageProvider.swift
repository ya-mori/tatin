import Foundation

/// Codex の月次クレジット消化率を取る。
///
/// セッションログにも `rate_limits` は残るが、Business プランでは中身が
/// すべて null になるため使えない。本体が置いた OAuth トークンで API を呼ぶ。
public struct CodexUsageProvider: UsageProvider {
    public let source = UsageSource.codex

    static let endpoint = URL(string: "https://chatgpt.com/backend-api/codex/usage")!

    /// 本体がトークンを置く場所。
    static var authFileURL: URL {
        URL(fileURLWithPath: NSHomeDirectory()).appending(path: ".codex/auth.json")
    }

    public init() {}

    public func fetch() async throws -> UsageSnapshot {
        let credentials = try Self.credentials()
        let data = try await UsageHTTP.get(
            Self.endpoint,
            headers: [
                "Authorization": "Bearer \(credentials.tokens.accessToken)",
                "chatgpt-account-id": credentials.tokens.accountId,
                "Accept": "application/json",
                "originator": "codex_cli_rs",
            ]
        )
        return try Self.snapshot(from: data, now: Date())
    }

    static func credentials() throws -> StoredCredentials {
        let url = authFileURL
        guard let data = try? Data(contentsOf: url) else {
            throw UsageError.credentialsUnavailable("\(url.path) を読めません")
        }
        guard let credentials = try? UsageHTTP.decoder().decode(StoredCredentials.self, from: data) else {
            throw UsageError.credentialsUnavailable("\(url.path): 形式が想定と違います")
        }
        return credentials
    }

    static func snapshot(from data: Data, now: Date) throws -> UsageSnapshot {
        let response: UsageResponse
        do {
            response = try UsageHTTP.decoder().decode(UsageResponse.self, from: data)
        } catch {
            throw UsageError.unexpectedResponse(error.localizedDescription)
        }
        guard let limit = response.spendControl?.individualLimit else {
            throw UsageError.unexpectedResponse("individual_limit が空です")
        }
        guard let percent = limit.usedPercent else {
            throw UsageError.unexpectedResponse("used_percent がありません")
        }

        return UsageSnapshot(
            source: .codex,
            usedPercent: percent,
            detail: limit.formattedUsage(),
            resetAt: limit.resetAt.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            fetchedAt: now
        )
    }
}

extension CodexUsageProvider {
    struct StoredCredentials: Decodable {
        struct Tokens: Decodable {
            let accessToken: String
            let accountId: String
        }
        let tokens: Tokens
    }

    struct UsageResponse: Decodable {
        struct SpendControl: Decodable {
            /// 上限と消化量。数値も文字列で返ってくる。
            struct IndividualLimit: Decodable {
                let unit: String?
                let limit: String?
                let used: String?
                let usedPercent: Int?
                let resetAt: Int?

                func formattedUsage() -> String {
                    guard let used = Self.rounded(used), let limit = Self.rounded(limit) else {
                        return ""
                    }
                    let suffix = unit == "credit" ? " クレジット" : ""
                    return "\(used) / \(limit)\(suffix)"
                }

                /// "234.5678901234" のような文字列を "235" にする。
                private static func rounded(_ raw: String?) -> String? {
                    guard let raw, let value = Double(raw) else { return nil }
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.maximumFractionDigits = 0
                    return formatter.string(from: NSNumber(value: value))
                }
            }
            let individualLimit: IndividualLimit?
        }
        let spendControl: SpendControl?
    }
}
