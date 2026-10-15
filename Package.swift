// swift-tools-version: 6.0
import PackageDescription

// 自前の macOS ツールをまとめて置くモノレポ。
// アプリは Apps/<名前>/ に、共通コードは Libraries/ に置く。
// 新しいアプリは `mise run new-app <名前>` で追加する。
let package = Package(
    name: "tatin",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TatinKit", targets: ["TatinKit"]),
        .executable(name: "MenuBar", targets: ["MenuBar"]),
        // tatin:products — `mise run new-app` はこの行の前に追記する
    ],
    targets: [
        .target(
            name: "TatinKit",
            path: "Libraries/TatinKit/Sources",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "MenuBar",
            dependencies: ["TatinKit"],
            path: "Apps/MenuBar/Sources",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // tatin:targets — `mise run new-app` はこの行の前に追記する
        .testTarget(
            name: "TatinKitTests",
            dependencies: ["TatinKit"],
            path: "Tests/TatinKitTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
