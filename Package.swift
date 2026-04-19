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
            ],
            path: "App",
            exclude: ["Info.plist", "Assets.xcassets"]
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
            dependencies: ["PreferencesStore", "HotkeyManager", "WindowEngine"],
            path: "Sources/PreferencesUI"
        ),
        .target(name: "PermissionsCoordinator", path: "Sources/PermissionsCoordinator"),
        .target(
            name: "UndoStack",
            dependencies: ["WindowEngine"],
            path: "Sources/UndoStack"
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
    ]
)
