// Copyright 2024 The 'Mumble for iOS' Developers.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Helper class to catch Objective-C exceptions from Swift.
/// Swift cannot catch NSExceptions directly, so this wrapper is needed.
@interface ObjCExceptionCatcher : NSObject

/// Executes a block and catches any NSException thrown.
/// @param block The block to execute
/// @param error On return, contains an NSError if an exception was thrown
/// @return YES if the block executed successfully, NO if an exception was thrown
+ (BOOL)tryBlock:(void(NS_NOESCAPE ^)(void))block error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
