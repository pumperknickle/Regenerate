// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Regenerate",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v5),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Regenerate",
            targets: ["Regenerate"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pumperknickle/AwesomeTrie.git", from: "0.1.9"),
        .package(url: "https://github.com/pumperknickle/AwesomeDictionary.git", from: "0.1.1"),
        .package(url: "https://github.com/pumperknickle/CryptoStarterPack.git", from: "1.1.9"),
        .package(url: "https://github.com/pumperknickle/Bedrock.git", from: "0.2.2"),
        .package(url: "https://github.com/Quick/Quick.git", from: "3.1.2"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "9.0.0"),
    ],  
    targets: [
        .target(
            name: "Regenerate",
            dependencies: ["CryptoStarterPack", "Bedrock", "AwesomeTrie", "AwesomeDictionary"]
        ),
        .testTarget(
            name: "RegenerateTests",
            dependencies: ["Regenerate", "Quick", "Nimble", "CryptoStarterPack", "Bedrock", "AwesomeTrie", "AwesomeDictionary"]
        ),
    ]
)
