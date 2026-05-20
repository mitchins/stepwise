// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Stepwise",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "Stepwise",
            targets: ["StepwiseCore", "StepwiseUI"]
        ),
        .library(
            name: "StepwiseCore",
            targets: ["StepwiseCore"]
        ),
        .library(
            name: "StepwiseUI",
            targets: ["StepwiseUI"]
        ),
        .library(
            name: "StepwiseFoundationModel",
            targets: ["StepwiseFoundationModel"]
        )
    ],
    targets: [
        .target(
            name: "StepwiseCore",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "StepwiseUI",
            dependencies: ["StepwiseCore"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "StepwiseFoundationModel",
            dependencies: ["StepwiseCore"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "StepwiseCoreTests",
            dependencies: ["StepwiseCore"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "StepwiseUITests",
            dependencies: ["StepwiseUI", "StepwiseCore"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "StepwiseFoundationModelTests",
            dependencies: ["StepwiseFoundationModel", "StepwiseCore"],
            resources: [.process("Resources")],
            swiftSettings: swiftSettings
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault")
]
