import OSLog

/// アプリ共通のログ出力。
///
/// Console.app や `log stream` で subsystem に `dev.tatin` を指定すると
/// tatin のアプリだけを追える。
public enum TatinLog {
    public static let subsystem = "dev.tatin"

    public static func logger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}
