// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "CorsoAthletics",
    platforms: [.iOS("17.5")],
    products: [
        .iOSApplication(
            name: "Corso Athletics",
            targets: ["AppModule"],
            displayVersion: "0.2.0",
            bundleVersion: "10",
            appIcon: .placeholder(icon: .star),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [.pad],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources"
        )
    ]
)
