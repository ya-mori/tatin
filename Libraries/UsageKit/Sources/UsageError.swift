import Foundation

/// 使用率を取れなかった理由。
///
/// 取得元ごとに事情が違うため、メニューにそのまま出せる粒度で分けている。
public enum UsageError: Error, Equatable, Sendable {
    /// 認証情報が見つからない、または読めない。
    case credentialsUnavailable(String)
    /// 認証情報が拒否された。期限切れならツール本体を一度起動すると更新される。
    case unauthorized
    /// 応答は返ったが、想定した形ではなかった。
    case unexpectedResponse(String)
    /// 通信そのものが失敗した。
    case transportFailed(String)
}

extension UsageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .credentialsUnavailable(let detail):
            "認証情報を読めません（\(detail)）"
        case .unauthorized:
            "認証情報が拒否されました。本体を一度起動してログインを更新してください"
        case .unexpectedResponse(let detail):
            "応答の形が想定と違います（\(detail)）"
        case .transportFailed(let detail):
            "通信に失敗しました（\(detail)）"
        }
    }
}
