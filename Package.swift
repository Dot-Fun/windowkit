// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WindowKit",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "WindowKit", targets: ["WindowKit"]),
        .library(name: "WindowEngine", targets: ["WindowEngine"]),
        .library(name: "HotkeyManager", targets: ["HotkeyManager"]),
        .library(name: "PreferencesStore", targets: ["PreferencesStore"]),
        .library(name: "PreferencesUI", targets: ["PreferencesUI"]),
        .library(name: "PermissionsCoordinator", targets: ["PermissionsCoordinator"]),
        .library(name: "UndoStack", targets: ["UndoStack"]),
        .library(name: "UpdateChecker", targets: ["UpdateChecker"]),
        .library(name: "LayoutProfiles", targets: ["LayoutProfiles"]),
    ],
    targets: [
        .executableTarget(
            name: "WindowKit",
            dependencies: [
                "WindowEngine",
                "HotkeyManager",
                "PreferencesStore",
                "PreferencesUI",
                "PermissionsCoordinator",
                "UndoStack",
                "UpdateChecker",
                "LayoutProfiles",
            ],
            path: "App",
            exclude: ["Info.plist", "Assets.xcassets", "AppIcon.icns"]
        ),
        .target(name: "WindowEngine", path: "Sources/WindowEngine"),
        .target(
            name: "HotkeyManager",
            dependencies: ["WindowEngine", "PreferencesStore"],
            path: "Sources/HotkeyManager"
        ),
        .target(
            name: "PreferencesStore",
            dependencies: ["WindowEngine"],
            path: "Sources/PreferencesStore"
        ),
        .target(
            name: "PreferencesUI",
            dependencies: ["PreferencesStore", "HotkeyManager", "WindowEngine", "PermissionsCoordinator", "UpdateChecker", "LayoutProfiles"],
            path: "Sources/PreferencesUI",
            resources: [.process("Resources")]
        ),
        .target(name: "PermissionsCoordinator", path: "Sources/PermissionsCoordinator"),
        .target(
            name: "UndoStack",
            dependencies: ["WindowEngine"],
            path: "Sources/UndoStack"
        ),
        .target(name: "UpdateChecker", path: "Sources/UpdateChecker"),
        .target(
            name: "LayoutProfiles",
            dependencies: ["WindowEngine"],
            path: "Sources/LayoutProfiles"
        ),
        .testTarget(
            name: "WindowEngineTests",
            dependencies: ["WindowEngine"],
            path: "Tests/WindowEngineTests"
        ),
        .testTarget(
            name: "PreferencesStoreTests",
            dependencies: ["PreferencesStore", "WindowEngine"],
            path: "Tests/PreferencesStoreTests"
        ),
        .testTarget(
            name: "HotkeyManagerTests",
            dependencies: ["HotkeyManager", "WindowEngine"],
            path: "Tests/HotkeyManagerTests"
        ),
        .testTarget(
            name: "UpdateCheckerTests",
            dependencies: ["UpdateChecker"],
            path: "Tests/UpdateCheckerTests"
        ),
        .testTarget(
            name: "PermissionsCoordinatorTests",
            dependencies: ["PermissionsCoordinator"],
            path: "Tests/PermissionsCoordinatorTests"
        ),
        .testTarget(
            name: "LayoutProfilesTests",
            dependencies: ["LayoutProfiles"],
            path: "Tests/LayoutProfilesTests"
        ),
    ]
)
