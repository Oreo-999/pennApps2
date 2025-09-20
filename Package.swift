// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "pennApps2",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "pennApps2",
            targets: ["pennApps2"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "pennApps2",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk")
            ]),
    ]
)


