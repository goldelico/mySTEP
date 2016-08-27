/*$Id: SenSelection.m,v 1.4 2001/11/22 13:11:49 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenSelection.h"
#import <Foundation/Foundation.h>


NSString	*SenSelectionWillChangeNotification = @"selectionWillChange";
NSString	*SenSelectionDidChangeNotification = @"selectionDidChange";


@implementation SenSelection

+ (SenSelection *) selection
{
    return [[[self alloc] init] autorelease];
}

+ (SenSelection *) selectionWithObject:(id)anObject
{
    SenSelection	*selection = [self selection];
    
    [selection setSelectedObjects:[NSArray arrayWithObject:anObject]];
    
    return selection;
}

- (id) init
{
    if(self = [super init])
        selectedObjects = [[NSMutableArray allocWithZone:[self zone]] init];
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:selectedObjects];
}

- (id) initWithCoder:(NSCoder *)coder
// If the decoded array contains objects that refuse 
// to decode themselves (returning nil) the array will
// contain invalid nil objects.
{
    NSArray	*decodedArray = [coder decodeObject];
    int		count = [decodedArray count];
    int		i = 0;

    selectedObjects = [[NSMutableArray alloc] init];
    for(i = 0; i < count; i++){
        id	decodedObject = [decodedArray objectAtIndex:i];
        
        if(decodedObject != nil)
            [selectedObjects addObject:decodedObject];
    }
    
    return self;
}

- (void) dealloc
{
    [selectedObjects release];
    
    [super dealloc];
}

- (Class) selectedClass
{
    if(![self isEmpty])
        return [[selectedObjects objectAtIndex:0] class];

    return Nil;
}

- (NSArray *) selectedObjects
{
    return selectedObjects;
}

- (NSObject *) selectedObject
{
    if(![self isEmpty])
        return [selectedObjects objectAtIndex:0];
    else
        return nil;
}

- (void) didChange
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SenSelectionDidChangeNotification object:self];	   
}

- (void) willChange
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SenSelectionWillChangeNotification object:self];	
}

- (void) empty
{
    if(![self isEmpty]){
        [self willChange];
        [selectedObjects removeAllObjects];
        [self didChange];
    }
}

- (BOOL) isEmpty
{
    return [selectedObjects isEmpty];
}

- (BOOL) notEmpty
{
    return [selectedObjects notEmpty];
}

- (void) setSelectedObjects:(NSArray *)objects
{
    if (![objects isEqual:selectedObjects]){
        [self willChange];
        [selectedObjects removeAllObjects];
        [selectedObjects addObjectsFromArray:objects];
        [self didChange];
    }
}

- (void) setSelectedObject:(NSObject *)anObject
{
    if(anObject == nil)
        [self empty];
    else if(([selectedObjects count] != 1) || ([selectedObjects objectAtIndex:0] != anObject)){ // Potential problem with no selectedObjects?
        [self willChange];
        [selectedObjects removeAllObjects];
        [selectedObjects addObject:anObject];
        [self didChange];
    }
}

- (void) addSelectedObject:(NSObject *)anObject
{
    if(![selectedObjects containsObject:anObject]){
        [self willChange];
        [selectedObjects addObject:anObject];
        [self didChange];
    }
}

- (unsigned int) count
{
    return [selectedObjects count];
}

- (id) objectAtIndex:(unsigned int)anIndex
{
    return [selectedObjects objectAtIndex:anIndex];
}

- (NSEnumerator *) objectEnumerator
{
    return [selectedObjects objectEnumerator];
}

- (void) addObject:(id)anObject;
{
    [self willChange];
    [selectedObjects addObject:anObject];
    [self didChange];
}

- (BOOL) containsObject:(NSObject *)anObject
{
    return [selectedObjects containsObject:anObject];
}

@end
