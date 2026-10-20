import SwiftUI
import TatinKit
import UsageKit

/// メニューバーのアイコンをクリックしたときに開く中身。
struct UsageMenu: View {
    let store: UsageStore

    @State private var launchesAtLogin = LoginItem.isEnabled
    @State private var failureMessage: String?

    private static let logger = TatinLog.logger(category: "UsageMenu")

    var body: some View {
        if store.entries.isEmpty {
            Text(store.isRefreshing ? "取得中…" : "まだ取得していません")
        }

        ForEach(store.entries) { entry in
            Text(Self.line(for: entry))
        }

        Divider()

        Button(store.isRefreshing ? "更新中…" : "今すぐ更新") {
            Task { await store.refresh() }
        }
        .disabled(store.isRefreshing)

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

    /// 取得元ごとに 1 行。メニューでは折り返せないので項目を増やさずに収める。
    private static func line(for entry: UsageEntry) -> String {
        guard let snapshot = entry.snapshot else {
            return "\(entry.source.displayName): \(entry.error?.errorDescription ?? "取得できません")"
        }

        var parts = ["\(entry.source.displayName)  \(snapshot.remainingPercent)%"]
        if !snapshot.detail.isEmpty {
            parts.append(snapshot.detail)
        }
        if let reset = snapshot.resetDescription() {
            parts.append(reset)
        }
        return parts.joined(separator: "  ·  ")
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
