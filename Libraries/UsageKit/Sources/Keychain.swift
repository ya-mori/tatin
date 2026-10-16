import Foundation
import Security

/// キーチェーンからの読み取り。書き込みはしない。
enum Keychain {
    /// サービス名でジェネリックパスワードを引く。
    ///
    /// 他のアプリが作った項目を読むため、初回はシステムの許可ダイアログが出る。
    static func genericPassword(service: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            let message = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
            throw UsageError.credentialsUnavailable("\(service): \(message)")
        }
        guard let data = item as? Data else {
            throw UsageError.credentialsUnavailable("\(service): 中身を取り出せません")
        }
        return data
    }
}
