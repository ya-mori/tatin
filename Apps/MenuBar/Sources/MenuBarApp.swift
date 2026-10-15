import SwiftUI

@main
struct MenuBarApp: App {
    var body: some Scene {
        MenuBarExtra {
            MenuContent()
        } label: {
            Image(nsImage: Self.menuBarIcon)
        }
        // ポップオーバーではなく、通常のメニューとして開く。
        .menuBarExtraStyle(.menu)
    }

    /// メニューバーに出すアイコン。
    ///
    /// .app の Resources にある AppIcon.icns を読み、テンプレート画像として扱う。
    /// テンプレートにすると macOS は元画像の色を捨てて形だけを使い、背景の明暗に
    /// 合わせて塗り直す。そのため白一色の画像でもライトモードでは黒く描かれる。
    @MainActor
    private static let menuBarIcon: NSImage = {
        guard let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
            let image = NSImage(contentsOf: url)
        else {
            // .app の外で起動した場合。アイコンが無いとメニューを開けなくなるため記号で代替する。
            return NSImage(
                systemSymbolName: "square.stack.3d.up.fill",
                accessibilityDescription: "tatin"
            ) ?? NSImage()
        }
        // .icns は 1024px まで含むので、メニューバーの高さに合わせて縮める。
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }()
}
