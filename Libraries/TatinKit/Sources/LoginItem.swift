import Foundation
import ServiceManagement

/// ログイン時の自動起動の登録と解除。
///
/// `SMAppService.mainApp` は .app バンドルとして起動されていることを前提とする。
/// `swift run` でバイナリを直接動かした場合は登録に失敗するため、
/// 動作確認は `mise run start <アプリ名>` で .app として起動して行う。
public enum LoginItem {
    public static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public static func enable() throws {
        try SMAppService.mainApp.register()
    }

    public static func disable() throws {
        try SMAppService.mainApp.unregister()
    }

    /// 現在の状態を反転させる。
    public static func toggle() throws {
        if isEnabled {
            try disable()
        } else {
            try enable()
        }
    }
}
