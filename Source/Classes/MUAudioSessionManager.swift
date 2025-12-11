import Foundation
import AVFoundation

@objc public enum MUAudioTransmitMode: Int {
    case voiceActivity
    case pushToTalk
    case continuous
}

@objc public enum MUAudioCodecQualityPreset: Int {
    case low
    case balanced
    case high
}

@objcMembers
final class MUAudioSessionManager: NSObject {
    static let shared = MUAudioSessionManager()

    private let session = AVAudioSession.sharedInstance()
    private(set) var transmitMode: MUAudioTransmitMode = .voiceActivity
    private(set) var codecQuality: MUAudioCodecQualityPreset = .balanced
    private(set) var vadLowerThreshold: Float = 0.3
    private(set) var vadUpperThreshold: Float = 0.6
    private(set) var recorderSettings: [String: Any] = [:]

    private override init() {
    }

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

    func applySavedPreferences() {
        let defaults = UserDefaults.standard
        _ = updateTransmitMethod(withString: defaults.string(forKey: "AudioTransmitMethod"))
        _ = updateVADKind(withString: defaults.string(forKey: "AudioVADKind"))
        _ = updateVADThresholds(lower: defaults.float(forKey: "AudioVADBelow"), upper: defaults.float(forKey: "AudioVADAbove"))
        _ = updateCodecQualityPreset(defaults.string(forKey: "AudioQualityKind"))
    }

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
            if resolvedMode == .continuous {
                try session.setMode(.measurement)
            } else {
                try session.setMode(.voiceChat)
            }
        } catch {
            NSLog("MUAudioSessionManager: Failed to update transmit mode: %@", error.localizedDescription)
        }

        return value(for: resolvedMode)
    }

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
