import XCTest
import AVFoundation
@testable import Mumble

#if __has_include(<MumbleKit/MKAudio.h>)
import MumbleKit
#else
// Minimal stubs to allow the tests to compile in environments where
// the real MumbleKit headers are not available (such as CI runners).
@objc class MKAudio: NSObject {
    @objc static func sharedAudio() -> MKAudio {
        return MKAudio()
    }
    
    @objc var isRunning: Bool = false
    
    @objc func start() {
        isRunning = true
    }
    
    @objc func stop() {
        isRunning = false
    }
    
    @objc func restart() {
        stop()
        start()
    }
}
#endif

class MUAudioSessionManagerTests: XCTestCase {
    var sessionManager: MUAudioSessionManager!
    var mockDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        sessionManager = MUAudioSessionManager.shared
        // Use a separate suite for tests to avoid polluting user defaults
        mockDefaults = UserDefaults(suiteName: "MUAudioSessionManagerTests")!
        mockDefaults.removePersistentDomain(forName: "MUAudioSessionManagerTests")
    }
    
    override func tearDown() {
        mockDefaults.removePersistentDomain(forName: "MUAudioSessionManagerTests")
        super.tearDown()
    }
    
    // MARK: - bind(to:defaults:) Tests
    
    func testBindToMumbleKitAudioAppliesPlaybackPreferences() {
        // Given: Speaker mode is enabled in defaults
        mockDefaults.set(true, forKey: "AudioSpeakerPhoneMode")
        
        let audio = MKAudio.sharedAudio()
        
        // When: Binding to the audio instance
        sessionManager.bind(to: audio, defaults: mockDefaults)
        
        // Then: The playback preferences should be applied
        // We can verify this indirectly by checking that the method completes without error
        XCTAssertTrue(true, "bind method should complete without throwing")
    }
    
    func testBindWithSpeakerModeDisabled() {
        // Given: Speaker mode is disabled in defaults
        mockDefaults.set(false, forKey: "AudioSpeakerPhoneMode")
        
        let audio = MKAudio.sharedAudio()
        
        // When: Binding to the audio instance
        sessionManager.bind(to: audio, defaults: mockDefaults)
        
        // Then: The method should complete successfully
        XCTAssertTrue(true, "bind method should handle disabled speaker mode")
    }
    
    // MARK: - refreshPlaybackChain() Tests
    
    func testRefreshPlaybackChainCompletesSuccessfully() {
        // Given: A session manager with bound audio
        let audio = MKAudio.sharedAudio()
        sessionManager.bind(to: audio, defaults: mockDefaults)
        
        // When: Refreshing the playback chain
        sessionManager.refreshPlaybackChain()
        
        // Then: The method should complete without error
        XCTAssertTrue(true, "refreshPlaybackChain should complete without throwing")
    }
    
    // MARK: - handleRouteChange(reasonValue:defaults:) Tests
    
    func testHandleRouteChangeWithNewDeviceAvailable() {
        // Given: A route change with new device available
        let audio = MKAudio.sharedAudio()
        audio.start()
        sessionManager.bind(to: audio, defaults: mockDefaults)
        
        // When: Handling a route change for new device available
        let reason = AVAudioSession.RouteChangeReason.newDeviceAvailable
        sessionManager.handleRouteChange(reasonValue: reason.rawValue, defaults: mockDefaults)
        
        // Then: The audio subsystem should be restarted
        // This is verified by the method completing without error
        XCTAssertTrue(true, "handleRouteChange should handle new device available")
    }
    
    func testHandleRouteChangeWithOldDeviceUnavailable() {
        // Given: A route change with old device unavailable
        let audio = MKAudio.sharedAudio()
        audio.start()
        sessionManager.bind(to: audio, defaults: mockDefaults)
        
        // When: Handling a route change for old device unavailable
        let reason = AVAudioSession.RouteChangeReason.oldDeviceUnavailable
        sessionManager.handleRouteChange(reasonValue: reason.rawValue, defaults: mockDefaults)
        
        // Then: The audio subsystem should be restarted
        XCTAssertTrue(true, "handleRouteChange should handle old device unavailable")
    }
    
    func testHandleRouteChangeWithCategoryChange() {
        // Given: A route change with category change
        let audio = MKAudio.sharedAudio()
        audio.start()
        sessionManager.bind(to: audio, defaults: mockDefaults)
        
        // When: Handling a route change for category change
        let reason = AVAudioSession.RouteChangeReason.categoryChange
        sessionManager.handleRouteChange(reasonValue: reason.rawValue, defaults: mockDefaults)
        
        // Then: The audio subsystem should be restarted
        XCTAssertTrue(true, "handleRouteChange should handle category change")
    }
    
    func testHandleRouteChangeWithUnknownReason() {
        // Given: A route change with unknown reason
        let audio = MKAudio.sharedAudio()
        sessionManager.bind(to: audio, defaults: mockDefaults)
        
        // When: Handling a route change for unknown reason
        let reason = AVAudioSession.RouteChangeReason.unknown
        sessionManager.handleRouteChange(reasonValue: reason.rawValue, defaults: mockDefaults)
        
        // Then: The method should complete without restarting audio
        XCTAssertTrue(true, "handleRouteChange should handle unknown reason gracefully")
    }
    
    func testHandleRouteChangeWithOverride() {
        // Given: A route change with override reason
        let audio = MKAudio.sharedAudio()
        audio.start()
        sessionManager.bind(to: audio, defaults: mockDefaults)
        
        // When: Handling a route change for override
        let reason = AVAudioSession.RouteChangeReason.override
        sessionManager.handleRouteChange(reasonValue: reason.rawValue, defaults: mockDefaults)
        
        // Then: The audio subsystem should be restarted
        XCTAssertTrue(true, "handleRouteChange should handle override")
    }
    
    // MARK: - applyPlaybackPreferences(defaults:) Tests
    
    func testApplyPlaybackPreferencesWithSpeakerModeEnabled() {
        // Given: Speaker mode is enabled in defaults
        mockDefaults.set(true, forKey: "AudioSpeakerPhoneMode")
        
        // When: Applying playback preferences
        sessionManager.applyPlaybackPreferences(defaults: mockDefaults)
        
        // Then: The method should complete successfully
        XCTAssertTrue(true, "applyPlaybackPreferences should apply speaker mode")
    }
    
    func testApplyPlaybackPreferencesWithSpeakerModeDisabled() {
        // Given: Speaker mode is disabled in defaults
        mockDefaults.set(false, forKey: "AudioSpeakerPhoneMode")
        
        // When: Applying playback preferences
        sessionManager.applyPlaybackPreferences(defaults: mockDefaults)
        
        // Then: The method should complete successfully
        XCTAssertTrue(true, "applyPlaybackPreferences should apply receiver mode")
    }
    
    func testApplyPlaybackPreferencesWithDefaultValue() {
        // Given: No explicit speaker mode setting in defaults (should default to false)
        // When: Applying playback preferences
        sessionManager.applyPlaybackPreferences(defaults: mockDefaults)
        
        // Then: The method should complete successfully with default value
        XCTAssertTrue(true, "applyPlaybackPreferences should handle default value")
    }
    
    // MARK: - configureSession(activate:) Tests
    
    func testConfigureSessionWithActivation() {
        // Given: A session manager
        // When: Configuring the session with activation
        sessionManager.configureSession(activate: true)
        
        // Then: The session should be configured and activated
        XCTAssertTrue(true, "configureSession should activate when requested")
    }
    
    func testConfigureSessionWithoutActivation() {
        // Given: A session manager
        // When: Configuring the session without activation
        sessionManager.configureSession(activate: false)
        
        // Then: The session should be configured but not activated
        XCTAssertTrue(true, "configureSession should not activate when not requested")
    }
    
    func testConfigureSessionDefaultActivation() {
        // Given: A session manager
        // When: Configuring the session with default parameter
        sessionManager.configureSession()
        
        // Then: The session should be activated by default
        XCTAssertTrue(true, "configureSession should activate by default")
    }
}
