/*$Id: SenQualifier.m,v 1.1 2002/06/05 08:44:11 phink Exp $*/

// This is Goban, a Go program for Mac OS X.  Contact goban@sente.ch,
// or see http://www.sente.ch/software/goban for more information.
//
// Copyright (c) 1997-2002, Sen:te (Sente SA).  All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation - version 2.
//
// This program is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE.  See the GNU General Public License in file COPYING
// for more details.
//
// You should have received a copy of the GNU General Public
// License along with this program; if not, write to the Free
// Software Foundation, Inc., 59 Temple Place - Suite 330,
// Boston, MA 02111, USA.

#import "SenQualifier.h"
#import <SenFoundation/SenFoundation.h>


@implementation SenQualifier
- (BOOL) evaluateWithObject:object
{
	return NO;
}
@end


@implementation SenKeyValueQualifier
- initWithKey:(NSString *) aKey operatorSelector:(SEL) aSelector value:(id) aValue
{
	[super init];
	key = [aKey copy];
	selector = aSelector;
	value = [aValue copy];
	return self;
}


- (void) dealloc
{
	RELEASE (key);
	RELEASE (value);
	[super dealloc];
}


- (SEL) selector
{
	return selector;
}


- (NSString *) key
{
	return key;
}


- (id) value
{
	return value;
}


- (BOOL) evaluateWithObject:object
{
	return [[object valueForKey:key] performSelector:selector withObject:value] != nil ? YES : NO;
}


- (NSString *) description
{
	return [NSString stringWithFormat:@"%@ %@ %@", key, NSStringFromSelector(selector), value];
}
@end


@implementation SenAndQualifier
+ qualifierWithQualifierArray:(NSArray *) array
{
	return [[[self alloc] initWithQualifierArray:array] autorelease];
}


- initWithQualifierArray:(NSArray *) array
{
	[super init];
	qualifiers = [array copy];
	return self;
}


- (void) dealloc
{
	RELEASE (qualifiers);
	[super dealloc];
}


- (NSArray *) qualifiers
{
	return qualifiers;
}


- (BOOL) evaluateWithObject:object
{
	NSEnumerator *qualifierEnumerator = [qualifiers objectEnumerator];
	id each;
	while (each = [qualifierEnumerator nextObject]) {
		if (![each evaluateWithObject:object]) {
			return NO;
		}
	}
	return YES;
}


- (NSString *) description
{
	return [NSString stringWithFormat:@"and %@", qualifiers];
}
@end


@implementation SenOrQualifier
+ qualifierWithQualifierArray:(NSArray *) array
{
	return [[[self alloc] initWithQualifierArray:array] autorelease];
}


- initWithQualifierArray:(NSArray *) array
{
	[super init];
	qualifiers = [array copy];
	return self;
}


- (void) dealloc
{
	RELEASE (qualifiers);
	[super dealloc];
}


- (NSArray *) qualifiers
{
	return qualifiers;
}


- (BOOL) evaluateWithObject:object
{
	NSEnumerator *qualifierEnumerator = [qualifiers objectEnumerator];
	id each;
	while (each = [qualifierEnumerator nextObject]) {
		if ([each evaluateWithObject:object]) {
			return YES;
		}
	}
	return NO;
}


- (NSString *) description
{
	return [NSString stringWithFormat:@"or %@", qualifiers];
}
@end


@implementation SenNotQualifier
+ qualifierWithQualifier:(SenQualifier *) aQualifier
{
	return [[[self alloc] initWithQualifier:aQualifier] autorelease];
}


- initWithQualifier:(SenQualifier *) aQualifier
{
	[super init];
	ASSIGN (qualifier, aQualifier);
	return self;
}


- (SenQualifier *) qualifier
{
	return qualifier;
}


- (BOOL) evaluateWithObject:object
{
	return ![qualifier evaluateWithObject:object];
}


- (NSString *) description
{
	return [NSString stringWithFormat:@"not %@", qualifier];
}
@end


@implementation NSArray (SenQualifierExtras)
- (NSArray *) arrayBySelectingWithQualifier:(SenQualifier *)qualifier
{
	NSMutableArray *result = [NSMutableArray array];
	NSEnumerator *objectEnumerator = [self objectEnumerator];
	id each;
	while (each = [objectEnumerator nextObject]) {
		if ([qualifier evaluateWithObject:each]) {
			[result addObject:each];
		}
	}
	return result;
}
@end
