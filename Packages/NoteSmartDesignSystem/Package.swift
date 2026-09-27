// swift-tools-version: 6.4
import PackageDescription

// Atomic Design enforced by SPM target boundaries.
// Dependencies only ever flow upward: Tokens -> Atoms -> Molecules -> Organisms -> Templates.
// The "Pages" level lives in the app target, because pages carry real data.
let package = Package(
    name: "NoteSmartDesignSystem",
    platforms: [.iOS(.v27)],
    products: [
        .library(name: "DSTokens", targets: ["DSTokens"]),
        .library(name: "DSAtoms", targets: ["DSAtoms"]),
        .library(name: "DSMolecules", targets: ["DSMolecules"]),
        .library(name: "DSOrganisms", targets: ["DSOrganisms"]),
        .library(name: "DSTemplates", targets: ["DSTemplates"]),
    ],
    targets: [
        .target(name: "DSTokens", swiftSettings: [.swiftLanguageMode(.v6)]),
        .target(name: "DSAtoms", dependencies: ["DSTokens"], swiftSettings: [.swiftLanguageMode(.v6)]),
        .target(name: "DSMolecules", dependencies: ["DSAtoms"], swiftSettings: [.swiftLanguageMode(.v6)]),
        .target(name: "DSOrganisms", dependencies: ["DSMolecules"], swiftSettings: [.swiftLanguageMode(.v6)]),
        .target(name: "DSTemplates", dependencies: ["DSOrganisms"], swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
