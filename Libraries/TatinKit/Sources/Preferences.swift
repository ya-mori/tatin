import Foundation

/// アプリの設定を UserDefaults に読み書きする。
///
/// `UserDefaults` の `bool(forKey:)` などは未設定のキーに対して `false` や `0` を返すため、
/// 「設定されていない」と「false が設定されている」を区別できない。
/// ここでは既定値を呼び出し側が指定できるようにしている。
/// `UserDefaults` 自体はスレッドセーフだが `Sendable` に準拠していないため、
/// ここでは `@unchecked Sendable` として扱う。
public struct Preferences: @unchecked Sendable {
    private let defaults: UserDefaults

    /// - Parameter suiteName: 設定を他と分けたいときの suite 名。
    ///   指定しない、または開けない場合は標準の UserDefaults を使う。
    public init(suiteName: String? = nil) {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            self.defaults = suite
        } else {
            self.defaults = .standard
        }
    }

    public func bool(forKey key: String, default defaultValue: Bool = false) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }

    public func integer(forKey key: String, default defaultValue: Int = 0) -> Int {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.integer(forKey: key)
    }

    public func string(forKey key: String, default defaultValue: String? = nil) -> String? {
        defaults.string(forKey: key) ?? defaultValue
    }

    public func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func set(_ value: Int, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func set(_ value: String?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
