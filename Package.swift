// swift-tools-version:5.1

import PackageDescription
let package = Package(
    name: "KKPreview",
	platforms: [
		.iOS(SupportedPlatform.IOSVersion.v9)
	],
    products: [
        .library(
            name: "KKPreview",
            targets: ["KKPreview"]),
    ],
    targets: [
		.target(name: "KKPreview"),
        .testTarget(
            name: "KKPreviewTests",
            dependencies: ["KKPreview"]
		),
    ],
	swiftLanguageVersions: [.v4_2, .v5]
)
