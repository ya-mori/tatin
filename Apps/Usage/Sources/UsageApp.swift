import SwiftUI
import UsageKit

@main
struct UsageApp: App {
    @State private var store: UsageStore

    /// 取得元を叩きすぎず、席を外して戻ったときには新しくなっている程度の間隔。
    private static let refreshInterval = Duration.seconds(300)

    init() {
        // メニューを開く前から数字が出ているよう、起動した時点で引き始める。
        // MenuBarExtra のラベルは通常のビュー階層の外にあり .task が動かない。
        let store = UsageStore()
        store.startAutoRefresh(every: Self.refreshInterval)
        _store = State(initialValue: store)
    }

    var body: some Scene {
        MenuBarExtra {
            UsageMenu(store: store)
        } label: {
            // HStack などで包むと MenuBarExtra が中身を拾えずラベルが消える。
            // アイコンと文字はそれぞれ直に置く。
            Image(nsImage: Self.icon)
            Text(store.menuBarTitle)
        }
        // ポップオーバーではなく、通常のメニューとして開く。
        .menuBarExtraStyle(.menu)
    }

    /// .app の Resources にある AppIcon.icns を読み、テンプレート画像として扱う。
    ///
    /// テンプレートにすると macOS は元画像の色を捨てて形だけを使い、背景の明暗に
    /// 合わせて塗り直す。そのため白一色の画像でもライトモードでは黒く描かれる。
    @MainActor
    private static let icon: NSImage = {
        guard let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
            let image = NSImage(contentsOf: url)
        else {
            // .app の外で起動した場合。アイコンが無いとメニューを開けなくなるため記号で代替する。
            return NSImage(
                systemSymbolName: "gauge.with.needle",
                accessibilityDescription: "tatin"
            ) ?? NSImage()
        }
        // .icns は 1024px まで含むので、メニューバーの高さに合わせて縮める。
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }()
}
