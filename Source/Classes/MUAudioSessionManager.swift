import Foundation
import AVFoundation

/// Defines the mode used for transmitting audio in a Mumble session.
///
/// This enum specifies how audio input is captured and transmitted:
/// - Voice Activity Detection (VAD) automatically detects when the user is speaking
/// - Push-to-Talk requires manual activation
/// - Continuous transmission sends audio at all times
@objc public enum MUAudioTransmitMode: Int {
    /// Voice Activity Detection mode - audio is transmitted automatically when speech is detected
    case voiceActivity
    /// Push-to-Talk mode - audio is transmitted only when manually activated by the user
    case pushToTalk
    /// Continuous transmission mode - audio is transmitted continuously without activation
    case continuous
}

/// Defines preset quality levels for audio codec configuration.
///
/// Each preset configures sample rate, bit rate, and I/O buffer duration
/// to balance audio quality against bandwidth and processing requirements.
@objc public enum MUAudioCodecQualityPreset: Int {
    /// Low quality preset - 16 kHz sample rate, 16 kbps bit rate, suitable for low bandwidth
    case low
    /// Balanced quality preset - 48 kHz sample rate, 40 kbps bit rate, good balance of quality and bandwidth
    case balanced
    /// High quality preset - 48 kHz sample rate, 72 kbps bit rate, best audio quality
    case high
}

/// Manages the audio session configuration for Mumble voice communication.
///
/// `MUAudioSessionManager` is a singleton that provides centralized management
/// of AVAudioSession settings and user audio preferences. It handles:
/// - Audio session category and mode configuration for VoIP
/// - Transmit mode selection (VAD, Push-to-Talk, Continuous)
/// - Voice Activity Detection (VAD) threshold configuration
/// - Audio codec quality presets
/// - Persistence of audio preferences to UserDefaults
///
/// Use the shared instance to configure and manage audio settings throughout
/// the application lifecycle.
@objcMembers
final class MUAudioSessionManager: NSObject {
    /// The shared singleton instance of the audio session manager
    static let shared = MUAudioSessionManager()

    private let session = AVAudioSession.sharedInstance()
    
    /// The current audio transmission mode
    private(set) var transmitMode: MUAudioTransmitMode = .voiceActivity
    
    /// The current codec quality preset
    private(set) var codecQuality: MUAudioCodecQualityPreset = .balanced
    
    /// The lower threshold for Voice Activity Detection (0.0 to 1.0)
    private(set) var vadLowerThreshold: Float = 0.3
    
    /// The upper threshold for Voice Activity Detection (0.0 to 1.0)
    private(set) var vadUpperThreshold: Float = 0.6
    
    /// Audio recorder settings dictionary for AVAudioRecorder
    private(set) var recorderSettings: [String: Any] = [:]

    private init() {
    }

    /// Configures the AVAudioSession for Mumble voice communication.
    ///
    /// Sets up the audio session with:
    /// - Category: `.playAndRecord` for simultaneous input and output
    /// - Mode: `.voiceChat` optimized for VoIP
    /// - Options: Bluetooth support and default to speaker
    ///
    /// This method should be called during application initialization
    /// and when returning from background.
    func configureSession() {
        do {
            if #available(iOS 12.0, *) {
                try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            } else {
                try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
            }
            try session.setActive(true, options: [])
        } catch {
            NSLog("MUAudioSessionManager: Failed to configure audio session: %@", error.localizedDescription)
        }
    }

    /// Loads and applies audio preferences saved in UserDefaults.
    ///
    /// Reads the following preference keys:
    /// - `AudioTransmitMethod`: The transmit mode (vad, ptt, continuous)
    /// - `AudioVADKind`: The VAD algorithm kind (amplitude, snr)
    /// - `AudioVADBelow`: Lower VAD threshold (0.0-1.0)
    /// - `AudioVADAbove`: Upper VAD threshold (0.0-1.0)
    /// - `AudioQualityKind`: Codec quality preset (low, balanced, high)
    ///
    /// This method should be called after `configureSession()` to restore
    /// user preferences.
    func applySavedPreferences() {
        let defaults = UserDefaults.standard
        _ = updateTransmitMethod(withString: defaults.string(forKey: "AudioTransmitMethod"))
        _ = updateVADKind(withString: defaults.string(forKey: "AudioVADKind"))
        let lower: Float
        if let _ = defaults.object(forKey: "AudioVADBelow") {
            lower = defaults.float(forKey: "AudioVADBelow")
        } else {
            lower = vadLowerThreshold
        }
        let upper: Float
        if let _ = defaults.object(forKey: "AudioVADAbove") {
            upper = defaults.float(forKey: "AudioVADAbove")
        } else {
            upper = vadUpperThreshold
        }
        _ = updateVADThresholds(lower: lower, upper: upper)
        _ = updateCodecQualityPreset(defaults.string(forKey: "AudioQualityKind"))
    }

    /// Updates the audio transmission mode.
    ///
    /// - Parameter string: A string representation of the transmit mode.
    ///   Valid values: "ptt" (Push-to-Talk), "continuous", or "vad" (Voice Activity)
    ///   Invalid or nil values default to Voice Activity Detection.
    /// - Returns: The normalized string value of the applied mode
    ///
    /// The selected mode is persisted to UserDefaults under the key "AudioTransmitMethod".
    @discardableResult
    func updateTransmitMethod(withString string: String?) -> String {
        let resolvedMode: MUAudioTransmitMode
        switch string?.lowercased() {
        case "ptt":
            resolvedMode = .pushToTalk
        case "continuous":
            resolvedMode = .continuous
        default:
            resolvedMode = .voiceActivity
        }

        transmitMode = resolvedMode
        UserDefaults.standard.set(value(for: resolvedMode), forKey: "AudioTransmitMethod")

        do {
            try session.setMode(.voiceChat)
        } catch {
            NSLog("MUAudioSessionManager: Failed to update transmit mode: %@", error.localizedDescription)
        }

        return value(for: resolvedMode)
    }

    /// Updates the Voice Activity Detection algorithm kind.
    ///
    /// - Parameter string: A string representation of the VAD kind.
    ///   Valid values: "snr" (Signal-to-Noise Ratio) or "amplitude"
    ///   Invalid or nil values default to "amplitude".
    /// - Returns: The normalized string value of the applied VAD kind
    ///
    /// The selected kind is persisted to UserDefaults under the key "AudioVADKind".
    @discardableResult
    func updateVADKind(withString string: String?) -> String {
        let resolvedKind: String
        switch string?.lowercased() {
        case "snr":
            resolvedKind = "snr"
        default:
            resolvedKind = "amplitude"
        }

        UserDefaults.standard.set(resolvedKind, forKey: "AudioVADKind")
        return resolvedKind
    }

    /// Updates the Voice Activity Detection threshold values.
    ///
    /// - Parameters:
    ///   - lower: The lower threshold (0.0 to 1.0). Audio below this level is considered silence.
    ///   - upper: The upper threshold (0.0 to 1.0). Audio above this level is considered speech.
    /// - Returns: A dictionary containing the sanitized "lower" and "upper" threshold values
    ///
    /// Values are automatically clamped to the valid range [0.0, 1.0] and the upper
    /// threshold is ensured to be >= lower threshold. Both values are persisted to
    /// UserDefaults under keys "AudioVADBelow" and "AudioVADAbove".
    @discardableResult
    func updateVADThresholds(lower: Float, upper: Float) -> NSDictionary {
        let sanitizedLower = clamp(value: lower, lowerBound: 0.0, upperBound: 1.0)
        let sanitizedUpper = clamp(value: max(upper, sanitizedLower), lowerBound: 0.0, upperBound: 1.0)

        vadLowerThreshold = sanitizedLower
        vadUpperThreshold = sanitizedUpper

        UserDefaults.standard.set(sanitizedLower, forKey: "AudioVADBelow")
        UserDefaults.standard.set(sanitizedUpper, forKey: "AudioVADAbove")

        return ["lower": sanitizedLower, "upper": sanitizedUpper] as NSDictionary
    }

    /// Updates the audio codec quality preset.
    ///
    /// - Parameter preset: A string representation of the quality preset.
    ///   Valid values: "low", "balanced", or "high"
    ///   Invalid or nil values default to "balanced".
    /// - Returns: The normalized string value of the applied preset
    ///
    /// Each preset configures different audio parameters:
    /// - Low: 16 kHz sample rate, 16 kbps bit rate, 60ms I/O buffer
    /// - Balanced: 48 kHz sample rate, 40 kbps bit rate, 20ms I/O buffer (default)
    /// - High: 48 kHz sample rate, 72 kbps bit rate, 10ms I/O buffer
    ///
    /// The selected preset is persisted to UserDefaults under the key "AudioQualityKind".
    @discardableResult
    func updateCodecQualityPreset(_ preset: String?) -> String {
        let resolvedPreset: MUAudioCodecQualityPreset
        switch preset?.lowercased() {
        case "low":
            resolvedPreset = .low
        case "high":
            resolvedPreset = .high
        default:
            resolvedPreset = .balanced
        }

        codecQuality = resolvedPreset
        UserDefaults.standard.set(value(for: resolvedPreset), forKey: "AudioQualityKind")
        applyCodecSettings(for: resolvedPreset)
        return value(for: resolvedPreset)
    }

    private func applyCodecSettings(for preset: MUAudioCodecQualityPreset) {
        let sampleRate: Double
        let bitRate: Int
        let packetDuration: TimeInterval

        switch preset {
        case .low:
            sampleRate = 16000
            bitRate = 16000
            packetDuration = 0.06
        case .high:
            sampleRate = 48000
            bitRate = 72000
            packetDuration = 0.01
        case .balanced:
            sampleRate = 48000
            bitRate = 40000
            packetDuration = 0.02
        }

        recorderSettings = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        do {
            try session.setPreferredSampleRate(sampleRate)
            try session.setPreferredIOBufferDuration(packetDuration)
        } catch {
            NSLog("MUAudioSessionManager: Failed to apply codec settings: %@", error.localizedDescription)
        }
    }

    private func value(for mode: MUAudioTransmitMode) -> String {
        switch mode {
        case .pushToTalk:
            return "ptt"
        case .continuous:
            return "continuous"
        case .voiceActivity:
            return "vad"
        }
    }

    private func value(for quality: MUAudioCodecQualityPreset) -> String {
        switch quality {
        case .low:
            return "low"
        case .balanced:
            return "balanced"
        case .high:
            return "high"
        }
    }

    private func clamp(value: Float, lowerBound: Float, upperBound: Float) -> Float {
        guard value.isFinite else { return lowerBound }
        return min(max(value, lowerBound), upperBound)
    }
}
