// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "CorsoAthletics032",
    platforms: [.iOS("17.5")],
    products: [
        .iOSApplication(
            name: "Corso Athletics",
            targets: ["AppModule"],
            displayVersion: "0.3.2",
            bundleVersion: "14",
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
