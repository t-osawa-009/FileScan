// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FileScan",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "FileScan", targets: ["FileScan"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/Commander.git", from: "0.9.2"),
        .package(url: "https://github.com/JohnSundell/Files.git", from: "4.2.0")
    ],
    targets: [
        .executableTarget(
            name: "FileScan",
            dependencies: ["Files", "Commander"]),
        .testTarget(
            name: "FileScanTests",
            dependencies: ["FileScan", "Files", "Commander"]),
    ]
)
