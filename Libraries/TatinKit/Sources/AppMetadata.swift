import Foundation

/// 実行中のアプリの素性。メニューに表示したりログに添えたりする。
public struct AppMetadata: Sendable, Equatable {
    public let name: String
    public let bundleIdentifier: String
    public let version: String
    public let build: String

    public init(name: String, bundleIdentifier: String, version: String, build: String) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.build = build
    }

    /// 実行中のバンドルの Info.plist から読み取る。
    ///
    /// `swift run` で .app を経由せずに起動した場合は Info.plist が無いため、
    /// 実行ファイル名などで埋めて落ちないようにしている。
    public static var current: AppMetadata {
        let bundle = Bundle.main
        let info = bundle.infoDictionary ?? [:]
        let fallbackName = ProcessInfo.processInfo.processName
        return AppMetadata(
            name: info["CFBundleName"] as? String ?? fallbackName,
            bundleIdentifier: bundle.bundleIdentifier ?? "dev.tatin.\(fallbackName)",
            version: info["CFBundleShortVersionString"] as? String ?? "0.0.0",
            build: info["CFBundleVersion"] as? String ?? "0"
        )
    }

    /// メニューなどに出す "0.1.0 (1)" の形。
    public var displayVersion: String {
        "\(version) (\(build))"
    }
}
