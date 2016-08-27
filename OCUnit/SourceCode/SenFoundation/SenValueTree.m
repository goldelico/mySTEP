/*$Id: SenValueTree.m,v 1.1 2002/01/08 14:54:02 alain Exp $*/
/* Copyright (c) 1997, Sen:te Ltd.  All rights reserved. */

#import "SenValueTree.h"
#import "NSString_SenAdditions.h"
#import <SenFoundation/SenFoundation.h>
#import <Foundation/Foundation.h>

@interface NSObject (SenValueTreeExtensions)
- childForSenValueTreeClass:(Class) aSenValueTreeClass;
@end


@implementation NSObject (SenValueTreeExtensions)
- childForSenValueTreeClass:(Class) aSenValueTreeClass
{
    return [[[aSenValueTreeClass alloc] initWithValue:self] autorelease];
}
@end

@implementation NSArray (SenValueTreeExtensions)
- childForSenValueTreeClass:(Class) aSenValueTreeClass
{
    return [[[aSenValueTreeClass alloc] initWithSExpression:self] autorelease];
}
@end



@implementation SenValueTree
+ valueTreeWithPropertyList:(NSString *) aString
{
    return [[[self alloc] initWithPropertyList:aString] autorelease];
}


+ valueTreeWithOutlineString:(NSString *) aString
{
    return [[[self alloc] initWithOutlineString:aString] autorelease];
}


- initWithValue:(id) aValue
{
    [super init];
    [self setValue:aValue];
    return self;
}


- initWithSExpression:(NSArray *) anArray
{
    if (!isNilOrEmpty (anArray)) {
        NSEnumerator *objectEnumerator = [anArray objectEnumerator];
        id each;

        [self initWithValue:[objectEnumerator nextObject]];
        while (each = [objectEnumerator nextObject]) {
            [self addChild:[each childForSenValueTreeClass:[self class]]];
        }
        return self;
    }
    return nil;
}


- initWithPropertyList:(NSString *) aString
{
    NSArray *array;
    NS_DURING
        array = [aString propertyList];
    NS_HANDLER
        array = nil;
        [localException raise];
    NS_ENDHANDLER
    return ((array != nil) && [array isKindOfClass:[NSArray class]]) ? [self initWithSExpression:array] : nil;
}


- initWithOutlineArray:(NSArray *) array index:(int *) index
{
    if (*index < [array count]) {
        NSString *line = [array objectAtIndex:*index];
        NSRange indentationRange = [line indentationRange];
        NSString *content = [line substringFromIndex:indentationRange.length];

        [self initWithValue:content];
        *index = *index + 1;
        while ((*index < [array count]) && [[array objectAtIndex:*index] indentationRange].length > indentationRange.length) {
            [self addChild:[[[[self class] alloc] initWithOutlineArray:array index:index] autorelease]];
        }
    }
    return self;
}


- initWithOutlineString:(NSString *) aString
{
    NSEnumerator *lineEnumerator = [[aString componentsSeparatedByString:@"\n"] objectEnumerator];
    NSString *each;
    NSMutableArray *array = [NSMutableArray array];
    int index = 0;

    while (each = [lineEnumerator nextObject]) {
        if ([each rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]].length != 0) {
            [array addObject:each];
        }
    }
    
    return (!isNilOrEmpty (array)) ? [self initWithOutlineArray:array index:&index] : nil;
}


- (NSString *) description
{
    if ([self isLeaf]) {
        return [value description];
    }
    else {
        NSMutableArray *array = [NSMutableArray arrayWithObject:value];
        NSEnumerator *childEnumerator = [[self children] objectEnumerator];
        id child;
        while (child = [childEnumerator nextObject]) {
            [array addObject:[child description]];
        }
        return [array descriptionWithLocale:nil indent:[self depth]];
    }
}

- (BOOL) isEqual:(id) other
{
    if ([other isKindOfClass:[self class]]) {
        return [self isEqualToTree:other];
    }
    return [super isEqual:other];
}

- (BOOL) isEqualToNode:(id)other
{
    return [[self value] isEqual:[other value]];
}

- (void) dealloc
{
    RELEASE (value);
    [super dealloc];
}


- (id) value
{
    return value;
}


- (void) setValue:(id) aValue
{
    RETAIN (value, aValue);
}
@end
