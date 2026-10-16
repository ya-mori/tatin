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
        .library(name: "UsageKit", targets: ["UsageKit"]),
        .executable(name: "MenuBar", targets: ["MenuBar"]),
        .executable(name: "Usage", targets: ["Usage"]),
        // tatin:products — `mise run new-app` はこの行の前に追記する
    ],
    targets: [
        .target(
            name: "TatinKit",
            path: "Libraries/TatinKit/Sources",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "UsageKit",
            path: "Libraries/UsageKit/Sources",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "MenuBar",
            dependencies: ["TatinKit"],
            path: "Apps/MenuBar/Sources",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "Usage",
            dependencies: ["TatinKit", "UsageKit"],
            path: "Apps/Usage/Sources",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // tatin:targets — `mise run new-app` はこの行の前に追記する
        .testTarget(
            name: "TatinKitTests",
            dependencies: ["TatinKit"],
            path: "Tests/TatinKitTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "UsageKitTests",
            dependencies: ["UsageKit"],
            path: "Tests/UsageKitTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
