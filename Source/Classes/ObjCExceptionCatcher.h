// Copyright 2024 The 'Mumble for iOS' Developers.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Helper class to catch Objective-C exceptions from Swift.
/// Swift cannot catch NSExceptions directly, so this wrapper is needed.
@interface ObjCExceptionCatcher : NSObject

/// Executes a block and catches any NSException thrown.
/// Returns nil on success, or the exception reason string on failure.
/// @param block The block to execute
/// @return nil if successful, or the exception reason if an exception was thrown
+ (nullable NSString *)tryBlock:(void(NS_NOESCAPE ^)(void))block;

/// Safely removes an audio tap from an AVAudioNode if one exists.
/// Catches any NSException thrown during removal.
/// @param node The AVAudioNode to remove the tap from
/// @param bus The bus number to remove the tap from
/// @return nil if successful, or the exception reason if an exception was thrown
+ (nullable NSString *)safelyRemoveTapOnNode:(id)node bus:(NSUInteger)bus;

/// Safely installs an audio tap on an AVAudioNode.
/// This method performs the entire installation in Objective-C context to ensure
/// proper exception handling (Swift closures don't support ObjC exception unwinding).
/// @param node The AVAudioNode to install the tap on
/// @param bus The bus number to install the tap on
/// @param bufferSize The buffer size for the tap
/// @param format The audio format (AVAudioFormat) - pass nil to use node's output format
/// @param tapBlock The block to call with audio buffers
/// @return nil if successful, or the exception reason if an exception was thrown
+ (nullable NSString *)safelyInstallTapOnNode:(id)node
                                          bus:(NSUInteger)bus
                                   bufferSize:(uint32_t)bufferSize
                                       format:(nullable id)format
                                     tapBlock:(void (^)(id buffer, id when))tapBlock;

@end

NS_ASSUME_NONNULL_END
