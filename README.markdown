# Mumble for iOS – Swift 5 Migration

A modern Swift 5 port of the Mumble voice chat client for iOS.

> [!NOTE]
> This fork has been **successfully migrated to Swift 5** and now compiles with Xcode 16.2.
> Currently in **alpha testing** phase – ready for testing on real iOS devices.

> [!CAUTION]
> - The app is **NOT YET** production ready to be used and still needs a lot of improvements and bug fixes. 
> 
> Feel free to send a [PR](https://github.com/mumble-voip/mumble-iphoneos/compare/master...0n1cOn3:mumble-iphoneos-swift:master) if you wanna help on this project! **:D**

---

## Project Status

| Metric | Status |
|--------|--------|
| Build Status | **Compiling** |
| Swift Version | Swift 5 |
| iOS Target | iOS 12.0+ |
| Xcode | 16.2+ |
| Stage | **Alpha Testing** |

### Migration Progress

- **Complete:** All Objective-C view controllers migrated to Swift
- **Complete:** Storyboards converted to programmatic UI
- **Complete:** Audio session management modernized
- **Complete:** Certificate handling updated
- **Complete:** MumbleKit integration working
- **Testing:** Real device functionality

---

> [!CAUTION]
> ### Known bugs
> - Checking a large number of servers can cause the app to crash.
> - Connecting to a server either causes the app to crash, or, if the connection succeeds, the microphone does not work at all.
> - The app does not allow you to check the sound level of your microphone in the settings.


---

## Features

- Voice chat with Mumble servers
- Push-to-Talk and Voice Activity Detection
- Server favorites and public server browser
- Certificate-based authentication
- Text messaging
- Channel navigation
- iPad and iPhone support

---

## Building

### Requirements

- macOS with **Xcode 16.2** or newer
- iOS SDK (included with Xcode)
- Git with submodule support

### Getting the Source

Clone with submodules:

```bash
git clone --recursive https://github.com/0n1cOn3/mumble-iphoneos-swift.git
cd mumble-iphoneos-swift
```

If you already cloned without `--recursive`:

```bash
git submodule update --init --recursive
```

### Building in Xcode

1. Open `Mumble.xcodeproj` in Xcode
2. Select the **Mumble** scheme
3. Choose your target device or simulator
4. Build with **Cmd+B** or run with **Cmd+R**

### Building via Command Line

```bash
xcodebuild -configuration Release \
  -target "Mumble" \
  CONFIGURATION_BUILD_DIR="${PWD}/__build__" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  -sdk iphoneos
```

The `.app` bundle will be in the `__build__` directory.

---

## Installing on Device (Sideloading)

Since this app is not on the App Store, you need to sideload it to your iOS device. The easiest method is using **Sideloadly**.

### Option 1: Sideloadly (Recommended)

[Sideloadly](https://sideloadly.io/) is a free tool for sideloading apps to iOS devices.

#### Download Sideloadly

Get Sideloadly from: **https://github.com/SideloadlyiOS/Sideloadly-Download**

Available for:
- Windows
- macOS (Intel & Apple Silicon)

#### Installation Steps

1. **Download and install Sideloadly** from the link above

2. **Build the IPA** (if you don't have one):
   ```bash
   # After building the .app, create an IPA
   mkdir -p Payload
   cp -r __build__/Mumble.app Payload/
   zip -r Mumble.ipa Payload
   rm -rf Payload
   ```

3. **Connect your iOS device** to your computer via USB

4. **Open Sideloadly** and:
   - Drag the `Mumble.ipa` file into Sideloadly
   - Enter your Apple ID (used for signing)
   - Click "Start" to begin installation

5. **Trust the developer certificate** on your device:
   - Go to **Settings > General > VPN & Device Management**
   - Tap on your Apple ID email
   - Tap **Trust** to allow apps from this developer

6. **Launch Mumble** from your home screen

#### Notes on Sideloadly

- Free Apple IDs require re-signing every 7 days
- Paid Apple Developer accounts ($99/year) allow 1-year certificates
- The app may need to be re-installed after the certificate expires

### Option 2: Xcode Direct Install

If you have Xcode and an Apple Developer account:

1. Open the project in Xcode
2. Connect your iOS device
3. Select your device as the build target
4. Go to **Signing & Capabilities** and select your team
5. Click **Run** (Cmd+R) to build and install directly

### Option 3: AltStore

[AltStore](https://altstore.io/) is an alternative sideloading solution that automatically refreshes apps.

### Option 4: Linux Sideloading

Linux users have several options for sideloading iOS apps:

#### SideStore (Recommended for Linux)

[SideStore](https://sidestore.io/) is a fork of AltStore that works without a computer after initial setup.

#### AltServer-Linux

Community port of AltServer for Linux:

```bash
# Install dependencies (Debian/Ubuntu)
sudo apt install libimobiledevice-utils usbmuxd

# Get AltServer-Linux from:
# https://github.com/NyaMisty/AltServer-Linux
```

#### libimobiledevice + Sideloader

For advanced users, use libimobiledevice tools directly:

```bash
# Install libimobiledevice (Fedora)
sudo dnf install libimobiledevice usbmuxd ifuse

# Install libimobiledevice (Debian/Ubuntu)
sudo apt install libimobiledevice6 usbmuxd ifuse

# Install libimobiledevice (Arch)
sudo pacman -S libimobiledevice usbmuxd ifuse
```

Then use [Sideloader](https://github.com/Dadoum/Sideloader) - a cross-platform sideloading tool written in D:

```bash
# Download from releases or build from source
# https://github.com/Dadoum/Sideloader/releases
```

#### Manual Installation with ideviceinstaller

```bash
# Pair your device first
idevicepair pair

# Install the IPA (unsigned - device must be jailbroken)
ideviceinstaller -i Mumble.ipa
```

> [!NOTE]
> For non-jailbroken devices on Linux, you'll need to sign the IPA first.
> Consider using a signing service or setting up a macOS VM for signing.

---

## Configuration

### Audio Settings

The app supports various audio configurations:

- **Transmission Mode:** Voice Activity Detection (VAD), Push-to-Talk, or Continuous
- **Audio Quality:** Low (16kbps), Balanced (40kbps), or High (72kbps)
- **Codec:** Opus (recommended) or CELT
- **Echo Cancellation:** Enabled by default
- **Sidetone:** Optional audio feedback

### Server Connection

Connect to Mumble servers using:
- Direct hostname/IP and port
- Server favorites
- Public server browser

Default port: `64738`

---

## Troubleshooting

### App Won't Install

- Ensure your device is trusted on your computer
- Check that your Apple ID is valid
- Try rebooting both your device and computer

### App Crashes on Launch

- Verify the IPA was built for the correct architecture (arm64)
- Check that all frameworks are properly embedded
- Review device logs in Xcode Organizer

### Audio Issues

- Grant microphone permission when prompted
- Check audio route settings (speaker vs. receiver)
- Ensure the server supports the selected codec

### Certificate Errors

- The app uses self-signed certificates for authentication
- Generate a new certificate in Settings if needed
- Export/import certificates for use on multiple devices

---

## Architecture

### Swift Migration

This fork migrated all view controllers from Objective-C to Swift 5:

- `MUApplicationDelegate` – App lifecycle and audio setup
- `MUConnectionController` – Server connection management
- `MUServerViewController` – Connected server UI
- `MUPreferencesViewController` – Settings screens
- `MUCertificate*` – Certificate management
- `MUMessages*` – Text messaging
- And 50+ more files

### Dependencies

- **MumbleKit** – Core Mumble protocol implementation (submodule)
- **FMDB** – SQLite database wrapper (submodule)
- **OpenSSL** – Cryptographic functions (submodule)

---

## Contributing

Contributions are welcome! Areas that need work:

- UI modernization (SwiftUI migration planned)
- iOS 17+ features (Interactive Widgets, Live Activities)
- Accessibility improvements
- Localization updates
- Bug fixes and testing

### Development Guidelines

- Follow Swift API Design Guidelines
- Use `@objcMembers` for classes called from Objective-C
- Maintain iOS 12 compatibility with `#available` checks
- Keep MumbleKit submodule unchanged

---

## Upstream Projects

This fork is based on the original Mumble iOS client:

- Original iOS repo: https://github.com/mumble-voip/mumble-iphoneos
- Desktop Mumble: https://github.com/mumble-voip/mumble
- Mumble website: https://mumble.info/

---

## License

This project inherits licensing from the upstream `mumble-iphoneos` project.
See the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- The Mumble development team for the original iOS client
- MumbleKit contributors for the protocol implementation
- All contributors to this Swift migration effort
