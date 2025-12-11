# Modernization guidelines for migrating to Swift

- **Swift migration**: Convert Objective-C files under `Source/Classes/` to Swift 5. Keep the existing folder structure. Use bridging headers if some MumbleKit APIs remain in Objective-C.
- **ARC adoption**: The project still uses manual retain/release calls (for example in `MUCertificateViewController.m`). Remove `release`/`autorelease` patterns and adopt ARC when translating to Swift.
- **Deployment targets**: The base deployment target is iOS 12. Guard new APIs with availability checks to keep compatibility with older iOS versions.
- **Replace deprecated APIs**: Update `UIAlertView` and other legacy UI code to modern UIKit or SwiftUI equivalents. Use `XCTest` instead of `SenTestingKit`.
- **Storyboard & Auto Layout**: Migrate nibs to storyboards and add Auto Layout constraints as needed.
- **Audio**: Preserve existing audio features while updating to use `AVAudioSession` / `AVAudioEngine` as appropriate. Maintain interoperability with MumbleKit.
- **Submodules**: The repo contains git submodules (`MumbleKit`, `Dependencies/fmdb`). Do not modify submodule contents directly. Ensure they are updated and integrated with the Swift code.
- **Testing**: Running `xcodebuild` or the iOS simulator is not possible in this Linux environment. Mark any instructions requiring Xcode as non-executable here.
- **Style**: Follow Swift naming conventions, use optionals and enums where sensible, and drop C-style macros.

Completed tasks
===============
- Migrated the web view code to **WKWebView**.
- Replaced **SenTestingKit** with **XCTest**.
- Rewrote certificate controllers in Swift and deleted the old Objective‑C implementations.
- Converted most user interfaces from xib files to storyboards, including the former `MainWindow.xib`.
- Converted the preferences UI to Swift (`MUPreferencesViewController`).
- Added a centralized **AVAudioEngine** capture pipeline with push-to-talk and VAD metering support.

Open tasks
==========
- Migrate the remaining Objective‑C controllers (for example `MUConnectionController` and the server list flows) to Swift 5 with ARC semantics.
- Port the legacy Objective‑C preference and messaging screens (audio detail panels, server buttons, message bubbles) to Swift 5 while keeping storyboard/Auto Layout parity.
- Trim the bridging header and delete unused Objective‑C shims once the last controllers are rewritten to Swift 5.