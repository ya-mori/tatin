import Foundation

/// ひとつの取得元から使用率を取ってくる担当。
public protocol UsageProvider: Sendable {
    var source: UsageSource { get }
    func fetch() async throws -> UsageSnapshot
}

/// 取得元ごとの HTTP 呼び出しで共通する部分。
enum UsageHTTP {
    /// GET して本文を返す。失敗は `UsageError` に寄せる。
    static func get(
        _ url: URL,
        headers: [String: String],
        session: URLSession = .shared
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw UsageError.transportFailed(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw UsageError.unexpectedResponse("HTTP 応答ではありません")
        }
        switch http.statusCode {
        case 200..<300:
            return data
        case 401, 403:
            throw UsageError.unauthorized
        default:
            throw UsageError.unexpectedResponse("HTTP \(http.statusCode)")
        }
    }

    /// 取得元の JSON はどちらも snake_case なので変換を既定にする。
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
