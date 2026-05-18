// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AskNow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AskNow", targets: ["AskNow"])
    ],
    targets: [
        .executableTarget(
            name: "AskNow",
            path: "Sources/AskNow"
        )
    ]
)
