// Copyright 2024 The 'Mumble for iOS' Developers.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#import "MUAudioCaptureManager.h"
#import <math.h>

static const float kMinimumMeterPowerDb = -96.0f;
static NSString * const kAudioMeterUpdateNotification = @"MUAudioCaptureManagerMeterUpdate";

@interface MUAudioCaptureManager ()
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioFormat *inputFormat;
@property (nonatomic, assign) MUTransmitMode transmitMode;
@property (nonatomic, assign) float vadMin;
@property (nonatomic, assign) float vadMax;
@property (nonatomic, assign) float meterLevel;
@property (nonatomic, assign) float speechProbability;
@property (nonatomic, assign, getter=isTransmitting) BOOL transmitting;
@property (nonatomic, assign) BOOL tapInstalled;
@property (nonatomic, copy) dispatch_block_t meteringHandler;
@end

@implementation MUAudioCaptureManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static MUAudioCaptureManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[MUAudioCaptureManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if ((self = [super init])) {
        _engine = [[AVAudioEngine alloc] init];
        _meterLevel = 0.0f;
        _vadMin = 0.0f;
        _vadMax = 1.0f;
        _transmitMode = MUTransmitModeVAD;
        _inputFormat = [_engine.inputNode inputFormatForBus:0];
    }
    return self;
}

#pragma mark - Configuration

- (void)configureFromDefaults {
    [self refreshTransmitMode];
    [self refreshVADThresholds];
    [self refreshEncoderPreferences];
}

- (void)refreshTransmitMode {
    NSString *method = [[NSUserDefaults standardUserDefaults] stringForKey:@"AudioTransmitMethod"];
    if ([method isEqualToString:@"continuous"]) {
        self.transmitMode = MUTransmitModeContinuous;
    } else if ([method isEqualToString:@"ptt"]) {
        self.transmitMode = MUTransmitModePushToTalk;
    } else {
        self.transmitMode = MUTransmitModeVAD;
    }
}

- (void)refreshVADThresholds {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.vadMin = [defaults floatForKey:@"AudioVADBelow"];
    self.vadMax = [defaults floatForKey:@"AudioVADAbove"];
}

- (void)refreshEncoderPreferences {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *quality = [defaults stringForKey:@"AudioQualityKind"];
    double sampleRate = 48000.0;
    if ([quality isEqualToString:@"low"]) {
        sampleRate = 16000.0;
    } else if ([quality isEqualToString:@"balanced"]) {
        sampleRate = 40000.0;
    } else if ([quality isEqualToString:@"high"] || [quality isEqualToString:@"opus"]) {
        sampleRate = 72000.0;
    }

    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
             withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionMixWithOthers
                   error:&error];
    [session setPreferredSampleRate:sampleRate error:&error];
    [session setPreferredIOBufferDuration:0.02 error:&error];
    [session setActive:YES error:&error];

    self.inputFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sampleRate channels:1];

    NSDictionary *settings = @{ AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                AVSampleRateKey : @(sampleRate),
                                AVNumberOfChannelsKey : @(1),
                                AVEncoderBitRateKey : @((NSInteger)sampleRate),
                                AVEncoderAudioQualityKey : @(AVAudioQualityHigh)};
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:@"/dev/null"]
                                                settings:settings
                                                   error:&error];
    self.recorder.meteringEnabled = YES;
    if (!error) {
        [self.recorder prepareToRecord];
    }
}

#pragma mark - Engine lifecycle

- (void)start {
    [self installTapIfNeeded];
    if (![self.engine isRunning]) {
        NSError *error = nil;
        [self.engine startAndReturnError:&error];
        if (error) {
            NSLog(@"MUAudioCaptureManager: failed to start engine: %@", error);
        }
    }
    if (self.transmitMode == MUTransmitModeContinuous) {
        self.transmitting = YES;
    }
    if (self.transmitMode == MUTransmitModePushToTalk && self.recorder) {
        [self.recorder record];
    }
}

- (void)stop {
    if (self.tapInstalled) {
        [self.engine.inputNode removeTapOnBus:0];
        self.tapInstalled = NO;
    }
    [self.engine stop];
    if (self.recorder.isRecording) {
        [self.recorder stop];
    }
    self.transmitting = NO;
}

#pragma mark - Push-to-talk

- (void)beginPushToTalk {
    if (self.transmitMode != MUTransmitModePushToTalk) {
        return;
    }
    self.transmitting = YES;
    if (self.recorder && !self.recorder.isRecording) {
        [self.recorder record];
    }
}

- (void)endPushToTalk {
    if (self.transmitMode != MUTransmitModePushToTalk) {
        return;
    }
    self.transmitting = NO;
    if (self.recorder.isRecording) {
        [self.recorder stop];
    }
}

#pragma mark - Metering

- (void)installTapIfNeeded {
    AVAudioInputNode *input = self.engine.inputNode;
    if (!input) {
        return;
    }
    if (self.tapInstalled) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [input installTapOnBus:0 bufferSize:1024 format:self.inputFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [weakSelf processBuffer:buffer];
    }];
    self.tapInstalled = YES;
}

- (void)processBuffer:(AVAudioPCMBuffer *)buffer {
    AVAudioFrameCount frameLength = buffer.frameLength;
    if (frameLength == 0) {
        return;
    }

    float *data = buffer.floatChannelData[0];
    float sum = 0.0f;
    for (AVAudioFrameCount i = 0; i < frameLength; ++i) {
        sum += data[i] * data[i];
    }
    float rms = sqrtf(sum / (float)frameLength);
    float powerDb = 20.0f * log10f(rms);
    if (!isfinite(powerDb)) {
        powerDb = kMinimumMeterPowerDb;
    }
    float normalizedPower = (powerDb - kMinimumMeterPowerDb) / fabsf(kMinimumMeterPowerDb);
    normalizedPower = fmaxf(0.0f, fminf(1.0f, normalizedPower));

    self.meterLevel = normalizedPower;

    if (self.transmitMode == MUTransmitModeVAD) {
        float probability = 0.0f;
        if (self.vadMax > self.vadMin) {
            probability = (normalizedPower - self.vadMin) / (self.vadMax - self.vadMin);
            probability = fmaxf(0.0f, fminf(1.0f, probability));
        }
        self.speechProbability = probability;
        BOOL shouldTransmit = normalizedPower >= self.vadMax;
        BOOL shouldStop = normalizedPower <= self.vadMin;
        if (shouldTransmit) {
            self.transmitting = YES;
        } else if (shouldStop) {
            self.transmitting = NO;
        }
    } else if (self.transmitMode == MUTransmitModeContinuous) {
        self.transmitting = YES;
    }

    dispatch_block_t handler = self.meteringHandler;
    if (handler) {
        dispatch_async(dispatch_get_main_queue(), handler);
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kAudioMeterUpdateNotification object:self];
}

- (void)setMeteringHandler:(dispatch_block_t)handler {
    _meteringHandler = [handler copy];
}

@end
