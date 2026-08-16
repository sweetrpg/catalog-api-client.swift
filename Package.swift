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
    targets: [
        .target(
            name: "CatalogAPIClient"),
        .testTarget(
            name: "CatalogAPIClientTests",
            dependencies: ["CatalogAPIClient"]
        ),
    ]
)
