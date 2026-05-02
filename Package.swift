// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DebtFlow",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "DebtFlow",
            path: "Sources/DebtFlow",

            linkerSettings: [
                .linkedLibrary("ws2_32", .when(platforms: [.windows]))
            ]
        ),
        .testTarget(
            name: "DebtFlowTests",
            dependencies: ["DebtFlow"],
            path: "Tests/DebtFlowTests"
        )
    ]
)