// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Lightbox",
    products: [
        .library(
            name: "Lightbox",
            targets: ["Lightbox"]),
    ],
    dependencies: [
      .package(url: "https://github.com/nipapadak/Imaginary", .branch("branch-master-rb"))
    ],
    targets: [
        .target(
            name: "Lightbox",
            dependencies: ["Imaginary"],
            path: "Source"
            ),
        .target(name: "iOSDemo", dependencies: ["Lightbox"], path: "iOSDemo")
    ],
    swiftLanguageVersions: [.v5]
)
