// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import UIKit
import AVFoundation

/// Main application delegate for Mumble iOS.
@main
@objc(MUApplicationDelegate)
@objcMembers
class MUApplicationDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Properties

    var window: UIWindow?
    private var navigationController: UINavigationController?
    private var publistFetcher: MUPublicServerListFetcher?
    private var audioWasRunningBeforeInterruption: Bool = false

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerForAppLifecycleNotifications()

        // Reset application badge
        UIApplication.shared.applicationIconBadgeNumber = 0

        // Initialize the notification controller
        _ = MUNotificationController.shared

        // Try to fetch an updated public server list
        publistFetcher = MUPublicServerListFetcher()
        publistFetcher?.attemptUpdate()

        // Set MumbleKit release string
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        MKVersion.shared()?.setOverrideRelease("Mumble for iOS \(version)")

        // Enable Opus unconditionally
        MKVersion.shared()?.setOpusEnabled(true)

        // Register default settings
        UserDefaults.standard.register(defaults: [
            // Audio
            "AudioOutputVolume": 1.0,
            "AudioVADAbove": 0.6,
            "AudioVADBelow": 0.3,
            "AudioVADKind": "amplitude",
            "AudioTransmitMethod": "vad",
            "AudioPreprocessor": true,
            "AudioEchoCancel": true,
            "AudioMicBoost": 1.0,
            "AudioQualityKind": "balanced",
            "AudioSidetone": false,
            "AudioSidetoneVolume": 0.2,
            "AudioSpeakerPhoneMode": true,
            "AudioOpusCodecForceCELTMode": true,
            // Network
            "NetworkForceTCP": false,
            "DefaultUserName": "MumbleUser"
        ])

        // Disable mixer debugging for all builds
        UserDefaults.standard.set(false, forKey: "AudioMixerDebug")

        reloadPreferences()
        MUDatabase.initializeDatabase()

        registerForAudioSessionNotifications()

        #if ENABLE_REMOTE_CONTROL
        if UserDefaults.standard.bool(forKey: "RemoteControlServerEnabled") {
            MURemoteControlServer.shared.start()
        }
        #endif

        // Use dark keyboard throughout the app
        UITextField.appearance().keyboardAppearance = .dark

        window = UIWindow(frame: UIScreen.main.bounds)

        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = .black
        UINavigationBar.appearance().backgroundColor = .black
        UINavigationBar.appearance().barStyle = .black

        // Add background view for prettier transitions
        let bgView = MUBackgroundView.backgroundView()
        window?.addSubview(bgView)

        // Add default navigation controller
        navigationController = UINavigationController()
        navigationController?.isToolbarHidden = true

        let welcomeScreen: UIViewController
        if UIDevice.current.userInterfaceIdiom == .pad {
            welcomeScreen = MUWelcomeScreenPad()
        } else {
            welcomeScreen = MUWelcomeScreenPhone()
        }
        navigationController?.pushViewController(welcomeScreen, animated: true)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        // Handle mumble:// URL on launch
        if let url = launchOptions?[.url] as? URL, url.scheme == "mumble" {
            let connController = MUConnectionController.shared()
            let hostname = url.host ?? ""
            let port = url.port ?? 64738
            let username = url.user
            let password = url.password
            connController.connetToHostname(hostname, port: port, withUsername: username, andPassword: password, withParentViewController: welcomeScreen)
            return true
        }

        return false
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard url.scheme == "mumble" else { return false }

        let connController = MUConnectionController.shared()
        if connController.isConnected {
            return false
        }

        let hostname = url.host ?? ""
        let port = url.port ?? 64738
        let username = url.user
        let password = url.password

        if let visibleVC = navigationController?.visibleViewController {
            connController.connetToHostname(hostname, port: port, withUsername: username, andPassword: password, withParentViewController: visibleVC)
        }

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        MUDatabase.teardown()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        let audio = MKAudio.shared()
        let connController = MUConnectionController.shared()

        if !connController.isConnected {
            NSLog("MumbleApplicationDelegate: Not connected to a server. Stopping MKAudio.")
            audio?.stop()
            MUAudioCaptureManager.shared.stop()

            NSLog("MumbleApplicationDelegate: Not connected to a server. Deactivating audio session.")
            deactivateAudioSession()

            #if ENABLE_REMOTE_CONTROL
            MURemoteControlServer.shared.stop()
            #endif
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        let audio = MKAudio.shared()
        let connController = MUConnectionController.shared()

        if audio?.isRunning() == false {
            NSLog("MumbleApplicationDelegate: MKAudio not running. Starting it.")
            audio?.start()
            MUAudioCaptureManager.shared.start()
        }

        if !connController.isConnected && !AVAudioSession.sharedInstance().isOtherAudioPlaying {
            NSLog("MumbleApplicationDelegate: Reactivating audio session after foregrounding.")
            activateAudioSession()
            MUAudioSessionManager.shared.refreshPlaybackChain()

            #if ENABLE_REMOTE_CONTROL
            MURemoteControlServer.shared.stop()
            MURemoteControlServer.shared.start()
            #endif
        }
    }

    // MARK: - Audio Setup

    private func setupAudio() {
        let defaults = UserDefaults.standard

        // Configure AVAudioSession
        configureAudioSession(with: defaults)
        MUAudioSessionManager.shared.configureSession()
        MUAudioSessionManager.shared.applySavedPreferences()

        var settings = MKAudioSettings()

        // Transmit type
        let transmitMethod = defaults.string(forKey: "AudioTransmitMethod")
        switch transmitMethod {
        case "vad":
            settings.transmitType = MKTransmitTypeVAD
        case "continuous":
            settings.transmitType = MKTransmitTypeContinuous
        case "ptt":
            settings.transmitType = MKTransmitTypeToggle
        default:
            settings.transmitType = MKTransmitTypeVAD
        }

        // VAD kind
        let vadKind = defaults.string(forKey: "AudioVADKind")
        switch vadKind {
        case "snr":
            settings.vadKind = MKVADKindSignalToNoise
        default:
            settings.vadKind = MKVADKindAmplitude
        }

        settings.vadMin = defaults.float(forKey: "AudioVADBelow")
        settings.vadMax = defaults.float(forKey: "AudioVADAbove")

        // Quality settings
        let quality = defaults.string(forKey: "AudioQualityKind")
        switch quality {
        case "low":
            settings.codec = MKCodecFormatOpus
            settings.quality = 16000
            settings.audioPerPacket = 6
        case "balanced":
            settings.codec = MKCodecFormatOpus
            settings.quality = 40000
            settings.audioPerPacket = 2
        case "high", "opus":
            settings.codec = MKCodecFormatOpus
            settings.quality = 72000
            settings.audioPerPacket = 1
        default:
            settings.codec = MKCodecFormatCELT
            let codec = defaults.string(forKey: "AudioCodec")
            switch codec {
            case "opus":
                settings.codec = MKCodecFormatOpus
            case "celt":
                settings.codec = MKCodecFormatCELT
            case "speex":
                settings.codec = MKCodecFormatSpeex
            default:
                break
            }
            settings.quality = Int32(defaults.integer(forKey: "AudioQualityBitrate"))
            settings.audioPerPacket = Int32(defaults.integer(forKey: "AudioQualityFrames"))
        }

        settings.noiseSuppression = -42
        settings.amplification = 20.0
        settings.jitterBufferSize = 0
        settings.volume = defaults.float(forKey: "AudioOutputVolume")
        settings.outputDelay = 0
        settings.micBoost = defaults.float(forKey: "AudioMicBoost")
        settings.enablePreprocessor = defaults.bool(forKey: "AudioPreprocessor")
        settings.enableEchoCancellation = settings.enablePreprocessor && defaults.bool(forKey: "AudioEchoCancel")
        settings.enableSideTone = defaults.bool(forKey: "AudioSidetone")
        settings.sidetoneVolume = defaults.float(forKey: "AudioSidetoneVolume")
        settings.preferReceiverOverSpeaker = !defaults.bool(forKey: "AudioSpeakerPhoneMode")
        settings.opusForceCELTMode = defaults.bool(forKey: "AudioOpusCodecForceCELTMode")
        settings.audioMixerDebug = defaults.bool(forKey: "AudioMixerDebug")

        MUAudioCaptureManager.shared.configureFromDefaults()

        let audio = MKAudio.shared()
        MUAudioSessionManager.shared.bind(toMumbleKitAudio: audio, defaults: defaults)
        audio?.update(&settings)
        MUAudioSessionManager.shared.refreshPlaybackChain()

        // Only activate if not already active
        if !AVAudioSession.sharedInstance().isActive {
            activateAudioSession()
        }
    }

    @objc func reloadPreferences() {
        setupAudio()
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession(with defaults: UserDefaults) {
        let session = AVAudioSession.sharedInstance()

        var options: AVAudioSession.CategoryOptions = [.allowBluetooth, .mixWithOthers]
        if defaults.bool(forKey: "AudioSpeakerPhoneMode") {
            options.insert(.defaultToSpeaker)
        }
        if #available(iOS 10.0, *) {
            options.insert(.allowBluetoothA2DP)
        }

        let mode: AVAudioSession.Mode
        if !defaults.bool(forKey: "AudioPreprocessor") {
            mode = .measurement
        } else {
            let transmitMethod = defaults.string(forKey: "AudioTransmitMethod")
            switch transmitMethod {
            case "continuous":
                if #available(iOS 9.0, *) {
                    mode = .spokenAudio
                } else {
                    mode = .default
                }
            case "ptt":
                mode = .default
            default:
                mode = .voiceChat
            }
        }

        do {
            if #available(iOS 10.0, *) {
                try session.setCategory(.playAndRecord, mode: mode, options: options)
            } else {
                try session.setCategory(.playAndRecord, options: options)
                try session.setMode(mode)
            }
        } catch {
            NSLog("MUApplicationDelegate: Failed to set audio session category: %@", error.localizedDescription)
        }

        // Sample rate
        var preferredSampleRate: Double = 48000.0
        if defaults.string(forKey: "AudioQualityKind") == "low" {
            preferredSampleRate = 16000.0
        }

        do {
            try session.setPreferredSampleRate(preferredSampleRate)
        } catch {
            NSLog("MUApplicationDelegate: Unable to set preferred sample rate: %@", error.localizedDescription)
        }

        // IO buffer duration
        var framesPerPacket = defaults.integer(forKey: "AudioQualityFrames")
        if framesPerPacket <= 0 {
            switch defaults.string(forKey: "AudioQualityKind") {
            case "low":
                framesPerPacket = 6
            case "balanced":
                framesPerPacket = 2
            case "high", "opus":
                framesPerPacket = 1
            default:
                framesPerPacket = 2
            }
        }

        let preferredIOBuffer = max(0.01, TimeInterval(framesPerPacket) * 0.01)
        do {
            try session.setPreferredIOBufferDuration(preferredIOBuffer)
        } catch {
            NSLog("MUApplicationDelegate: Unable to set preferred IO buffer duration: %@", error.localizedDescription)
        }

        // Input gain
        let micBoost = defaults.float(forKey: "AudioMicBoost")
        let requestedGain = max(0.0, min(1.0, micBoost))
        if session.isInputGainSettable {
            do {
                try session.setInputGain(requestedGain)
            } catch {
                NSLog("MUApplicationDelegate: Unable to set input gain: %@", error.localizedDescription)
            }
        }
    }

    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            NSLog("MUApplicationDelegate: Failed to activate audio session: %@", error.localizedDescription)
        }
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            NSLog("MUApplicationDelegate: Failed to deactivate audio session: %@", error.localizedDescription)
        }
    }

    // MARK: - Notifications

    private func registerForAppLifecycleNotifications() {
        let center = NotificationCenter.default

        center.addObserver(self, selector: #selector(handleApplicationActivation(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        center.addObserver(self, selector: #selector(handleApplicationActivation(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)

        if #available(iOS 13.0, *) {
            center.addObserver(self, selector: #selector(handleApplicationActivation(_:)), name: UIScene.willEnterForegroundNotification, object: nil)
            center.addObserver(self, selector: #selector(handleApplicationActivation(_:)), name: UIScene.didActivateNotification, object: nil)
        }
    }

    private func registerForAudioSessionNotifications() {
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()

        center.addObserver(self, selector: #selector(handleAudioInterruption(_:)), name: AVAudioSession.interruptionNotification, object: session)
        center.addObserver(self, selector: #selector(handleAudioRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: session)
    }

    @objc private func handleApplicationActivation(_ notification: Notification) {
        activateAudioSessionIfNeeded()

        if let audio = MKAudio.shared(), !audio.isRunning {
            audio.start()
        }
    }

    private func activateAudioSessionIfNeeded() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            NSLog("MUApplicationDelegate: Failed to activate AVAudioSession: %@", error.localizedDescription)
        }
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            audioWasRunningBeforeInterruption = MKAudio.shared()?.isRunning ?? false
            if audioWasRunningBeforeInterruption {
                MKAudio.shared()?.stop()
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    activateAudioSessionIfNeeded()
                    if audioWasRunningBeforeInterruption {
                        MKAudio.shared()?.start()
                    }
                }
            }
            audioWasRunningBeforeInterruption = false
        @unknown default:
            break
        }
    }

    @objc private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable, .categoryChange, .override, .wakeFromSleep:
            MUAudioSessionManager.shared.handleRouteChange(withReason: reason, defaults: UserDefaults.standard)
        default:
            break
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
