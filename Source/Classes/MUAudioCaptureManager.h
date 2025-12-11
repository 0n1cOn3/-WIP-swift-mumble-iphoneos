// Copyright 2024 The 'Mumble for iOS' Developers.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MUTransmitMode) {
    MUTransmitModeContinuous = 0,
    MUTransmitModePushToTalk,
    MUTransmitModeVAD,
};

/// Centralized capture pipeline built on AVAudioEngine/AVAudioRecorder.
@interface MUAudioCaptureManager : NSObject

@property (nonatomic, readonly) MUTransmitMode transmitMode;
@property (nonatomic, readonly) float vadMin;
@property (nonatomic, readonly) float vadMax;
@property (nonatomic, readonly) float meterLevel;
@property (nonatomic, readonly) float speechProbability;
@property (nonatomic, readonly, getter=isTransmitting) BOOL transmitting;

+ (instancetype)sharedManager;

/// Applies defaults for transmit mode, thresholds, and encoder quality.
- (void)configureFromDefaults;
/// Updates only the transmit mode from defaults.
- (void)refreshTransmitMode;
/// Updates only the VAD thresholds from defaults.
- (void)refreshVADThresholds;
/// Refreshes encoder/format hints from defaults.
- (void)refreshEncoderPreferences;

/// Starts the audio engine/recorder backing the capture pipeline.
- (void)start;
/// Stops the audio engine/recorder backing the capture pipeline.
- (void)stop;

/// Push-to-talk control entry points.
- (void)beginPushToTalk;
- (void)endPushToTalk;

/// Allows UI components to receive metering callbacks on the main thread.
- (void)setMeteringHandler:(dispatch_block_t _Nullable)handler;

@end

NS_ASSUME_NONNULL_END
