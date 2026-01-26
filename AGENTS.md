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
- **Process**: Update this `AGENTS.md` after each change to keep the migration status current.

Completed tasks
===============
- Migrated the web view code to **WKWebView**.
- Replaced **SenTestingKit** with **XCTest**.
- Rewrote certificate controllers in Swift and deleted the old Objective‑C implementations.
- Converted most user interfaces from xib files to storyboards, including the former `MainWindow.xib`.
- Converted the preferences UI to Swift (`MUPreferencesViewController`).
- Added a centralized **AVAudioEngine** capture pipeline with push-to-talk and VAD metering support.
- Installed the SwiftUI expert Codex skill (`swiftui-expert`) under `.codex/skills` for this workspace.

Open tasks
==========
- Migrate the remaining Objective‑C controllers (for example `MUConnectionController` and the server list flows) to Swift 5 with ARC semantics.
- Port the legacy Objective‑C preference and messaging screens (audio detail panels, server buttons, message bubbles) to Swift 5 while keeping storyboard/Auto Layout parity.
- Trim the bridging header and delete unused Objective‑C shims once the last controllers are rewritten to Swift 5.

Prioritized migration map
=========================
Priority 0 (Prerequisites & Guardrails)
1. **Inventory & dependency graph**
   - Confirm remaining Objective-C files under `Source/Classes`.
   - Identify which Objective-C classes are referenced by Swift via the bridging header.
   - Capture storyboard/xib references for legacy controllers before conversion.
2. **Adopt Swift-friendly project settings**
   - Ensure ARC is enabled for any remaining Objective-C targets.
   - Keep deployment target at iOS 12; wrap newer APIs in availability checks.

Priority 1 (Core app flows: connection + server lists)
1. **Connection & root navigation**
   - `MUConnectionController`
   - `MUServerRootViewController`
   - `MUServerViewController`
2. **Server list flows**
   - `MUFavouriteServerListController`
   - `MULanServerListController`
   - `MUCountryServerListController`
   - `MUPublicServerListController`
   - Supporting data models: `MUPublicServerList`, `MUFavouriteServer`

Priority 2 (Messaging surface)
1. **Message UI**
   - `MUMessagesViewController`
   - `MUMessageRecipientViewController`
   - `MUMessageAttachmentViewController`
   - `MUMessageBubbleTableViewCell`
2. **Messaging data**
   - `MUTextMessage`
   - `MUTextMessageProcessor`
   - `MUMessagesDatabase`

Priority 3 (Preferences: audio panels & diagnostics)
1. **Audio preference panels**
   - `MUAdvancedAudioPreferencesViewController`
   - `MUAudioQualityPreferencesViewController`
   - `MUAudioSidetonePreferencesViewController`
   - `MUVoiceActivitySetupViewController`
2. **Diagnostics**
   - `MUAudioMixerDebugViewController`

Priority 4 (Certificates & trust UI parity)
1. **Certificate preferences & trust**
   - `MUCertificatePreferencesViewController`
   - `MUServerCertificateTrustViewController`
   - Supporting view cells: `MUCertificateCell`, `MUCertificateCreationProgressView`

Priority 5 (UI polish + supporting views)
1. **UI components**
   - `MUAudioBarView`
   - `MUAudioBarViewCell`
   - `MUTableViewHeaderLabel`
   - `MUUserStateAcessoryView`
   - `MUServerTableViewCell`
   - `MUServerCell`
   - `MUServerButton`
   - `MUPopoverBackgroundView`
   - `MUBackgroundView`
2. **Transitions & misc**
   - `MUHorizontalFlipTransitionDelegate`
   - `MUImageViewController`
   - `MUWelcomeScreenPhone`
   - `MUWelcomeScreenPad`
   - `MULegalViewController`
   - `MUAccessTokenViewController`

Priority 6 (Data/utilities & app entry)
1. **Utilities & data**
   - `MUDatabase`
   - `MUDataURL`
   - `MUImage`
   - `MUColor`
   - `MUAudioCaptureManager`
2. **App delegate & notifications**
   - `MUApplicationDelegate`
   - `MUNotificationController`
   - `MURemoteControlServer`
3. **Entry point**
   - `main.m` (optional: move to Swift `@main` only after all controllers are in Swift)

Cross-cutting guidance
----------------------
- **Replace deprecated APIs**: Migrate `UIAlertView` and other legacy APIs to `UIAlertController` or modern UIKit equivalents.
- **Storyboard + Auto Layout parity**: Keep layout fidelity with existing storyboards and add constraints where needed.
- **ARC & memory safety**: Remove manual retain/release patterns during Swift conversion.
- **Submodules**: Do **not** edit `MumbleKit` or `Dependencies/fmdb`; keep integrations stable via bridging headers until Objective-C is fully removed.
- **Bridging header cleanup**: Trim after each controller migration to minimize Objective-C surface area.
