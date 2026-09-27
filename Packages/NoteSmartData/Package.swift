// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "NoteSmartData",
    platforms: [.iOS(.v27)],
    products: [
        .library(name: "NoteSmartData", targets: ["NoteSmartData"])
    ],
    dependencies: [
        .package(path: "../NoteSmartDomain")
    ],
    targets: [
        .target(
            name: "NoteSmartData",
            dependencies: [
                .product(name: "NoteSmartDomain", package: "NoteSmartDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "NoteSmartDataTests",
            dependencies: [
                "NoteSmartData",
                .product(name: "NoteSmartDomain", package: "NoteSmartDomain")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
