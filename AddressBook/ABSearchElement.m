//
//  ABSearchElement.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "Private.h"

@implementation ABSearchElement

+ (ABSearchElement *) _searchElementForClass:(Class) cls property:(NSString*) property label:(NSString*) label key:(NSString*) key value:(id) value comparison:(ABSearchComparison) comparison; 
{ // initialize for class
	ABSearchElement *e=[[[self alloc] init] autorelease];
	e->_class=cls;
	e->_comparison=comparison;
	e->_property=[property retain];
	e->_label=[label retain];
	e->_key=[key retain];
	e->_value=[value retain];
	return e;
}

+ (ABSearchElement *) searchElementForConjunction:(ABSearchConjunction) conjuction children:(NSArray *) children;
{ // initialize for conjunction
	ABSearchElement *e=[[[self alloc] init] autorelease];
	e->_conjunction=conjuction;
	e->_children=[children retain];
	return e;
}

- (void) dealloc;
{
	[_property release];
	[_label release];
	[_key release];
	[_value release];
	[_children release];
	[super dealloc];
}

- (NSString *) description;
{
	NSString *str;
	if(_children)
		{
		NSEnumerator *e=[_children objectEnumerator];
		ABSearchElement *el;
		NSString *delim=@"";
		str=@"(";
		while((el=[e nextObject]))
			{
			str=[str stringByAppendingFormat:@"%@%@", delim, [el description]];
			delim=(_conjunction == kABSearchOr)?@" ||\n":@" &&\n";
			}
		return [str stringByAppendingString:@")"];
		}
	str=[NSStringFromClass(_class) stringByAppendingFormat:@".%@", _property];
	if(_label)
		str=[str stringByAppendingFormat:@"[%@]", _label];	// multi-value
	if(_key)
		str=[str stringByAppendingFormat:@".%@", _key];	// dictionary entry
	switch(_comparison)
		{
		case kABEqual:
			str=[str stringByAppendingFormat:@" == %@", _value];
			break;
		case kABNotEqual:
			str=[str stringByAppendingFormat:@" != %@", _value];
			break;
		case kABLessThan:
			str=[str stringByAppendingFormat:@" < %@", _value];
			break;
		case kABLessThanOrEqual:
			str=[str stringByAppendingFormat:@" <= %@", _value];
			break;
		case kABGreaterThan:
			str=[str stringByAppendingFormat:@" > %@", _value];
			break;
		case kABGreaterThanOrEqual:
			str=[str stringByAppendingFormat:@" >= %@", _value];
			break;
		case kABEqualCaseInsensitive:
			str=[str stringByAppendingFormat:@" a==A %@", _value];
			break;
		case kABContainsSubString:
			str=[str stringByAppendingFormat:@" contains Substring %@", _value];
			break;
		case kABContainsSubStringCaseInsensitive:
			str=[str stringByAppendingFormat:@" CoNtAiNs SuBsTrInG %@", _value];
			break;
		case kABPrefixMatch:
			str=[str stringByAppendingFormat:@" has Prefix %@", _value];
			break;
		case kABPrefixMatchCaseInsensitive:
			str=[str stringByAppendingFormat:@" HaS PrEfIx %@", _value];
			break;
			// FIXME: add new comparison methods
		default:
			str=[str stringByAppendingFormat:@" ? %@", _value];
		}
	return str;
}

- (BOOL) matchesRecord:(ABRecord *) record;
{
	id val;
	if(_children)
		{ // handle conjunction
		NSEnumerator *e=[_children objectEnumerator];
		while((val=[e nextObject]))
			{
			if(_conjunction==kABSearchAnd)
				{
				if(![val matchesRecord:record])
					return NO;  // all must match
				}
			else if(_conjunction==kABSearchOr)
				{
				if([val matchesRecord:record])
					return YES;  // any can match
				}
			return NO;
			}
		return (_conjunction==kABSearchAnd)?YES:NO;
		}
	if(_class)
		{ // class specific
		if([record class] != _class)
			return NO;	// not the specified class
		}
	val=[record valueForProperty:_property];
	if([val isKindOfClass:[ABMultiValue class]])
		{ // fetch value for label
		int i=[val count];
		if(!_label)
			{ // match ANY entry - handling key
			}
		while(--i >= 0)
			{
			if([[val labelAtIndex:i] isEqualToString:_label])
				break;
			}
		if(i<0)
			return NO;	// does not have label!
		val=[val valueAtIndex:i];
		}
	if([val isKindOfClass:[NSDictionary class]])
		val=[val objectForKey:_key];	// go to subdirectory (i.e. street)
	switch(_comparison)
		{
		case kABEqual:
			return [val isEqual:_value];
		case kABNotEqual:
			return ![val isEqual:_value];
		case kABLessThan:
			return [val compare:_value] < NSOrderedSame;
		case kABLessThanOrEqual:
			return [val compare:_value] <= NSOrderedSame;
		case kABGreaterThan:
			return [val compare:_value] > NSOrderedSame;
		case kABGreaterThanOrEqual:
			return [val compare:_value] >= NSOrderedSame;
		case kABEqualCaseInsensitive:
			return [val caseInsensitiveCompare:_value] == NSOrderedSame;
		case kABContainsSubString:
			return [val rangeOfString:_value].location != NSNotFound;
		case kABContainsSubStringCaseInsensitive:
			return [val rangeOfString:_value options:NSCaseInsensitiveSearch].location != NSNotFound;
		case kABPrefixMatch:
			return [val hasPrefix:_value];
		case kABPrefixMatchCaseInsensitive:
			return [val compare:_value options:NSCaseInsensitiveSearch range:NSMakeRange(0, [(NSString *) _value length])] == NSOrderedSame;
		// FIXME: add new comparison methods
		default:
			NSLog(@"matchesRecord with unimplemented comparison %d", _comparison);
			break;
		}
	return NO;
}

@end