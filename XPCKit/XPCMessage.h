//
//  XPCMessage.h
//  XPCKit
//
//  Created by Jörg Jacobsen on 14/2/12. Copyright 2012 XPCKit.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import <xpc/xpc.h>

#define kXPCKitErrorDomain @"com.joergjacobsen.xpckit"

enum {
    XPCConnectionInterrupted = 1001,
    XPCConnectionInvalid = 1002,
    XPCTerminationImminent = 2001,
};

extern const char *XPCMessageErrorKey;

@interface XPCMessage : NSObject
{    
    xpc_object_t _XPCDictionary;
}

+ (instancetype)message;
+ (instancetype)messageWithXPCDictionary:(xpc_object_t)inXPCDictionary;
+ (instancetype)messageReplyForMessage:(XPCMessage *)inOriginalMessage;
+ (instancetype)messageWithObjects:(NSArray *)inObjects forKeys:(NSArray *)inKeys;
+ (instancetype)messageWithObject:(id)inObject forKey:(NSString *)inKey;
+ (instancetype)messageWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
+ (instancetype)messageWithSelector:(SEL)inSelector target:(id)inTarget object:(id)inObject;

- (instancetype)initWithXPCDictionary:(xpc_object_t)inXPCDictionary NS_DESIGNATED_INITIALIZER;
- (instancetype)initReplyForMessage:(XPCMessage *)inOriginalMessage;
- (instancetype)initWithObjects:(NSArray *)inObjects forKeys:(NSArray *)inKeys;
- (instancetype)initWithObject:(id)inObject forKey:(NSString *)inKey;
- (instancetype)initWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (instancetype)initWithSelector:(SEL)inSelector target:(id)inTarget object:(id)inObject;

- (id)objectForKey:(NSString *)inKey;

// Convenience accessors
- (NSArray *) arrayForKey:(NSString *)inKey;
- (NSDictionary *) dictionaryForKey:(NSString *)inKey;
- (NSString *) stringForKey:(NSString *)inKey;
- (NSURL *) URLForKey:(NSString *)inKey;
- (NSData *) dataForKey:(NSString *)inKey;
- (BOOL) boolForKey:(NSString *)inKey;
- (float) floatForKey:(NSString *)inKey;
- (NSInteger) integerForKey:(NSString *)inKey;
- (double) doubleForKey:(NSString *)inKey;

- (void)setObject:(id)inObject forKey:(NSString *)inKey;

// Convenience mutators
- (void) setBool:(BOOL)inValue forKey:(NSString *)inKey;
- (void) setDouble:(double)inValue forKey:(NSString *)inKey;
- (void) setFloat:(float)inValue forKey:(NSString *)inKey;
- (void) setInteger:(NSInteger)inValue forKey:(NSString *)inKey;

// Invocation

// Returns whether this message is invocable
// (i.e. contains target and selector and optionally an argument object)

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL invocable;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) XPCMessage *invoke;
@end
