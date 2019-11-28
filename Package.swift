// swift-tools-version:5.1

import PackageDescription
let package = Package(
    name: "CompatibleContextMenuInteraction",
	platforms: [
		.iOS(SupportedPlatform.IOSVersion.v9)
	],
    products: [
        .library(
            name: "CompatibleContextMenuInteraction",
            targets: ["CompatibleContextMenuInteraction"]),
    ],
    targets: [
		.target(name: "CompatibleContextMenuInteraction"),
        .testTarget(
            name: "CompatibleContextMenuInteractionTests",
            dependencies: ["CompatibleContextMenuInteraction"]
		),
    ],
	swiftLanguageVersions: [.v4_2, .v5]
)
