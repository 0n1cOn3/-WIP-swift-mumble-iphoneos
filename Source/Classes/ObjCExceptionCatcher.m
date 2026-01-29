// Copyright 2024 The 'Mumble for iOS' Developers.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#import "ObjCExceptionCatcher.h"
#import <AVFoundation/AVFoundation.h>

@implementation ObjCExceptionCatcher

+ (nullable NSString *)tryBlock:(void(NS_NOESCAPE ^)(void))block {
    @try {
        block();
        return nil;
    } @catch (NSException *exception) {
        return exception.reason ?: exception.name;
    }
}

+ (nullable NSString *)safelyRemoveTapOnNode:(id)node bus:(NSUInteger)bus {
    @try {
        AVAudioNode *audioNode = (AVAudioNode *)node;
        [audioNode removeTapOnBus:bus];
        return nil;
    } @catch (NSException *exception) {
        return exception.reason ?: exception.name;
    }
}

+ (nullable NSString *)safelyInstallTapOnNode:(id)node
                                          bus:(NSUInteger)bus
                                   bufferSize:(uint32_t)bufferSize
                                       format:(nullable id)format
                                     tapBlock:(void (^)(id buffer, id when))tapBlock {
    @try {
        AVAudioNode *audioNode = (AVAudioNode *)node;
        AVAudioFormat *audioFormat = (AVAudioFormat *)format;

        // Install the tap with proper ObjC exception handling context
        [audioNode installTapOnBus:bus
                        bufferSize:bufferSize
                            format:audioFormat
                             block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
            // Call the Swift-provided block with the buffer and time
            if (tapBlock) {
                tapBlock(buffer, when);
            }
        }];
        return nil;
    } @catch (NSException *exception) {
        return exception.reason ?: exception.name;
    }
}

@end
