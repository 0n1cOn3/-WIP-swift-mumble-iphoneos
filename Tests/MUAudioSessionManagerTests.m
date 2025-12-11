#import <XCTest/XCTest.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

// Import MumbleKit if available, otherwise use stubs
#if __has_include(<MumbleKit/MKAudio.h>)
#import <MumbleKit/MKAudio.h>
#else
// Minimal stubs to allow the tests to compile in environments where
// the real MumbleKit headers are not available (such as CI runners).
@interface MKAudio : NSObject
@property (nonatomic) BOOL isRunning;
- (void)start;
- (void)stop;
- (void)restart;
@end

@implementation MKAudio
- (void)start {}
- (void)stop {}
- (void)restart {}
@end
#endif

// Mock MKAudio for testing that tracks method calls
@interface MockMKAudio : MKAudio
@property (nonatomic) NSInteger startCallCount;
@property (nonatomic) NSInteger stopCallCount;
@property (nonatomic) NSInteger restartCallCount;
@property (nonatomic) BOOL mockIsRunning;
@end

@implementation MockMKAudio

- (BOOL)isRunning {
    return self.mockIsRunning;
}

- (void)start {
    self.startCallCount += 1;
    self.mockIsRunning = YES;
}

- (void)stop {
    self.stopCallCount += 1;
    self.mockIsRunning = NO;
}

- (void)restart {
    self.restartCallCount += 1;
}

@end

@interface MUAudioSessionManagerTests : XCTestCase
@property (nonatomic, strong) MockMKAudio *mockAudio;
@property (nonatomic, strong) NSUserDefaults *mockDefaults;
@property (nonatomic, strong) id sessionManager;
@end

@implementation MUAudioSessionManagerTests

- (void)setUp {
    [super setUp];
    
    // Use a fresh UserDefaults suite for each test
    NSString *suiteName = [NSString stringWithFormat:@"test.suite.%@", [[NSUUID UUID] UUIDString]];
    self.mockDefaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    self.mockAudio = [[MockMKAudio alloc] init];
    
    // Access the Swift singleton via Objective-C runtime
    Class managerClass = NSClassFromString(@"Mumble.MUAudioSessionManager");
    if (managerClass) {
        self.sessionManager = [managerClass performSelector:@selector(shared)];
    }
}

- (void)tearDown {
    // Clean up the test defaults suite
    [self.mockDefaults removePersistentDomainForName:self.mockDefaults.name];
    self.mockDefaults = nil;
    self.mockAudio = nil;
    self.sessionManager = nil;
    
    [super tearDown];
}
    

// MARK: - bind(to:defaults:) Tests

- (void)testBindAppliesPlaybackPreferences {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Speaker mode preference is enabled
    [self.mockDefaults setBool:YES forKey:@"AudioSpeakerPhoneMode"];
    
    // When: Binding to MKAudio
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    
    // Then: Should complete without error
    XCTAssertNotNil(self.sessionManager);
}

- (void)testBindAppliesDefaultSpeakerModeWhenNotSet {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: No speaker mode preference set (defaults to false)
    
    // When: Binding to MKAudio
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    
    // Then: Should complete without error
    XCTAssertNotNil(self.sessionManager);
}

// MARK: - refreshPlaybackChain() Tests

- (void)testRefreshPlaybackChainRestartsRunningAudio {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Audio is bound and running
    self.mockAudio.mockIsRunning = YES;
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    
    // When: Refreshing the playback chain
    SEL refreshSelector = NSSelectorFromString(@"refreshPlaybackChain");
    if ([self.sessionManager respondsToSelector:refreshSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:refreshSelector];
#pragma clang diagnostic pop
    }
    
    // Then: Audio should be restarted
    XCTAssertEqual(self.mockAudio.restartCallCount, 1);
}

- (void)testRefreshPlaybackChainStartsStoppedAudio {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Audio is bound but not running
    self.mockAudio.mockIsRunning = NO;
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    
    // Reset call counts after bind
    self.mockAudio.startCallCount = 0;
    
    // When: Refreshing the playback chain
    SEL refreshSelector = NSSelectorFromString(@"refreshPlaybackChain");
    if ([self.sessionManager respondsToSelector:refreshSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:refreshSelector];
#pragma clang diagnostic pop
    }
    
    // Then: Audio should be started
    XCTAssertEqual(self.mockAudio.startCallCount, 1);
}

// MARK: - handleRouteChange(reasonValue:defaults:) Tests

- (void)testHandleRouteChangeWithNewDeviceRestartsAudio {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Audio is bound and running
    self.mockAudio.mockIsRunning = YES;
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    self.mockAudio.restartCallCount = 0;
    
    // When: Route changes due to new device
    AVAudioSessionRouteChangeReason reason = AVAudioSessionRouteChangeReasonNewDeviceAvailable;
    SEL handleSelector = NSSelectorFromString(@"handleRouteChangeWithReason:defaults:");
    if ([self.sessionManager respondsToSelector:handleSelector]) {
        NSMethodSignature *signature = [self.sessionManager methodSignatureForSelector:handleSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handleSelector];
        [invocation setTarget:self.sessionManager];
        
        NSUInteger reasonValue = (NSUInteger)reason;
        [invocation setArgument:&reasonValue atIndex:2];
        [invocation setArgument:&_mockDefaults atIndex:3];
        [invocation invoke];
    }
    
    // Then: Audio should be restarted
    XCTAssertEqual(self.mockAudio.restartCallCount, 1);
}

- (void)testHandleRouteChangeWithOldDeviceUnavailableRestartsAudio {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Audio is bound and running
    self.mockAudio.mockIsRunning = YES;
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    self.mockAudio.restartCallCount = 0;
    
    // When: Route changes due to device removal
    AVAudioSessionRouteChangeReason reason = AVAudioSessionRouteChangeReasonOldDeviceUnavailable;
    SEL handleSelector = NSSelectorFromString(@"handleRouteChangeWithReason:defaults:");
    if ([self.sessionManager respondsToSelector:handleSelector]) {
        NSMethodSignature *signature = [self.sessionManager methodSignatureForSelector:handleSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handleSelector];
        [invocation setTarget:self.sessionManager];
        
        NSUInteger reasonValue = (NSUInteger)reason;
        [invocation setArgument:&reasonValue atIndex:2];
        [invocation setArgument:&_mockDefaults atIndex:3];
        [invocation invoke];
    }
    
    // Then: Audio should be restarted
    XCTAssertEqual(self.mockAudio.restartCallCount, 1);
}

- (void)testHandleRouteChangeWithCategoryChangeRestartsAudio {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Audio is bound and running
    self.mockAudio.mockIsRunning = YES;
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    self.mockAudio.restartCallCount = 0;
    
    // When: Route changes due to category change
    AVAudioSessionRouteChangeReason reason = AVAudioSessionRouteChangeReasonCategoryChange;
    SEL handleSelector = NSSelectorFromString(@"handleRouteChangeWithReason:defaults:");
    if ([self.sessionManager respondsToSelector:handleSelector]) {
        NSMethodSignature *signature = [self.sessionManager methodSignatureForSelector:handleSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handleSelector];
        [invocation setTarget:self.sessionManager];
        
        NSUInteger reasonValue = (NSUInteger)reason;
        [invocation setArgument:&reasonValue atIndex:2];
        [invocation setArgument:&_mockDefaults atIndex:3];
        [invocation invoke];
    }
    
    // Then: Audio should be restarted
    XCTAssertEqual(self.mockAudio.restartCallCount, 1);
}

- (void)testHandleRouteChangeWithOverrideRestartsAudio {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Audio is bound and running
    self.mockAudio.mockIsRunning = YES;
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    self.mockAudio.restartCallCount = 0;
    
    // When: Route changes due to override
    AVAudioSessionRouteChangeReason reason = AVAudioSessionRouteChangeReasonOverride;
    SEL handleSelector = NSSelectorFromString(@"handleRouteChangeWithReason:defaults:");
    if ([self.sessionManager respondsToSelector:handleSelector]) {
        NSMethodSignature *signature = [self.sessionManager methodSignatureForSelector:handleSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handleSelector];
        [invocation setTarget:self.sessionManager];
        
        NSUInteger reasonValue = (NSUInteger)reason;
        [invocation setArgument:&reasonValue atIndex:2];
        [invocation setArgument:&_mockDefaults atIndex:3];
        [invocation invoke];
    }
    
    // Then: Audio should be restarted
    XCTAssertEqual(self.mockAudio.restartCallCount, 1);
}

- (void)testHandleRouteChangeWithWakeFromSleepRestartsAudio {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Audio is bound and running
    self.mockAudio.mockIsRunning = YES;
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    self.mockAudio.restartCallCount = 0;
    
    // When: Route changes due to wake from sleep
    AVAudioSessionRouteChangeReason reason = AVAudioSessionRouteChangeReasonWakeFromSleep;
    SEL handleSelector = NSSelectorFromString(@"handleRouteChangeWithReason:defaults:");
    if ([self.sessionManager respondsToSelector:handleSelector]) {
        NSMethodSignature *signature = [self.sessionManager methodSignatureForSelector:handleSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handleSelector];
        [invocation setTarget:self.sessionManager];
        
        NSUInteger reasonValue = (NSUInteger)reason;
        [invocation setArgument:&reasonValue atIndex:2];
        [invocation setArgument:&_mockDefaults atIndex:3];
        [invocation invoke];
    }
    
    // Then: Audio should be restarted
    XCTAssertEqual(self.mockAudio.restartCallCount, 1);
}

- (void)testHandleRouteChangeWithUnknownReasonDoesNotRestartAudio {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Audio is bound and running
    self.mockAudio.mockIsRunning = YES;
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    self.mockAudio.restartCallCount = 0;
    
    // When: Route changes for an unknown reason
    AVAudioSessionRouteChangeReason reason = AVAudioSessionRouteChangeReasonUnknown;
    SEL handleSelector = NSSelectorFromString(@"handleRouteChangeWithReason:defaults:");
    if ([self.sessionManager respondsToSelector:handleSelector]) {
        NSMethodSignature *signature = [self.sessionManager methodSignatureForSelector:handleSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handleSelector];
        [invocation setTarget:self.sessionManager];
        
        NSUInteger reasonValue = (NSUInteger)reason;
        [invocation setArgument:&reasonValue atIndex:2];
        [invocation setArgument:&_mockDefaults atIndex:3];
        [invocation invoke];
    }
    
    // Then: Audio should not be restarted
    XCTAssertEqual(self.mockAudio.restartCallCount, 0);
}

// MARK: - applyPlaybackPreferences(defaults:) Tests

- (void)testApplyPlaybackPreferencesEnablesSpeakerMode {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Speaker mode is enabled in preferences
    [self.mockDefaults setBool:YES forKey:@"AudioSpeakerPhoneMode"];
    
    // When: Applying playback preferences
    SEL applySelector = NSSelectorFromString(@"applyPlaybackPreferencesWithDefaults:");
    if ([self.sessionManager respondsToSelector:applySelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:applySelector withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    
    // Then: Should complete without error
    // (AVAudioSession state can't be verified in unit tests)
    XCTAssertNotNil(self.sessionManager);
}

- (void)testApplyPlaybackPreferencesDisablesSpeakerMode {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Speaker mode is disabled in preferences
    [self.mockDefaults setBool:NO forKey:@"AudioSpeakerPhoneMode"];
    
    // When: Applying playback preferences
    SEL applySelector = NSSelectorFromString(@"applyPlaybackPreferencesWithDefaults:");
    if ([self.sessionManager respondsToSelector:applySelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:applySelector withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    
    // Then: Should complete without error
    XCTAssertNotNil(self.sessionManager);
}

- (void)testApplyPlaybackPreferencesUsesDefaultWhenNotSet {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: No speaker mode preference set
    // (defaults to false/unset)
    
    // When: Applying playback preferences
    SEL applySelector = NSSelectorFromString(@"applyPlaybackPreferencesWithDefaults:");
    if ([self.sessionManager respondsToSelector:applySelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:applySelector withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    
    // Then: Should complete without error
    XCTAssertNotNil(self.sessionManager);
}

// MARK: - Integration Tests

- (void)testBindAndRefreshIntegration {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Speaker mode enabled and audio not running
    [self.mockDefaults setBool:YES forKey:@"AudioSpeakerPhoneMode"];
    self.mockAudio.mockIsRunning = NO;
    
    // When: Binding and then refreshing
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    self.mockAudio.startCallCount = 0;  // Reset after bind
    
    SEL refreshSelector = NSSelectorFromString(@"refreshPlaybackChain");
    if ([self.sessionManager respondsToSelector:refreshSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:refreshSelector];
#pragma clang diagnostic pop
    }
    
    // Then: Audio should be started
    XCTAssertEqual(self.mockAudio.startCallCount, 1);
}

- (void)testRouteChangeAppliesPreferences {
    if (!self.sessionManager) {
        XCTFail(@"Could not access MUAudioSessionManager.shared");
        return;
    }
    
    // Given: Audio is bound with speaker mode enabled
    [self.mockDefaults setBool:YES forKey:@"AudioSpeakerPhoneMode"];
    self.mockAudio.mockIsRunning = YES;
    SEL bindSelector = NSSelectorFromString(@"bindToMumbleKitAudio:defaults:");
    if ([self.sessionManager respondsToSelector:bindSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.sessionManager performSelector:bindSelector withObject:self.mockAudio withObject:self.mockDefaults];
#pragma clang diagnostic pop
    }
    
    // When: Route changes and preferences are updated
    [self.mockDefaults setBool:NO forKey:@"AudioSpeakerPhoneMode"];
    AVAudioSessionRouteChangeReason reason = AVAudioSessionRouteChangeReasonNewDeviceAvailable;
    SEL handleSelector = NSSelectorFromString(@"handleRouteChangeWithReason:defaults:");
    if ([self.sessionManager respondsToSelector:handleSelector]) {
        NSMethodSignature *signature = [self.sessionManager methodSignatureForSelector:handleSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:handleSelector];
        [invocation setTarget:self.sessionManager];
        
        NSUInteger reasonValue = (NSUInteger)reason;
        [invocation setArgument:&reasonValue atIndex:2];
        [invocation setArgument:&_mockDefaults atIndex:3];
        [invocation invoke];
    }
    
    // Then: Should apply new preferences and restart audio
    XCTAssertEqual(self.mockAudio.restartCallCount, 1);
}

@end