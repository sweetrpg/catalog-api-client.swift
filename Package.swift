// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CatalogAPIClient",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "CatalogAPIClient",
            targets: ["CatalogAPIClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "CatalogAPIClient",
            dependencies: [
                .product(name: "Tracing", package: "swift-distributed-tracing"),
            ]
        ),
        .testTarget(
            name: "CatalogAPIClientTests",
            dependencies: ["CatalogAPIClient"]
        ),
    ]
)
