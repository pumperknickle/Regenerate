// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Regenerate",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Regenerate",
            targets: ["Regenerate"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pumperknickle/TMap.git", from: "1.0.3"),
        .package(url: "https://github.com/pumperknickle/CryptoStarterPack.git", from: "1.0.9"),
        .package(url: "https://github.com/pumperknickle/Bedrock.git", from: "0.0.3"),
        .package(url: "https://github.com/Quick/Quick.git", from: "2.1.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.2"),
    ],
    targets: [
        .target(
            name: "Regenerate",
            dependencies: ["CryptoStarterPack", "Bedrock", "TMap"]),
        .testTarget(
            name: "RegenerateTests",
            dependencies: ["Regenerate", "Quick", "Nimble", "CryptoStarterPack", "Bedrock", "TMap"]),
    ]
)
