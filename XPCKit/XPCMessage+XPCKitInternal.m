//
//  XPCMessage+XPCKitInternal.m
//  XPCKit
//
//  Created by Jörg Jacobsen on 15/2/12. Copyright 2012 XPCKit.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "XPCMessage+XPCKitInternal.h"

#define XPC_DIRECT_REPLY_KEY @"__directReply"
#define XPC_LOG_LEVEL_KEY  @"__logLevel"

@implementation XPCMessage (XPCKitInternal)

+ (NSError *) errorForXPCObject:(xpc_object_t)object
{
    if (xpc_get_type(object) == XPC_TYPE_ERROR)
    {
        NSInteger errorCode = 0;
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        if (object == XPC_ERROR_CONNECTION_INVALID) {
            errorCode = XPCConnectionInvalid;
            [userInfo setValue:@"XPC connection is invalid" forKey:NSLocalizedDescriptionKey];
        } else if (object == XPC_ERROR_CONNECTION_INTERRUPTED) {
            errorCode = XPCConnectionInterrupted;
            [userInfo setValue:@"XPC connection was interrupted" forKey:NSLocalizedDescriptionKey];
        } else if (object == XPC_ERROR_TERMINATION_IMMINENT) {
            errorCode = XPCTerminationImminent;
            [userInfo setValue:@"XPC service termination is imminent" forKey:NSLocalizedDescriptionKey];
        }
        return [NSError errorWithDomain:kXPCKitErrorDomain code:errorCode userInfo:userInfo];
    }
    return nil;
}


- (xpc_object_t) XPCDictionary
{
    return _XPCDictionary;
}


- (BOOL) needsDirectReply
{
    NSNumber *directReply = nil;
    return (directReply = [self objectForKey:XPC_DIRECT_REPLY_KEY]) && directReply.boolValue;
}


- (void) setNeedsDirectReply:(BOOL)inDirectReply
{
    [self setObject:@(inDirectReply) forKey:XPC_DIRECT_REPLY_KEY];
}


- (XPCLogLevel) logLevel
{
    NSNumber *logLevel = [self objectForKey:XPC_LOG_LEVEL_KEY];
    return logLevel ? logLevel.unsignedIntValue : XPCLogLevelErrors;
}


- (void) setLogLevel:(XPCLogLevel) inLogLevel
{
    [self setObject:[NSNumber numberWithUnsignedInt:inLogLevel] forKey:XPC_LOG_LEVEL_KEY];
}


// Returns the return value stored in a message that was instantiated through -invoke

- (id) invocationReturnValue:(NSError **)outError
{
    id result = [self objectForKey:@"result"];
    if (outError) *outError = [self objectForKey:@"error"];
    
    return result;
}


@end
