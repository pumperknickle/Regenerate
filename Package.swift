// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Regenerate",
    products: [
        .library(
            name: "Regenerate",
            targets: ["Regenerate"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pumperknickle/AwesomeTrie.git", from: "0.1.8"),
        .package(url: "https://github.com/pumperknickle/AwesomeDictionary.git", from: "0.1.0"),
        .package(url: "https://github.com/pumperknickle/CryptoStarterPack.git", from: "1.1.7"),
        .package(url: "https://github.com/pumperknickle/Bedrock.git", from: "0.2.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "2.2.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.4"),
    ],  
    targets: [
        .target(
            name: "Regenerate",
            dependencies: ["CryptoStarterPack", "Bedrock", "AwesomeTrie", "AwesomeDictionary"]
        ),
        .testTarget(
            name: "RegenerateTests",
            dependencies: ["Regenerate", "Quick", "Nimble", "CryptoStarterPack", "Bedrock", "AwesomeDictionary", "AwesomeTrie"]
        ),
    ]
)
