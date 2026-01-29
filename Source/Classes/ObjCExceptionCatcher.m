// Copyright 2024 The 'Mumble for iOS' Developers.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#import "ObjCExceptionCatcher.h"

@implementation ObjCExceptionCatcher

+ (BOOL)tryBlock:(void(NS_NOESCAPE ^)(void))block error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    @try {
        block();
        return YES;
    } @catch (NSException *exception) {
        if (error) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            if (exception.reason) {
                userInfo[NSLocalizedDescriptionKey] = exception.reason;
            }
            if (exception.userInfo) {
                userInfo[NSUnderlyingErrorKey] = exception.userInfo;
            }
            *error = [NSError errorWithDomain:@"ObjCExceptionDomain"
                                         code:1
                                     userInfo:userInfo];
        }
        return NO;
    }
}

@end
