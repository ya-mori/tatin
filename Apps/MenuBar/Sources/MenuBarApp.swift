import SwiftUI

@main
struct MenuBarApp: App {
    var body: some Scene {
        MenuBarExtra("tatin", systemImage: "square.stack.3d.up.fill") {
            MenuContent()
        }
        // ポップオーバーではなく、通常のメニューとして開く。
        .menuBarExtraStyle(.menu)
    }
}
