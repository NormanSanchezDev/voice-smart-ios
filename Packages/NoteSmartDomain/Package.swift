// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "NoteSmartDomain",
    platforms: [.iOS(.v27)],
    products: [
        .library(name: "NoteSmartDomain", targets: ["NoteSmartDomain"])
    ],
    targets: [
        .target(
            name: "NoteSmartDomain",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "NoteSmartDomainTests",
            dependencies: ["NoteSmartDomain"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
