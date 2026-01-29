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

@end

NS_ASSUME_NONNULL_END
