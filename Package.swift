// swift-tools-version:5.5
import PackageDescription

let package = Package(
	name: "hashids",
	products: [
		.library(name: "hashids", targets: ["hashids"]),
	],
	dependencies: [],
	targets: [
		.target(name: "hashids", dependencies: []),
		.testTarget(name: "HashidsTests", dependencies: ["hashids"])
	]
)
