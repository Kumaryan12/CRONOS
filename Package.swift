// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Chronos",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "ChronosCore", targets: ["ChronosCore"]),
        .library(name: "ChronosCollector", targets: ["ChronosCollector"]),
        .executable(name: "ChronosApp", targets: ["ChronosApp"]),
        .executable(name: "chronos-dev", targets: ["ChronosDev"])
    ],
    targets: [
        .systemLibrary(
            name: "CSQLite",
            providers: [.brew(["sqlite3"]), .apt(["libsqlite3-dev"])]
        ),
        .target(
            name: "ChronosCore",
            dependencies: ["CSQLite"]
        ),
        .target(
            name: "ChronosCollector",
            dependencies: ["ChronosCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics")
            ]
        ),
        .executableTarget(
            name: "ChronosApp",
            dependencies: ["ChronosCore", "ChronosCollector"],
            linkerSettings: [
                .linkedFramework("ServiceManagement"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .executableTarget(
            name: "ChronosDev",
            dependencies: ["ChronosCore"]
        ),
        .testTarget(
            name: "CollectorTests",
            dependencies: ["ChronosCollector", "ChronosCore"]
        ),
        .testTarget(
            name: "AnalyticsTests",
            dependencies: ["ChronosCore"]
        ),
        .testTarget(
            name: "DatabaseTests",
            dependencies: ["ChronosCore"]
        )
    ],
    swiftLanguageModes: [.v5]
)
