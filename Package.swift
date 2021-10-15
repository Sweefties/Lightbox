// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Lightbox",
    defaultLocalization: "en",
        platforms: [
            .iOS(.v13)
        ],
    products: [
        .library(name: "Lightbox", targets: ["Lightbox"])
    ],
    dependencies: [
      .package(url: "https://github.com/nipapadak/Imaginary", .branch("branch-master-rb"))
    ],
    targets: [
        .target(name: "Lightbox",
                dependencies: ["Imaginary"],
                path: "Source",
                resources: [.process("Files/")]),
        .target(name: "iOSDemo",
                dependencies: ["Lightbox"],
                path: "iOSDemo")
    ],
    swiftLanguageVersions: [.v5]
)

/*
 manifest property 'defaultLocalization' not set; it is required in the presence of localized resources
 */
