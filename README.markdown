# Mumble for iOS – Swift 5 WIP Fork

This repository is an experimental fork of the original **Mumble for iOS** client.  
The goal is to gradually migrate the codebase to **Swift 5** and modern iOS APIs.

> [!WARNING]  
> This fork is **work in progress**, **does not compile**, and is **not usable in production**.  
> Expect broken builds, incomplete features, and frequent changes.

---

## Project status

- Experimental Swift 5 migration of the legacy Objective-C iOS client
- Target platform: **iOS 12+**
- Current state: **broken / unfinished / non-compiling**
- No releases, no App Store build, no support guarantees

If you need a working Mumble client, use the official stable releases or the upstream projects instead.

---

## Upstream projects

This fork is based on the original, unmaintained iOS client:

- Original iOS repo: <https://github.com/mumble-voip/mumble-iphoneos>  
- Desktop Mumble (Windows, macOS, Linux, *BSD, etc.): <https://github.com/mumble-voip/mumble>
- Project website: <https://mumble.info/>

The upstream iOS app itself is currently unmaintained. This fork is an independent experiment and not an official continuation.

---

## Goals of this fork

The long-term goals are:

- Migrate the codebase to **Swift 5** (while keeping a controlled amount of Objective-C via bridging headers).
- Raise minimum iOS version and clean up deprecated APIs.
- Modernize the UI layer (storyboards, Auto Layout, trait collections).
- Replace legacy and deprecated frameworks where possible (e.g. old WebView, outdated audio APIs).
- Make the project buildable and maintainable on current Xcode versions.

At the moment, many of these goals are only partially attempted or not yet implemented.

---

## Work in progress

The migration is ongoing and very incomplete. Examples of planned or partially tackled areas:

- Converting controllers and views from Objective-C to Swift.
- Replacing legacy web views with `WKWebView`.
- Converting old test targets and frameworks to modern Xcode testing infrastructure.
- Updating audio handling to more modern APIs (e.g. `AVAudioSession`, `AVAudioEngine`).

Nothing in this list should be considered “done” or “stable” yet.

---

## Building (currently fails)

> [!IMPORTANT]  
> The current state of this fork **does not build successfully**, even with a recent Xcode toolchain.  
> The instructions below describe the *intended* build setup once the migration progresses.

### Requirements

- macOS with a recent Xcode version (e.g. Xcode 16 or newer)
- Latest iOS SDK provided by Xcode
- Git with submodule support

### Getting the source

Clone this fork with submodules:

```bash
git clone --recursive https://github.com/0n1cOn3/mumble-iphoneos.git
cd mumble-iphoneos
```

If you already cloned without `--recursive`, initialize submodules with:

```bash
git submodule update --init --recursive
```

### Opening in Xcode

1. Open `Mumble.xcodeproj` in Xcode.
2. Select the **Mumble** scheme.
3. Choose a suitable iOS Simulator or device target.

At this time, the project will **not** build successfully. The migration must progress further before a clean build can be expected.

---

## Xcode schemes and configurations

Once the project reaches a buildable state, you may want to:

- Keep only the **Mumble** scheme enabled to reduce clutter.
- Adjust build configurations for your workflow (for example, a faster configuration for device builds, or a dedicated configuration for archives).

Currently, scheme and configuration tuning is secondary to getting the project to compile at all.

---

## Contributing

This fork is experimental and highly unstable. If you want to help with the Swift 5 migration:

- Focus on **small, self-contained changes** (e.g. converting a single controller or utility).
- Avoid large refactors that touch everything at once.
- Keep Objective-C interop via bridging headers where needed instead of rewriting everything in one go.
- Clearly document any API replacements (especially for audio and networking).

Bug reports about “it doesn’t build” are expected at this stage; detailed, reproducible issues and concrete migration contributions are more useful than general breakage reports.

---

## License

The licensing model is inherited from the upstream `mumble-iphoneos` project.  
Refer to the license file(s) in this repository and the upstream project for details.
