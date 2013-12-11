//
//  JCPropertyMapper.m
//  JCModel
//
//  Created by Joseph Constantakis on 10/25/13.
//  Copyright (c) 2013 Joseph Constantakis. All rights reserved.
//

#import "JCPropertyMapper.h"
#import "NSObject+Properties.h"

@implementation JCPropertyMapper

- (void)mapJSON:(id)json toObject:(id)object usingMappingPlist:(NSString *)plistName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
    NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:path];
    [self mapJSON:json toObject:object usingMapping:plist];
}

- (void)mapJSON:(id)json toObject:(id)object usingMapping:(NSDictionary *)mapping
{
    for (NSString *remoteKey in mapping) {
        
        id value = [self getValueForKeyPath:remoteKey inCollection:json];

        if (!value) {
            NSLog(@"mapping error: json dictionary %@ has no value for key path %@", json, remoteKey);
            continue;
            
        } else if (value == [NSNull null]) {
            value = nil;
        }
        
        NSString *localKey = mapping[remoteKey];

        if ([object hasPropertyNamed:localKey]) {
            Class destClass = [[object class] classOfPropertyNamed:localKey];
            [object setValue:[self value:value transformedToClass:destClass] forKey:localKey];
        } else
            NSLog(@"mapping error: object %@ has no property named %@", object, localKey);
    }
}

- (id)value:(id)value transformedToClass:(Class)destClass
{
    if ([[value class] isSubclassOfClass:destClass])
        return value;
    if (destClass == [NSString class])
        return [value description];
    if ([[value class] isSubclassOfClass:[NSString class]]) {
        if (destClass == [NSNumber class]) {
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            return [f numberFromString:value];
        } if (destClass == [NSDate class]) {
            NSDateFormatter *f = [[NSDateFormatter alloc] init];
            [f setDateFormat:self.defaultDateFormat];
            return [f dateFromString:value];
        }
    }
    if ([[value class] isSubclassOfClass:[NSArray class]]) {
        if (destClass == [NSSet class])
            return [NSSet setWithArray:value];
        if (destClass == [NSMutableSet class])
            return [NSMutableSet setWithArray:value];
        if (destClass == [NSOrderedSet class])
            return [NSOrderedSet orderedSetWithArray:value];
        if (destClass == [NSMutableOrderedSet class])
            return [NSMutableOrderedSet orderedSetWithArray:value];
    }
    NSLog(@"failed to transform value %@ to class %@", value, destClass);
    return value;
}

- (id)getValueForKeyPath:(NSString *)keyPath inCollection:(id)coll
{
    NSString *key = keyPath;
    NSUInteger dotIndex = [keyPath rangeOfString:@"."].location;
    
    if (dotIndex != NSNotFound) {
        key = [keyPath substringToIndex:dotIndex];
        keyPath = [keyPath substringFromIndex:dotIndex+1];
        return [self getValueForKeyPath:keyPath inCollection:[coll valueForKey:key]];
    }
    
    //if coll is an array, valueForKey handles this elegantly
    return [coll valueForKey:key];
}

@end
