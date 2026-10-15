import SwiftUI
import TatinKit

/// メニューバーのアイコンをクリックしたときに開く中身。
struct MenuContent: View {
    @State private var launchesAtLogin = LoginItem.isEnabled
    @State private var failureMessage: String?

    private let metadata = AppMetadata.current
    private static let logger = TatinLog.logger(category: "MenuContent")

    var body: some View {
        Text("\(metadata.name) \(metadata.displayVersion)")

        Divider()

        Toggle("ログイン時に起動", isOn: launchAtLoginBinding)

        if let failureMessage {
            Text(failureMessage)
        }

        Divider()

        Button("終了") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchesAtLogin },
            set: { updateLaunchAtLogin(to: $0) }
        )
    }

    private func updateLaunchAtLogin(to enabled: Bool) {
        do {
            if enabled {
                try LoginItem.enable()
            } else {
                try LoginItem.disable()
            }
            failureMessage = nil
        } catch {
            // .app として起動していない場合などに失敗する。
            // 勝手にトグルが入ったままにならないよう、実際の状態を読み直す。
            Self.logger.error("ログイン項目を更新できなかった: \(error.localizedDescription, privacy: .public)")
            failureMessage = "ログイン項目を変更できませんでした"
        }
        launchesAtLogin = LoginItem.isEnabled
    }
}
