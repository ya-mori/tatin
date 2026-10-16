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
            Image(nsImage: Self.renderLabel(items: store.menuBarItems))
        }
        // ポップオーバーではなく、通常のメニューとして開く。
        .menuBarExtraStyle(.menu)
    }

    /// 取得元の記号と消化率を横に並べて 1 枚の画像にする。
    ///
    /// MenuBarExtra のラベルに置ける Text は 1 行だけで、HStack で包むと
    /// ラベルごと消える。記号と数字を交互に並べるには自分で描くしかない。
    @MainActor
    private static func renderLabel(items: [MenuBarItem]) -> NSImage {
        struct Piece {
            let symbol: NSImage?
            let text: NSAttributedString
        }

        // 桁が変わっても幅が動かないよう、数字の幅が揃う書体を使う。
        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        let symbolGap: CGFloat = 3  // 記号とその数字の間
        let itemGap: CGFloat = 9  // 取得元どうしの間
        let height: CGFloat = 16

        let pieces = items.map { item in
            Piece(
                symbol: NSImage(
                    systemSymbolName: item.source.symbolName,
                    accessibilityDescription: item.source.displayName
                )?.withSymbolConfiguration(symbolConfiguration),
                text: NSAttributedString(
                    string: item.text,
                    attributes: [.font: font, .foregroundColor: NSColor.black]
                )
            )
        }

        let width = pieces.enumerated().reduce(into: CGFloat.zero) { total, pair in
            if pair.offset > 0 { total += itemGap }
            total += (pair.element.symbol?.size.width ?? 0) + symbolGap + pair.element.text.size().width
        }

        let image = NSImage(size: NSSize(width: ceil(width), height: height))
        image.lockFocus()
        var x: CGFloat = 0
        for (index, piece) in pieces.enumerated() {
            if index > 0 { x += itemGap }
            if let symbol = piece.symbol {
                let size = symbol.size
                symbol.draw(
                    in: NSRect(x: x, y: (height - size.height) / 2, width: size.width, height: size.height))
                x += size.width
            }
            x += symbolGap
            let textSize = piece.text.size()
            piece.text.draw(at: NSPoint(x: x, y: (height - textSize.height) / 2))
            x += textSize.width
        }
        image.unlockFocus()

        // 色は捨てて形だけ使わせる。背景の明暗に合わせて OS が塗り直す。
        image.isTemplate = true
        return image
    }
}
