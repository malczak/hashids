// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Hashids_Swift",
    products: [
        .library(
            name: "Hashids_Swift",
            targets: ["Hashids_Swift"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Hashids_Swift",
            dependencies: [],
            path: ""),
        .testTarget(
            name: "Hashids_SwiftTests",
            dependencies: ["Hashids_Swift"],
            path: "Tests"),
    ]
)
