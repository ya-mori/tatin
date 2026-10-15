import Testing

@testable import TatinKit

@Suite("AppMetadata")
struct AppMetadataTests {
    @Test("表示用のバージョンはビルド番号を括弧で添える")
    func displayVersionCombinesVersionAndBuild() {
        let metadata = AppMetadata(
            name: "MenuBar",
            bundleIdentifier: "dev.tatin.MenuBar",
            version: "0.1.0",
            build: "1"
        )

        #expect(metadata.displayVersion == "0.1.0 (1)")
    }

    @Test(".app の外で動かしても値が空にならない")
    func currentFallsBackWhenRunOutsideAppBundle() {
        // テストは .app バンドル外で動くため Info.plist が無い。
        // それでも代替値で埋まることを確かめる。
        let metadata = AppMetadata.current

        #expect(!metadata.name.isEmpty)
        #expect(!metadata.bundleIdentifier.isEmpty)
        #expect(!metadata.version.isEmpty)
        #expect(!metadata.build.isEmpty)
    }
}
