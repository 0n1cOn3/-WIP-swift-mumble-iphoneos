// Copyright 2009-2010 The 'Mumble for iOS' Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#import "MUApplicationDelegate.h"

#import "MUWelcomeScreenPhone.h"
#import "MUWelcomeScreenPad.h"
#import "MUDatabase.h"
#import "MUPublicServerList.h"
#import "MUConnectionController.h"
#import "MUNotificationController.h"
#import "MURemoteControlServer.h"
#import "MUImage.h"
#import "MUBackgroundView.h"

#import <AVFoundation/AVFoundation.h>
#import <MumbleKit/MKAudio.h>
#import <MumbleKit/MKVersion.h>

@interface MUApplicationDelegate () <UIApplicationDelegate> {
    UIWindow                  *_window;
    UINavigationController    *_navigationController;
    MUPublicServerListFetcher *_publistFetcher;
    BOOL                      _connectionActive;
}
- (void) setupAudio;
- (void) registerForAudioSessionNotifications;
- (void) configureAudioSessionWithDefaults:(NSUserDefaults *)defaults;
- (void) activateAudioSession;
- (void) deactivateAudioSession;
- (void) forceKeyboardLoad;
@end

@implementation MUApplicationDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionOpened:) name:MUConnectionOpenedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionClosed:) name:MUConnectionClosedNotification object:nil];
    
    // Reset application badge, in case something brought it into an inconsistent state.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    // Initialize the notification controller
    [MUNotificationController sharedController];
    
    // Try to fetch an updated public server list
    _publistFetcher = [[MUPublicServerListFetcher alloc] init];
    [_publistFetcher attemptUpdate];
    
    // Set MumbleKit release string
    [[MKVersion sharedVersion] setOverrideReleaseString:
        [NSString stringWithFormat:@"Mumble for iOS %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]];
    
    // Enable Opus unconditionally
    [[MKVersion sharedVersion] setOpusEnabled:YES];

    // Register default settings
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                // Audio
                                                                [NSNumber numberWithFloat:1.0f],   @"AudioOutputVolume",
                                                                [NSNumber numberWithFloat:0.6f],   @"AudioVADAbove",
                                                                [NSNumber numberWithFloat:0.3f],   @"AudioVADBelow",
                                                                @"amplitude",                      @"AudioVADKind",
                                                                @"vad",                            @"AudioTransmitMethod",
                                                                [NSNumber numberWithBool:YES],     @"AudioPreprocessor",
                                                                [NSNumber numberWithBool:YES],     @"AudioEchoCancel",
                                                                [NSNumber numberWithFloat:1.0f],   @"AudioMicBoost",
                                                                @"balanced",                       @"AudioQualityKind",
                                                                [NSNumber numberWithBool:NO],      @"AudioSidetone",
                                                                [NSNumber numberWithFloat:0.2f],   @"AudioSidetoneVolume",
                                                                [NSNumber numberWithBool:YES],     @"AudioSpeakerPhoneMode",
                                                                [NSNumber numberWithBool:YES],     @"AudioOpusCodecForceCELTMode",
                                                                // Network
                                                                [NSNumber numberWithBool:NO],      @"NetworkForceTCP",
                                                                @"MumbleUser",                     @"DefaultUserName",
                                                        nil]];

    // Disable mixer debugging for all builds.
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"AudioMixerDebug"];

    [self reloadPreferences];
    [MUDatabase initializeDatabase];

    [self registerForAudioSessionNotifications];

#ifdef ENABLE_REMOTE_CONTROL
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"RemoteControlServerEnabled"]) {
        [[MURemoteControlServer sharedRemoteControlServer] start];
    }
#endif
    
    // Try to use a dark keyboard throughout the app's text fields.
    if (@available(iOS 7, *)) {
        [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDark];
    }
    
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if (@available(iOS 7, *)) {
    // XXX: don't do it system-wide just yet
    //    _window.tintColor = [UIColor whiteColor];
    }

    UINavigationBar.appearance.tintColor = [UIColor whiteColor];
    UINavigationBar.appearance.translucent = NO;
    UINavigationBar.appearance.barTintColor = [UIColor blackColor];
    UINavigationBar.appearance.backgroundColor = [UIColor blackColor];
    UINavigationBar.appearance.barStyle = UIBarStyleBlack;
    
    // Put a background view in here, to have prettier transitions.
    [_window addSubview:[MUBackgroundView backgroundView]];

    // Add our default navigation controller
    _navigationController = [[UINavigationController alloc] init];
    _navigationController.toolbarHidden = YES;

    UIUserInterfaceIdiom idiom = [[UIDevice currentDevice] userInterfaceIdiom];
    UIViewController *welcomeScreen = nil;
    if (idiom == UIUserInterfaceIdiomPad) {
        welcomeScreen = [[MUWelcomeScreenPad alloc] init];
        [_navigationController pushViewController:welcomeScreen animated:YES];
    } else {
        welcomeScreen = [[MUWelcomeScreenPhone alloc] init];
        [_navigationController pushViewController:welcomeScreen animated:YES];
    }
    
    [_window setRootViewController:_navigationController];
    [_window makeKeyAndVisible];

    NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if ([[url scheme] isEqualToString:@"mumble"]) {
        MUConnectionController *connController = [MUConnectionController sharedController];
        NSString *hostname = [url host];
        NSNumber *port = [url port];
        NSString *username = [url user];
        NSString *password = [url password];
        [connController connetToHostname:hostname port:port ? [port integerValue] : 64738 withUsername:username andPassword:password withParentViewController:welcomeScreen];
        return YES;
    }
    return NO;
}

- (BOOL) application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([[url scheme] isEqualToString:@"mumble"]) {
        MUConnectionController *connController = [MUConnectionController sharedController];
        if ([connController isConnected]) {
            return NO;
        }
        NSString *hostname = [url host];
        NSNumber *port = [url port];
        NSString *username = [url user];
        NSString *password = [url password];
        [connController connetToHostname:hostname port:port ? [port integerValue] : 64738 withUsername:username andPassword:password withParentViewController:_navigationController.visibleViewController];
        return YES;
    }
    return NO;
}

- (void) applicationWillTerminate:(UIApplication *)application {
    [MUDatabase teardown];
}

- (void) setupAudio {
    // Set up a good set of default audio settings.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    MKAudioSettings settings;

    [self configureAudioSessionWithDefaults:defaults];

    if ([[defaults stringForKey:@"AudioTransmitMethod"] isEqualToString:@"vad"])
        settings.transmitType = MKTransmitTypeVAD;
    else if ([[defaults stringForKey:@"AudioTransmitMethod"] isEqualToString:@"continuous"])
        settings.transmitType = MKTransmitTypeContinuous;
    else if ([[defaults stringForKey:@"AudioTransmitMethod"] isEqualToString:@"ptt"])
        settings.transmitType = MKTransmitTypeToggle;
    else
        settings.transmitType = MKTransmitTypeVAD;
    
    settings.vadKind = MKVADKindAmplitude;
    if ([[defaults stringForKey:@"AudioVADKind"] isEqualToString:@"snr"]) {
        settings.vadKind = MKVADKindSignalToNoise;
    } else if ([[defaults stringForKey:@"AudioVADKind"] isEqualToString:@"amplitude"]) {
        settings.vadKind = MKVADKindAmplitude;
    }
    
    settings.vadMin = [defaults floatForKey:@"AudioVADBelow"];
    settings.vadMax = [defaults floatForKey:@"AudioVADAbove"];
    
    NSString *quality = [defaults stringForKey:@"AudioQualityKind"];
    if ([quality isEqualToString:@"low"]) {
        // Will fall back to CELT if the
        // server requires it for inter-op.
        settings.codec = MKCodecFormatOpus;
        settings.quality = 16000;
        settings.audioPerPacket = 6;
    } else if ([quality isEqualToString:@"balanced"]) {
        // Will fall back to CELT if the 
        // server requires it for inter-op.
        settings.codec = MKCodecFormatOpus;
        settings.quality = 40000;
        settings.audioPerPacket = 2;
    } else if ([quality isEqualToString:@"high"] || [quality isEqualToString:@"opus"]) {
        // Will fall back to CELT if the 
        // server requires it for inter-op.
        settings.codec = MKCodecFormatOpus;
        settings.quality = 72000;
        settings.audioPerPacket = 1;
    } else {
        settings.codec = MKCodecFormatCELT;
        if ([[defaults stringForKey:@"AudioCodec"] isEqualToString:@"opus"])
            settings.codec = MKCodecFormatOpus;
        if ([[defaults stringForKey:@"AudioCodec"] isEqualToString:@"celt"])
            settings.codec = MKCodecFormatCELT;
        if ([[defaults stringForKey:@"AudioCodec"] isEqualToString:@"speex"])
            settings.codec = MKCodecFormatSpeex;
        settings.quality = (int) [defaults integerForKey:@"AudioQualityBitrate"];
        settings.audioPerPacket = (int) [defaults integerForKey:@"AudioQualityFrames"];
    }
    
    settings.noiseSuppression = -42; /* -42 dB */
    settings.amplification = 20.0f;
    settings.jitterBufferSize = 0; /* 10 ms */
    settings.volume = [defaults floatForKey:@"AudioOutputVolume"];
    settings.outputDelay = 0; /* 10 ms */
    settings.micBoost = [defaults floatForKey:@"AudioMicBoost"];
    settings.enablePreprocessor = [defaults boolForKey:@"AudioPreprocessor"];
    if (settings.enablePreprocessor) {
        settings.enableEchoCancellation = [defaults boolForKey:@"AudioEchoCancel"];
    } else {
        settings.enableEchoCancellation = NO;
    }

    settings.enableSideTone = [defaults boolForKey:@"AudioSidetone"];
    settings.sidetoneVolume = [defaults floatForKey:@"AudioSidetoneVolume"];
    
    if ([defaults boolForKey:@"AudioSpeakerPhoneMode"]) {
        settings.preferReceiverOverSpeaker = NO;
    } else {
        settings.preferReceiverOverSpeaker = YES;
    }

    settings.opusForceCELTMode = [defaults boolForKey:@"AudioOpusCodecForceCELTMode"];
    settings.audioMixerDebug = [defaults boolForKey:@"AudioMixerDebug"];

    MKAudio *audio = [MKAudio sharedAudio];
    [audio updateAudioSettings:&settings];
    [audio restart];

    [self activateAudioSession];
}

// Reload application preferences...
- (void) reloadPreferences {
    [self setupAudio];
}

- (void) forceKeyboardLoad {
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
    [_window addSubview:textField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [textField becomeFirstResponder];
}

- (void) keyboardWillShow:(NSNotification *)notification {
    for (UIView *view in [_window subviews]) {
        if ([view isFirstResponder]) {
            [view resignFirstResponder];
            [view removeFromSuperview];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        }
    }
}

- (void) connectionOpened:(NSNotification *)notification {
    _connectionActive = YES;
}

- (void) connectionClosed:(NSNotification *)notification {
    _connectionActive = NO;
}

- (void) applicationWillResignActive:(UIApplication *)application {
    if (!_connectionActive) {
        NSLog(@"MumbleApplicationDelegate: Not connected to a server. Deactivating audio session.");
        [self deactivateAudioSession];

#ifdef ENABLE_REMOTE_CONTROL
        // Also terminate the remote control server.
        [[MURemoteControlServer sharedRemoteControlServer] stop];
#endif
    }
}

- (void) applicationDidBecomeActive:(UIApplication *)application {
    if (!_connectionActive && ![[AVAudioSession sharedInstance] isOtherAudioPlaying]) {
        NSLog(@"MumbleApplicationDelegate: Reactivating audio session after foregrounding.");
        [self activateAudioSession];

#if ENABLE_REMOTE_CONTROL
        // Re-start the remote control server.
        [[MURemoteControlServer sharedRemoteControlServer] stop];
        [[MURemoteControlServer sharedRemoteControlServer] start];
#endif
    }
}

- (void) registerForAudioSessionNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    AVAudioSession *session = [AVAudioSession sharedInstance];

    [center addObserver:self
               selector:@selector(handleAudioSessionInterruption:)
                   name:AVAudioSessionInterruptionNotification
                 object:session];

    [center addObserver:self
               selector:@selector(handleAudioSessionRouteChange:)
                   name:AVAudioSessionRouteChangeNotification
                 object:session];
}

- (void) configureAudioSessionWithDefaults:(NSUserDefaults *)defaults {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;

    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDuckOthers;
    if ([defaults boolForKey:@"AudioSpeakerPhoneMode"]) {
        options |= AVAudioSessionCategoryOptionDefaultToSpeaker;
    }
    if (@available(iOS 10.0, *)) {
        options |= AVAudioSessionCategoryOptionAllowBluetoothA2DP;
    }

    AVAudioSessionMode mode = AVAudioSessionModeVoiceChat;
    NSString *transmitMethod = [defaults stringForKey:@"AudioTransmitMethod"];
    if ([transmitMethod isEqualToString:@"continuous"]) {
        if (@available(iOS 9.0, *)) {
            mode = AVAudioSessionModeSpokenAudio;
        } else {
            mode = AVAudioSessionModeDefault;
        }
    } else if ([transmitMethod isEqualToString:@"ptt"]) {
        mode = AVAudioSessionModeDefault;
    }
    if (![defaults boolForKey:@"AudioPreprocessor"]) {
        mode = AVAudioSessionModeMeasurement;
    }

    if (@available(iOS 10.0, *)) {
        if (![session setCategory:AVAudioSessionCategoryPlayAndRecord mode:mode options:options error:&error]) {
            NSLog(@"MUApplicationDelegate: Failed to set audio session category/mode: %@", error);
        }
    } else {
        if (![session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options error:&error]) {
            NSLog(@"MUApplicationDelegate: Failed to set audio session category: %@", error);
        }
        if (![session setMode:mode error:&error]) {
            NSLog(@"MUApplicationDelegate: Failed to set audio session mode: %@", error);
        }
    }

    NSString *quality = [defaults stringForKey:@"AudioQualityKind"];
    double preferredSampleRate = 48000.0;
    if ([quality isEqualToString:@"low"]) {
        preferredSampleRate = 16000.0;
    }

    if (![session setPreferredSampleRate:preferredSampleRate error:&error]) {
        NSLog(@"MUApplicationDelegate: Unable to set preferred sample rate: %@", error);
    }

    NSInteger framesPerPacket = [defaults integerForKey:@"AudioQualityFrames"];
    if (framesPerPacket <= 0) {
        if ([quality isEqualToString:@"low"]) {
            framesPerPacket = 6;
        } else if ([quality isEqualToString:@"balanced"]) {
            framesPerPacket = 2;
        } else if ([quality isEqualToString:@"high"] || [quality isEqualToString:@"opus"]) {
            framesPerPacket = 1;
        }
    }
    if (framesPerPacket <= 0) {
        framesPerPacket = 2;
    }
    NSTimeInterval preferredIOBuffer = MAX(0.01, (NSTimeInterval) framesPerPacket * 0.01);
    NSError *ioBufferError = nil;
    if (![session setPreferredIOBufferDuration:preferredIOBuffer error:&ioBufferError]) {
        NSLog(@"MUApplicationDelegate: Unable to set preferred IO buffer duration: %@", ioBufferError);
    }

    float vadMax = [defaults floatForKey:@"AudioVADAbove"];
    float micBoost = [defaults floatForKey:@"AudioMicBoost"];
    float requestedGain = fmaxf(0.0f, fminf(1.0f, micBoost));
    if ([session isInputGainSettable]) {
        NSError *inputGainError = nil;
        if (![session setInputGain:requestedGain error:&inputGainError]) {
            NSLog(@"MUApplicationDelegate: Unable to set input gain: %@", inputGainError);
        }
    }
}

- (void) activateAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    AVAudioSessionSetActiveOptions options = AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation;
    if (![session setActive:YES withOptions:options error:&error]) {
        NSLog(@"MUApplicationDelegate: Failed to activate audio session: %@", error);
    }
}

- (void) deactivateAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    if (![session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error]) {
        NSLog(@"MUApplicationDelegate: Failed to deactivate audio session: %@", error);
    }
}

- (void) handleAudioSessionInterruption:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    AVAudioSessionInterruptionType type = [userInfo[AVAudioSessionInterruptionTypeKey] integerValue];

    if (type == AVAudioSessionInterruptionTypeBegan) {
        NSLog(@"MUApplicationDelegate: Audio session interruption began.");
        [self deactivateAudioSession];
    } else {
        AVAudioSessionInterruptionOptions options = [userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options & AVAudioSessionInterruptionOptionShouldResume) {
            [self activateAudioSession];
        }
    }
}

- (void) handleAudioSessionRouteChange:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    AVAudioSessionRouteChangeReason reason = [userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
    NSLog(@"MUApplicationDelegate: Audio route changed: %ld", (long) reason);
}

@end
