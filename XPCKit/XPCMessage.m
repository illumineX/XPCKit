//
//  XPCMessage.m
//  XPCKit
//
//  Created by Jörg Jacobsen on 14/2/12. Copyright 2012 XPCKit.
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
#import "XPCExtensions.h"

@interface XPCMessage()

- (id)_initWithFirstObject:(id)firstObject arguments:(va_list)argumentList;

@end


@implementation XPCMessage

- (void) setXPCDictionary:(xpc_object_t)inXPCDictionary
{
    if (xpc_get_type(inXPCDictionary) != XPC_TYPE_DICTIONARY)
    {
        [NSException raise:NSInvalidArgumentException format:@"Argument must be of type XPC_TYPE_DICTIONARY"];
    }
    _XPCDictionary = inXPCDictionary;
}

#pragma mark - Lifecycle

+ (instancetype)message
{
    return [[[XPCMessage alloc] init] autorelease];
}


+ (instancetype)messageWithXPCDictionary:(xpc_object_t)inXPCDictionary
{
    return [[[XPCMessage alloc] initWithXPCDictionary:inXPCDictionary] autorelease];
}


// Returns an empty (reply)message based on a message supposedly coming from the wire.
// If that incoming message was sent through -sentMessage:withReply: the returned message
// will be setup for being sent to the incoming message's reply handler.
// Otherwise, this method will simply return an empty message (that will be routed
// to a generic event handler).
// Initialize a message that is supposed to be the reply to inOriginalMessage.
// See xpc_dictionary_create_reply() for details.

+ (instancetype)messageReplyForMessage:(XPCMessage *)inOriginalMessage
{
    return [[[XPCMessage alloc] initReplyForMessage:inOriginalMessage] autorelease];
}


+ (instancetype)messageWithObjects:(NSArray *)inObjects forKeys:(NSArray *)inKeys
{
    return [[[XPCMessage alloc] initWithObjects:inObjects forKeys:inKeys] autorelease];
}


+ (instancetype)messageWithObject:(id)inObject forKey:(NSString *)inKey
{
    return [[[XPCMessage alloc] initWithObject:inObject forKey:inKey] autorelease];
}


+ (instancetype)messageWithObjectsAndKeys:(id)firstObject, ...
{
    XPCMessage *this = [XPCMessage alloc];
    va_list argumentList;
    
    va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
    this = [this _initWithFirstObject:firstObject arguments:argumentList];
    va_end(argumentList);
    
    return [this autorelease];
}


// Returns a message that is suited for invocation

+ (instancetype)messageWithSelector:(SEL)inSelector target:(id)inTarget object:(id)inObject
{
    return [[[XPCMessage alloc] initWithSelector:inSelector target:inTarget object:inObject] autorelease];
}



// First designated initializer

- (instancetype)initWithXPCDictionary:(xpc_object_t)inXPCDictionary
{
    if ((self = [super init]))
    {
        if (!inXPCDictionary) {
            [self setXPCDictionary:xpc_dictionary_create(NULL, NULL, 0)];
        } else {
            [self setXPCDictionary:xpc_retain(inXPCDictionary)];
        }
    }
    return self;
}

- (id)_initReplyForMessage:(XPCMessage *)inOriginalMessage
{
    if ((self = [super init]))
    {
        if ([inOriginalMessage needsDirectReply])
        {
            [self setXPCDictionary:xpc_dictionary_create_reply(inOriginalMessage.XPCDictionary)];
        } else {
            [self setXPCDictionary:xpc_dictionary_create(NULL, NULL, 0)];
        }
    }
    return self;
}


// Second designated initializer:
//
// Initialize a message that is supposed to be the reply to inOriginalMessage coming from the wire.
// If the incoming message was sent through -sendMessage:withReply: the returned message
// will be setup for being sent to the incoming message's reply handler.
// Otherwise, this method will simply return an empty message (that will be routed
// to a generic event handler).
// See also xpc_dictionary_create_reply().

- (instancetype)initReplyForMessage:(XPCMessage *)inOriginalMessage
{
        if (inOriginalMessage)
        {
            return [self _initReplyForMessage:inOriginalMessage];
        } else {
            return [self init];
        }
}



// Initialize a message that is suited for invocation

- (instancetype)initWithSelector:(SEL)inSelector target:(id)inTarget object:(id)inObject
{
    return [self initWithObjectsAndKeys:
            inTarget,   @"target",
            NSStringFromSelector(inSelector), @"selector",
            inObject,   @"object1",
            nil];
}


- (instancetype)initWithObjects:(NSArray *)inObjects forKeys:(NSArray *)inKeys
{
    if ((self = [self init]))
    {
        id object = nil;
        id key = nil;
        
        if (inObjects.count != inKeys.count) {
            [NSException raise:NSInvalidArgumentException format:@"Objects and keys don't match in numbers"];
        }
        for (NSUInteger i = 0; i < inObjects.count; i++)
        {
            object = inObjects[i];
            
            if ([(key = inKeys[i]) isKindOfClass:[NSString class]])
            {
                [self setObject:object forKey:key];
            } else {
                [NSException raise:NSInvalidArgumentException format:@"Trying to initialize %@ with %@ key. Key must be of NSString", self.className, key];
            }
            
        }
    }
    return self;
}


- (instancetype)initWithObject:(id)inObject forKey:(NSString *)inKey
{
    return [self initWithObjects:@[inObject] forKeys:@[inKey]];
}


- (id)_initWithFirstObject:(id)firstObject arguments:(va_list)argumentList
{
    if (firstObject) // The first argument isn't part of the varargs list, so we'll handle it separately.
    {
        id eachObject;
        NSMutableArray *objects = [NSMutableArray array];
        NSMutableArray *keys = [NSMutableArray array];
        
        [objects addObject: firstObject];
        NSMutableArray *objectsOrKeys = keys;
        while ((eachObject = va_arg(argumentList, id)))  // As many times as we can get an argument of type "id"
        {
            [objectsOrKeys addObject: eachObject];
            objectsOrKeys = objectsOrKeys == objects ? keys : objects;
        }
        return [self initWithObjects:objects forKeys:keys];
    }
    return [self init];
}


- (instancetype)initWithObjectsAndKeys:(id)firstObject, ...
{
    va_list argumentList;
    
    va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
    self = [self _initWithFirstObject:firstObject arguments:argumentList];
    va_end(argumentList);
    
    return self;
}


- (instancetype)init
{
    return [self initWithXPCDictionary:NULL];
}


- (void)dealloc
{
    if (_XPCDictionary) {
        xpc_release(_XPCDictionary);
    }
    [super dealloc];
}


#pragma mark - Accessing/Adding Values
#pragma mark Accessors

- (id)objectForKey:(NSString *)inKey
{
    const char *lowLevelKey = [inKey cStringUsingEncoding:NSUTF8StringEncoding];
    xpc_object_t value = xpc_dictionary_get_value(_XPCDictionary, lowLevelKey);
    
    if (value) {
        return [NSObject objectWithXPCObject:value];
    } else {
        return nil;
    }
}


- (NSArray *) arrayForKey:(NSString *)inKey
{
    id object = [self objectForKey:inKey];
    return (NSArray *) ([object isKindOfClass:[NSArray class]] ? object : nil);
}


- (NSDictionary *) dictionaryForKey:(NSString *)inKey
{
    id object = [self objectForKey:inKey];
    return (NSDictionary *) ([object isKindOfClass:[NSDictionary class]] ? object : nil);
}


- (NSString *) stringForKey:(NSString *)inKey
{
    id object = [self objectForKey:inKey];
    return (NSString *) ([object isKindOfClass:[NSString class]] ? object : nil);
}


- (NSURL *) URLForKey:(NSString *)inKey
{
    id object = [self objectForKey:inKey];
    return (NSURL *) ([object isKindOfClass:[NSURL class]] ? object : nil);
}


- (NSData *) dataForKey:(NSString *)inKey
{
    id object = [self objectForKey:inKey];
    return (NSData *) ([object isKindOfClass:[NSData class]] ? object : nil);
}


- (BOOL) boolForKey:(NSString *)inKey
{
    id number = [self objectForKey:inKey];
    return (BOOL) [number isKindOfClass:[NSNumber class]] ? [number boolValue] : 0;
}


- (float) floatForKey:(NSString *)inKey
{
    id number = [self objectForKey:inKey];
    return (float) [number isKindOfClass:[NSNumber class]] ? [number floatValue] : 0;
}


- (NSInteger) integerForKey:(NSString *)inKey
{
    id number = [self objectForKey:inKey];
    return (NSInteger) [number isKindOfClass:[NSNumber class]] ? [number integerValue] : 0;
}


- (double) doubleForKey:(NSString *)inKey
{
    id number = [self objectForKey:inKey];
    return (double) [number isKindOfClass:[NSNumber class]] ? [number doubleValue] : 0;
}


#pragma mark Mutators

- (void)setObject:(id)inObject forKey:(NSString *)inKey
{
    xpc_object_t value = [inObject newXPCObject];
    
    if (value) 
    {
        const char *lowLevelKey = [inKey cStringUsingEncoding:NSUTF8StringEncoding];
        
        xpc_dictionary_set_value(_XPCDictionary, lowLevelKey, value);
        xpc_release(value);
    } else {
        // There is no way to convert inObject into an xpc_object_t object
        
        [NSException raise:NSInvalidArgumentException format:@"Object %@ is not convertible into xpc_object_t type. If you make it conform to NSCoding it will be. For further insight have a look at -newXPCObject.", inObject];
    }
}


- (void) setBool:(BOOL)inValue forKey:(NSString *)inKey
{
    [self setObject:@(inValue) forKey:inKey];
}


- (void) setDouble:(double)inValue forKey:(NSString *)inKey
{
    [self setObject:@(inValue) forKey:inKey];
}


- (void) setFloat:(float)inValue forKey:(NSString *)inKey
{
    [self setObject:@(inValue) forKey:inKey];
}


- (void) setInteger:(NSInteger)inValue forKey:(NSString *)inKey
{
    [self setObject:@(inValue) forKey:inKey];
}


#pragma mark - Invocation

// Returns whether this message is invocable
// (i.e. contains target and selector and optionally an argument object)

- (BOOL) invocable
{
    return (NSSelectorFromString([self objectForKey:@"selector"]) && [self objectForKey:@"target"]);
}


- (XPCMessage *) invoke
{
    SEL selector = NSSelectorFromString([self objectForKey:@"selector"]);
    id target = [self objectForKey:@"target"];
    id object = [self objectForKey:@"object1"];
    
    if (selector && target)
    {
        XPCMessage *reply = [XPCMessage messageReplyForMessage:self];
        
        NSError* error = nil;
        id result = nil;
        
        if (object) {
            result = [target performSelector:selector withObject:object withObject:(id)&error];
        } else {
            result = [target performSelector:selector withObject:(id)&error];
        }
        
        if (result) [reply setObject:result forKey:@"result"];
        if (error) [reply setObject:error forKey:@"error"];

        return reply;
    }
    return nil;
}


#pragma mark - Miscellaneous

-(NSString *) description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"\n{\n"];
    
    xpc_dictionary_apply(_XPCDictionary, ^bool(const char *inKey, xpc_object_t inValue){
        NSString *key = @(inKey);
        id value = [NSObject objectWithXPCObject:inValue];
        if(key && value)
        {
            [description appendFormat:@"    %@: %@\n", key, value];
        }
        return true;
    });
    [description appendFormat:@"}\n"];
    return description;
}

@end
