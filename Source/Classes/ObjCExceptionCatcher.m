// Copyright 2024 The 'Mumble for iOS' Developers.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#import "ObjCExceptionCatcher.h"

@implementation ObjCExceptionCatcher

+ (nullable NSString *)tryBlock:(void(NS_NOESCAPE ^)(void))block {
    @try {
        block();
        return nil;
    } @catch (NSException *exception) {
        return exception.reason ?: exception.name;
    }
}

@end
