// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "CorsoAthletics040",
    platforms: [.iOS("17.5")],
    products: [
        .iOSApplication(
            name: "Corso Athletics",
            targets: ["AppModule"],
            displayVersion: "0.4.0",
            bundleVersion: "15",
            appIcon: .placeholder(icon: .star),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [.pad],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            additionalInfoPlistContent: [
                "NSCameraUsageDescription": "Corso uses the camera to record school race footage for on-device frame-by-frame timing.",
                "NSMicrophoneUsageDescription": "Corso may include ambient audio while recording race footage."
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
