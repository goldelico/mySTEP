//
//  NSPredicate.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Dec 22 2005.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

// CODE NOT TESTED

#import "Foundation/NSComparisonPredicate.h"
#import "Foundation/NSCompoundPredicate.h"
#import "Foundation/NSExpression.h"
#import "Foundation/NSPredicate.h"

#import "Foundation/NSArray.h"
#import "Foundation/NSDictionary.h"
#import "Foundation/NSEnumerator.h"
#import "Foundation/NSKeyValueCoding.h"
#import "Foundation/NSString.h"
#import "Foundation/NSValue.h"

#import "NSPrivate.h"

@interface _NSTruePredicate : NSPredicate
@end

@interface _NSFalsePredicate : NSPredicate
@end

@interface _NSAndCompoundPredicate : NSCompoundPredicate
{
	@public
	NSArray *_subs;
}
- (id) _initWithSubpredicates:(NSArray *) list;
@end

@interface _NSOrCompoundPredicate : NSCompoundPredicate
{
	@public
	NSArray *_subs;
}
- (id) _initWithSubpredicates:(NSArray *) list;
@end

@interface _NSNotCompoundPredicate : NSCompoundPredicate
{
	@public
	NSPredicate *_sub;
}
- (id) _initWithSubpredicate:(id) predicateOrList;
@end

@interface _NSConstantValueExpression : NSExpression
{
	@public
	id _obj;
}
@end

@interface _NSEvaluatedObjectExpression : NSExpression
@end

@interface _NSVariableExpression : NSExpression
{
	@public
	NSString *_variable;
}
@end

@interface _NSKeyPathExpression : NSExpression
{
	@public
	NSString *_keyPath;
}
@end

@interface _NSFunctionExpression : NSExpression
{
	@public
	NSArray *_args;				// argument expressions
	NSMutableArray *_eargs;		// temporary space for evaluated argument expressions
	unsigned int _argc;
	SEL _selector;
}
@end

@implementation _NSPredicateScanner

+ (_NSPredicateScanner *) _scannerWithString:(NSString *) format args:(NSEnumerator *) args vargs:(va_list) vargs;
{
	return [[[self alloc] _initWithString:format args:args vargs:vargs] autorelease];
}

- (id) _initWithString:(NSString *) format args:(NSEnumerator *) args vargs:(va_list) vargs;
{
	if((self=[super initWithString:format]))
		{
		_args=args;	// not retained
		_vargs=vargs;
		}
	return self;
}

/*
- (void) dealloc
{
	[super dealloc];
}
 */

- (NSEnumerator *) _args; { return _args; }
- (va_list) _vargs; { return _vargs; }

- (BOOL) _scanPredicateKeyword:(NSString *) key;
{
	unsigned loc=[self scanLocation];	// save to back up
	unichar c;
	[self setCaseSensitive:NO];
	if(![self scanString:key intoString:NULL])
		return NO;	// no match
	c=[[self string] characterAtIndex:[self scanLocation]];
	if(![[NSCharacterSet alphanumericCharacterSet] characterIsMember:c])
		return YES;	// ok
	[self setScanLocation:loc];	// back up
	return NO;	// no match
}

@end

@implementation NSPredicate

+ (id) _parseWithScanner:(_NSPredicateScanner *) sc;
{
	NSPredicate *r;
	r=[NSCompoundPredicate _parseAndWithScanner:sc];
	if(![sc isAtEnd])
		[NSException raise:NSInvalidArgumentException format:@"Format string contains extra characters: \"%@\"", [sc string]];
	return r;
}

+ (NSPredicate *) predicateWithFormat:(NSString *) format, ...;
{
	NSPredicate *p;
	va_list va;
    va_start(va, format);
	p=[self predicateWithFormat:format arguments:va];
	va_end(va);
	return p;
}

+ (NSPredicate *) predicateWithFormat:(NSString *) format argumentArray:(NSArray *) args;
{
	return [self _parseWithScanner:[_NSPredicateScanner _scannerWithString:format args:[args objectEnumerator] vargs:NULL]];
}

+ (NSPredicate *) predicateWithFormat:(NSString *) format arguments:(va_list) args;
{
	return [self _parseWithScanner:[_NSPredicateScanner _scannerWithString:format args:nil vargs:args]];
}

+ (NSPredicate *) predicateWithValue:(BOOL) value;
{
	return [[(NSPredicate *) (value?[_NSTruePredicate alloc]:[_NSFalsePredicate alloc]) init] autorelease];
}

// we don't ever instantiate NSPredicate

- (id) copyWithZone:(NSZone *) z; {	return SUBCLASS; }
// - (id) init; { [self release]; return NIMP; }	// might be called for initializing a subclass!

- (BOOL) evaluateWithObject:(id) object; { SUBCLASS; return NO; }

- (BOOL) evaluateWithObject:(id) object substitutionVariables:(NSDictionary *) variables;
{ // substitute variables and evaluate
	// can/should optimize (i.e. parse into internal representation) if possible
	return [[self predicateWithSubstitutionVariables:variables] evaluateWithObject:object];
}

- (NSString *) description; { return [self predicateFormat]; }

- (NSString *) predicateFormat; { return SUBCLASS; }

- (NSPredicate *) predicateWithSubstitutionVariables:(NSDictionary *) variables;
{ // recursively walk through hierarchy, substitute variables and build up a copy
	return [[self copy] autorelease];	
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	[coder encodeObject:[self predicateFormat] forKey:@"Format"];
}

- (id) initWithCoder:(NSCoder *) coder;
{
	NIMP;
	return self;
}

@end

@implementation _NSTruePredicate
- (id) copyWithZone:(NSZone *) z; {	return [self retain]; }
- (BOOL) evaluateWithObject:(id) object; { return YES; }
- (NSString *) predicateFormat; { return @"TRUEPREDICATE"; }
@end

@implementation _NSFalsePredicate
- (id) copyWithZone:(NSZone *) z; {	return [self retain]; }
- (BOOL) evaluateWithObject:(id) object; { return NO; }
- (NSString *) predicateFormat; { return @"FALSEPREDICATE"; }
@end

@implementation NSCompoundPredicate

+ (id) _parseNotWithScanner:(_NSPredicateScanner *) sc;
{
	if([sc scanString:@"(" intoString:NULL])
		{
		NSPredicate *r=[NSPredicate _parseWithScanner:sc];
		if(![sc scanString:@")" intoString:NULL])
			[NSException raise:NSInvalidArgumentException format:@"Missing ) in compound predicate"];
		return r;
		}
	if([sc _scanPredicateKeyword:@"NOT"])
		return [self notPredicateWithSubpredicate:[self _parseNotWithScanner:sc]];	// -> NOT NOT x or NOT (y)
	if([sc _scanPredicateKeyword:@"TRUEPREDICATE"])
		return [NSPredicate predicateWithValue:YES];
	if([sc _scanPredicateKeyword:@"FALSEPREDICATE"])
		return [NSPredicate predicateWithValue:NO];
	return [NSComparisonPredicate _parseComparisonWithScanner:sc];
}

+ (id) _parseOrWithScanner:(_NSPredicateScanner *) sc;
{
	NSPredicate *l=[self _parseNotWithScanner:sc];
	while([sc _scanPredicateKeyword:@"OR"])
		{
		NSPredicate *r=[self _parseNotWithScanner:sc];
		if([r isKindOfClass:[NSCompoundPredicate class]] && [(NSCompoundPredicate *) r compoundPredicateType] == NSOrPredicateType)
			{ // merge
			if([l isKindOfClass:[NSCompoundPredicate class]] && [(NSCompoundPredicate *) l compoundPredicateType] == NSOrPredicateType)
				[(NSMutableArray *) [(NSCompoundPredicate *) l subpredicates] addObjectsFromArray:[(NSCompoundPredicate *) r subpredicates]];
			else
				[(NSMutableArray *) [(NSCompoundPredicate *) r subpredicates] insertObject:l atIndex:0], l=r;
			}
		else if([l isKindOfClass:[NSCompoundPredicate class]] && [(NSCompoundPredicate *) l compoundPredicateType] == NSOrPredicateType)
			[(NSMutableArray *) [(NSCompoundPredicate *) l subpredicates] addObject:r]; // add to l
		else
			l=[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:l, r, nil]];
		}
	return l;
}

+ (id) _parseAndWithScanner:(_NSPredicateScanner *) sc;
{
	NSPredicate *l=[self _parseOrWithScanner:sc];
	while([sc _scanPredicateKeyword:@"AND"])
		{
		NSPredicate *r=[self _parseOrWithScanner:sc];
		if([r isKindOfClass:[NSCompoundPredicate class]] && [(NSCompoundPredicate *) r compoundPredicateType] == NSAndPredicateType)
			{ // merge
			if([l isKindOfClass:[NSCompoundPredicate class]] && [(NSCompoundPredicate *) l compoundPredicateType] == NSAndPredicateType)
				[(NSMutableArray *) [(NSCompoundPredicate *) l subpredicates] addObjectsFromArray:[(NSCompoundPredicate *) r subpredicates]];
			else
				[(NSMutableArray *) [(NSCompoundPredicate *) r subpredicates] insertObject:l atIndex:0], l=r;
			}
		else if([l isKindOfClass:[NSCompoundPredicate class]] &&  [(NSCompoundPredicate *) l compoundPredicateType] == NSAndPredicateType)
			[(NSMutableArray *) [(NSCompoundPredicate *) l subpredicates] addObject:r]; // add to l
		else
			l=[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:l, r, nil]];
		}
	return l;
}

+ (NSPredicate *) andPredicateWithSubpredicates:(NSArray *) list;
{
	return [[[_NSAndCompoundPredicate alloc] _initWithSubpredicates:list] autorelease];
}

+ (NSPredicate *) notPredicateWithSubpredicate:(NSPredicate *) predicate;
{
	return [[[_NSNotCompoundPredicate alloc] _initWithSubpredicate:predicate] autorelease];
}

+ (NSPredicate *) orPredicateWithSubpredicates:(NSArray *) list;
{
	return [[[_NSOrCompoundPredicate alloc] _initWithSubpredicates:list] autorelease];
}

- (NSCompoundPredicateType) compoundPredicateType; { SUBCLASS; return 0; }

- (id) initWithType:(NSCompoundPredicateType) type subpredicates:(NSArray *) list;
{
	[self release];
	switch(type)
		{
		case NSAndPredicateType:
			return [[_NSAndCompoundPredicate alloc] _initWithSubpredicates:list];
		case NSOrPredicateType:
			return [[_NSOrCompoundPredicate alloc] _initWithSubpredicates:list];
		case NSNotPredicateType:
			return [[_NSNotCompoundPredicate alloc] _initWithSubpredicate:list];
		default:
			return nil;
		}
}

- (id) copyWithZone:(NSZone *) z; { return SUBCLASS; }

- (NSArray *) subpredicates; { return SUBCLASS; }

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return self;
}

@end

@implementation _NSAndCompoundPredicate

- (id) _initWithSubpredicates:(NSArray *) list;
{
	NSAssert([list count] > 1, NSInvalidArgumentException);
	if((self=[super init]))
		{
		_subs=[list retain];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) z;
{
	_NSAndCompoundPredicate *c=[isa allocWithZone:z];
	if(c)
		c->_subs=[_subs copyWithZone:z];	// FIXME: must we do a deep copy?
	return c;
}

- (void) dealloc;
{
	[_subs release];
	[super dealloc];
}

- (NSCompoundPredicateType) compoundPredicateType; { return NSAndPredicateType; }

- (BOOL) evaluateWithObject:(id) object;
{
	NSEnumerator *e=[_subs objectEnumerator];
	NSPredicate *p;
	while((p=[e nextObject]))
		if(![p evaluateWithObject:object])
			return NO;	// any NO returns NO
	return YES;	// all are true
}

- (NSString *) predicateFormat;
{
	NSString *fmt=@"";
	NSEnumerator *e=[_subs objectEnumerator];
	NSPredicate *sub;
	unsigned cnt=0;
	while((sub=[e nextObject]))
		{
		// when to add ()? -> if sub is compound and of type "or"
		if(cnt == 0)
			fmt=[sub predicateFormat];	// first
		else
			{
			if(cnt == 1 && [[_subs objectAtIndex:0] isKindOfClass:[NSCompoundPredicate class]] && [(NSCompoundPredicate *) [_subs objectAtIndex:0] compoundPredicateType] == NSOrPredicateType)
				fmt=[NSString stringWithFormat:@"(%@)", fmt];	// we need () around first OR on left side
			if([sub isKindOfClass:[NSCompoundPredicate class]] && [(NSCompoundPredicate *) sub compoundPredicateType] == NSOrPredicateType)
				fmt=[NSString stringWithFormat:@"%@ AND (%@)", fmt, [sub predicateFormat]];	// we need () around right OR
			else
				fmt=[NSString stringWithFormat:@"%@ AND %@", fmt, [sub predicateFormat]];
			}
		cnt++;
		}
	return fmt;
}

- (NSArray *) subpredicates; { return _subs; }

- (NSPredicate *) predicateWithSubstitutionVariables:(NSDictionary *) variables;
{ // recursively walk through hierarchy, substitute variables and build up a copy
	_NSAndCompoundPredicate *copy=[self copy];
	unsigned int i, count=[copy->_subs count];
	for(i=0; i<count; i++)
		[(NSMutableArray *) (copy->_subs) replaceObjectAtIndex:i withObject:[[_subs objectAtIndex:i] predicateWithSubstitutionVariables:variables]];
	return [copy autorelease];	
}

@end

@implementation _NSOrCompoundPredicate

- (id) _initWithSubpredicates:(NSArray *) list;
{
	NSAssert([list count] > 1, NSInvalidArgumentException);
	if((self=[super init]))
		{
		_subs=[list retain];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) z;
{
	_NSOrCompoundPredicate *c=[isa allocWithZone:z];
	if(c)
		c->_subs=[_subs copyWithZone:z];	// FIXME: must we do a deep copy?
	return c;
}

- (void) dealloc;
{
	[_subs release];
	[super dealloc];
}

- (NSCompoundPredicateType) compoundPredicateType; { return NSOrPredicateType; }

- (BOOL) evaluateWithObject:(id) object;
{
	NSEnumerator *e=[_subs objectEnumerator];
	NSPredicate *p;
	while((p=[e nextObject]))
		if([p evaluateWithObject:object])
			return YES;	// any YES returns YES
	return NO;	// none is true
}

- (NSString *) predicateFormat;
{
	NSString *fmt=@"";
	NSEnumerator *e=[_subs objectEnumerator];
	NSPredicate *sub;
	while((sub=[e nextObject]))
		{
		if([fmt length] > 0)
			fmt=[NSString stringWithFormat:@"%@ OR %@", fmt, [sub predicateFormat]];
		else
			fmt=[sub predicateFormat];	// first
		}
	return fmt;
}

- (NSArray *) subpredicates; { return _subs; }

- (NSPredicate *) predicateWithSubstitutionVariables:(NSDictionary *) variables;
{ // recursively walk through hierarchy, substitute variables and build up a copy
	_NSOrCompoundPredicate *copy=[self copy];
	unsigned int i, count=[copy->_subs count];
	for(i=0; i<count; i++)
		[(NSMutableArray *) (copy->_subs) replaceObjectAtIndex:i withObject:[[_subs objectAtIndex:i] predicateWithSubstitutionVariables:variables]];
	return [copy autorelease];	
}

@end

@implementation _NSNotCompoundPredicate

- (id) _initWithSubpredicate:(id) listOrPredicate;
{
	if((self=[super init]))
		{
		if([listOrPredicate isKindOfClass:[NSArray class]])
			_sub=[[listOrPredicate objectAtIndex:0] retain];
		else
			_sub=[listOrPredicate retain];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) z;
{
	_NSNotCompoundPredicate *c=[isa allocWithZone:z];
	if(c)
		c->_sub=[_sub copyWithZone:z];
	return c;
}

- (void) dealloc;
{
	[_sub release];
	[super dealloc];
}

- (NSCompoundPredicateType) compoundPredicateType; { return NSNotPredicateType; }

- (BOOL) evaluateWithObject:(id) object;
{
	return ![_sub evaluateWithObject:object];
}

- (NSString *) predicateFormat;
{
	if([_sub isKindOfClass:[NSCompoundPredicate class]] && [(NSCompoundPredicate *) _sub compoundPredicateType] != NSNotPredicateType)
		return [NSString stringWithFormat:@"NOT(%@)", [_sub predicateFormat]];
	return [NSString stringWithFormat:@"NOT %@", [_sub predicateFormat]];
}

- (NSArray *) subpredicates; { return [NSArray arrayWithObject:_sub]; }

- (NSPredicate *) predicateWithSubstitutionVariables:(NSDictionary *) variables;
{ // recursively walk through hierarchy, substitute variables and build up a copy
	_NSNotCompoundPredicate *copy=[self copy];
	copy->_sub=[_sub predicateWithSubstitutionVariables:variables];
	return [copy autorelease];	
}

@end

@implementation NSComparisonPredicate

+ (id) _parseComparisonWithScanner:(_NSPredicateScanner *) sc;
{ // there must always be a comparison
	NSComparisonPredicateModifier modifier=NSDirectPredicateModifier;
	NSPredicateOperatorType type=0;
	unsigned opts=0;
	NSExpression *left;
	NSPredicate *p;
	BOOL negate=NO;
	if([sc _scanPredicateKeyword:@"ANY"])
		modifier=NSAnyPredicateModifier;
	else if([sc _scanPredicateKeyword:@"ALL"])
		modifier=NSAllPredicateModifier;
	else if([sc _scanPredicateKeyword:@"NONE"])
		modifier=NSAnyPredicateModifier, negate=YES;
	else if([sc _scanPredicateKeyword:@"SOME"])
		modifier=NSAllPredicateModifier, negate=YES;
	left=[NSExpression _parseBinaryExpressionWithScanner:sc];
	if([sc scanString:@"<" intoString:NULL])
		type=NSLessThanPredicateOperatorType;
	else if([sc scanString:@"<=" intoString:NULL])
		type=NSLessThanOrEqualToPredicateOperatorType;
	else if([sc scanString:@">" intoString:NULL])
		type=NSGreaterThanPredicateOperatorType;
	else if([sc scanString:@">=" intoString:NULL])
		type=NSGreaterThanOrEqualToPredicateOperatorType;
	else if([sc scanString:@"=" intoString:NULL])
		type=NSEqualToPredicateOperatorType;
	else if([sc scanString:@"!=" intoString:NULL])
		type=NSNotEqualToPredicateOperatorType;
	else if([sc _scanPredicateKeyword:@"MATCHES"])
		type=NSMatchesPredicateOperatorType;
	else if([sc _scanPredicateKeyword:@"LIKE"])
		type=NSLikePredicateOperatorType;
	else if([sc _scanPredicateKeyword:@"BEGINSWITH"])
		type=NSBeginsWithPredicateOperatorType;
	else if([sc _scanPredicateKeyword:@"ENDSWITH"])
		type=NSEndsWithPredicateOperatorType;
	else if([sc _scanPredicateKeyword:@"IN"])
		type=NSInPredicateOperatorType;
	else
		[NSException raise:NSInvalidArgumentException format:@"Invalid comparison predicate: %@", [[sc string] substringFromIndex:[sc scanLocation]]];
	if([sc scanString:@"[cd]" intoString:NULL])
		opts=NSCaseInsensitivePredicateOption | NSDiacriticInsensitivePredicateOption;
	else if([sc scanString:@"[c]" intoString:NULL])
		opts=NSCaseInsensitivePredicateOption;
	else if([sc scanString:@"[d]" intoString:NULL])
		opts=NSDiacriticInsensitivePredicateOption;
	p=[self predicateWithLeftExpression:left rightExpression:[NSExpression _parseBinaryExpressionWithScanner:sc]
								  modifier:modifier type:type options:opts];
	return negate?[NSCompoundPredicate notPredicateWithSubpredicate:p]:p;
}

+ (NSPredicate *) predicateWithLeftExpression:(NSExpression *) left rightExpression:(NSExpression *) right customSelector:(SEL) sel;
{
	return [[[self alloc] initWithLeftExpression:left rightExpression:right customSelector:sel] autorelease];
}

+ (NSPredicate *) predicateWithLeftExpression:(NSExpression *) left rightExpression:(NSExpression *) right
									 modifier:(NSComparisonPredicateModifier) modifier type:(NSPredicateOperatorType) type options:(unsigned) opts;
{
	return [[[self alloc] initWithLeftExpression:left rightExpression:right
										modifier:modifier type:type options:opts] autorelease];
}

- (NSComparisonPredicateModifier) comparisonPredicateModifier; { return _modifier; }
- (SEL) customSelector; { return _selector; }

- (NSPredicate *) initWithLeftExpression:(NSExpression *) left rightExpression:(NSExpression *) right customSelector:(SEL) sel;
{
	if((self=[super init]))
		{
		_left=[left retain];
		_right=[right retain];
		_selector=sel;
		_type=NSCustomSelectorPredicateOperatorType;
		}
	return self;
}

- (id) initWithLeftExpression:(NSExpression *) left rightExpression:(NSExpression *)right
					 modifier:(NSComparisonPredicateModifier) modifier type:(NSPredicateOperatorType) type options:(unsigned) opts;
{
	if((self=[super init]))
		{
		_left=[left retain];
		_right=[right retain];
		_modifier=modifier;
		_type=type;
		_options=opts;
		}
	return self;
}

- (id) copyWithZone:(NSZone *) z;
{
	NSComparisonPredicate *c=[isa allocWithZone:z];
	if(c)
		{
		c->_left=[_left copyWithZone:z];
		c->_right=[_right copyWithZone:z];
		c->_modifier=_modifier;
		c->_type=_type;
		c->_options=_options;
		c->_selector=_selector;
		}
	return c;
}

- (void) dealloc;
{
	[_left release];
	[_right release];
	[super dealloc];
}

- (NSExpression *) leftExpression; { return _left; }
- (unsigned) options; { return _options; }
- (NSPredicateOperatorType) predicateOperatorType; { return _type; }
- (NSExpression *) rightExpression; { return _right; }

- (NSString *) predicateFormat;
{
	NSString *modi=@"";
	NSString *comp=@"?comparison?";
	NSString *opt=@"";
	switch(_modifier)
		{
		case NSDirectPredicateModifier: break;
		case NSAnyPredicateModifier: modi=@"ANY "; break;
		case NSAllPredicateModifier: modi=@"ALL"; break;
		default: modi=@"?modifier?"; break;
		}
	switch(_type)
		{
		case NSLessThanPredicateOperatorType: comp=@"<"; break;
		case NSLessThanOrEqualToPredicateOperatorType: comp=@"<="; break;
		case NSGreaterThanPredicateOperatorType: comp=@">="; break;
		case NSGreaterThanOrEqualToPredicateOperatorType: comp=@">"; break;
		case NSEqualToPredicateOperatorType: comp=@"="; break;
		case NSNotEqualToPredicateOperatorType: comp=@"!="; break;
		case NSMatchesPredicateOperatorType: comp=@"MATCHES"; break;
		case NSLikePredicateOperatorType: comp=@"LIKE"; break;
		case NSBeginsWithPredicateOperatorType: comp=@"BEGINSWITH"; break;
		case NSEndsWithPredicateOperatorType: comp=@"ENDSWITH"; break;
		case NSInPredicateOperatorType: comp=@"IN"; break;
		case NSContainsPredicateOperatorType: comp=@"CONTAINS"; break;
		case NSBetweenPredicateOperatorType: comp=@"BETWEEN"; break;
		case NSCustomSelectorPredicateOperatorType:
			{
				comp=NSStringFromSelector(_selector);
			}
		}
	switch(_options)
		{
		case NSCaseInsensitivePredicateOption: opt=@"[c]"; break;
		case NSDiacriticInsensitivePredicateOption: opt=@"[d]"; break;
		case NSCaseInsensitivePredicateOption | NSDiacriticInsensitivePredicateOption: opt=@"[cd]"; break;
		default: opt=@"[?options?]"; break;
		}
	return [NSString stringWithFormat:@"%@%@ %@%@ %@", modi, _left, comp, opt, _right];
}

- (NSPredicate *) predicateWithSubstitutionVariables:(NSDictionary *) variables;
{ // recursively walk through hierarchy, substitute variables and build up a copy
	NSComparisonPredicate *copy=[self copy];
	copy->_left=[_left _expressionWithSubstitutionVariables:variables];
	copy->_right=[_right _expressionWithSubstitutionVariables:variables];
	return [copy autorelease];	
}

@end

@implementation NSExpression

+ (id) _parseExpressionWithScanner:(_NSPredicateScanner *) sc;
{
	static NSCharacterSet *_identifier;
	NSString *ident;
	double dbl;
	if([sc scanDouble:&dbl])
		return [NSExpression expressionForConstantValue:[NSNumber numberWithDouble:dbl]];
	// FIXME: handle integer, hex constants, 0x 0o 0b
	if([sc scanString:@"-" intoString:NULL])
		return [NSExpression expressionForFunction:@"_chs" arguments:[NSArray arrayWithObject:[self _parseExpressionWithScanner:sc]]];
	if([sc scanString:@"(" intoString:NULL])
		{
		NSExpression *arg=[self _parseExpressionWithScanner:sc];
		if(![sc scanString:@")" intoString:NULL])
			[NSException raise:NSInvalidArgumentException format:@"Missing ) in expression"];
		return arg;
		}
	if([sc scanString:@"{" intoString:NULL])
		{
		NSMutableArray *a=[NSMutableArray arrayWithCapacity:10];
		if([sc scanString:@"}" intoString:NULL])
			return a;	// empty
		[a addObject:[self _parseExpressionWithScanner:sc]];	// first element
		while([sc scanString:@"," intoString:NULL])
			[a addObject:[self _parseExpressionWithScanner:sc]];	// more elements
		if(![sc scanString:@"}" intoString:NULL])
			[NSException raise:NSInvalidArgumentException format:@"Missing } in aggregate"];
		return a;
		}
	if([sc _scanPredicateKeyword:@"NULL"])
		return [NSExpression expressionForConstantValue:[NSNull null]];
	if([sc _scanPredicateKeyword:@"TRUE"])
		return [NSExpression expressionForConstantValue:[NSNumber numberWithBool:YES]];
	if([sc _scanPredicateKeyword:@"FALSE"])
		return [NSExpression expressionForConstantValue:[NSNumber numberWithBool:NO]];
	if([sc _scanPredicateKeyword:@"SELF"])
		return [NSExpression expressionForEvaluatedObject];
	if([sc scanString:@"$" intoString:NULL])
		{ // variable
		NSExpression *var=[self _parseExpressionWithScanner:sc];
		if(![var keyPath])
			[NSException raise:NSInvalidArgumentException format:@"Invalid variable identifier: %@", var];
		return [NSExpression expressionForVariable:[var keyPath]];
		}
	if([sc _scanPredicateKeyword:@"%K"])
		{
		NSEnumerator *e=[sc _args];
		va_list vargs=[sc _vargs];	// does this work or must we pass a pointer???
		if(e)
			return [NSExpression expressionForKeyPath:[e nextObject]];		// should we even allow to pass in/pass through an NSExpression to %K and convert only NSString objects to keyPaths?
		return [NSExpression expressionForKeyPath:va_arg(vargs, id)];
		}
	if([sc _scanPredicateKeyword:@"%@"])
		{
		NSEnumerator *e=[sc _args];
		va_list vargs=[sc _vargs];	// does this work or must we pass a pointer???
		if(e)
			return [NSExpression expressionForConstantValue:[e nextObject]];
		return [NSExpression expressionForConstantValue:va_arg(vargs, id)];
		}
	// FIXME: other formats
	if([sc scanString:@"\"" intoString:NULL])
		{
		NSString *str=@"string constant";
		return [NSExpression expressionForConstantValue:str];
		}
	if([sc scanString:@"'" intoString:NULL])
		{
		NSString *str=@"string constant";
		return [NSExpression expressionForConstantValue:str];
		}
	if([sc scanString:@"@" intoString:NULL])
		{
		NSExpression *e=[self _parseExpressionWithScanner:sc];
		if(![e keyPath])
			[NSException raise:NSInvalidArgumentException format:@"Invalid keypath identifier: %@", e];
		return [NSExpression expressionForKeyPath:[NSString stringWithFormat:@"@%@", [e keyPath]]];	// prefix with keypath
		}
	[sc scanString:@"#" intoString:NULL];	// skip # as prefix (reserved words)
	if(!_identifier)
		_identifier=[[NSCharacterSet characterSetWithCharactersInString:@"_$abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"] retain];
	if(![sc scanCharactersFromSet:_identifier intoString:&ident])
		[NSException raise:NSInvalidArgumentException format:@"Missing identifier: %@", [[sc string] substringFromIndex:[sc scanLocation]]];
	return [NSExpression expressionForKeyPath:ident];
}

+ (id) _parseFunctionalExpressionWithScanner:(_NSPredicateScanner *) sc;
{
	NSExpression *left=[self _parseExpressionWithScanner:sc];
	while(YES)
		{
		if([sc scanString:@"(" intoString:NULL])
			{ // function - this parser allows for (max)(a, b, c) to be properly recognized and even (%K)(a, b, c) if %K evaluates to "max"
			NSMutableArray *args=[NSMutableArray arrayWithCapacity:5];
			if(![left keyPath])
				[NSException raise:NSInvalidArgumentException format:@"Invalid function identifier: %@", left];
			if(![sc scanString:@")" intoString:NULL])
				{ // any arguments
				[args addObject:[self _parseExpressionWithScanner:sc]];	// first argument
				while([sc scanString:@"," intoString:NULL])
					[args addObject:[self _parseExpressionWithScanner:sc]];	// more arguments
				if(![sc scanString:@")" intoString:NULL])
					[NSException raise:NSInvalidArgumentException format:@"Missing ) in function arguments"];
				}
			left=[NSExpression expressionForFunction:[left keyPath] arguments:args];
			}
		else if([sc scanString:@"[" intoString:NULL])
			{ // index expression
			if([sc _scanPredicateKeyword:@"FIRST"])
				left=[NSExpression expressionForFunction:@"_first" arguments:[NSArray arrayWithObject:[self _parseExpressionWithScanner:sc]]];
			else if([sc _scanPredicateKeyword:@"LAST"])
				left=[NSExpression expressionForFunction:@"_last" arguments:[NSArray arrayWithObject:[self _parseExpressionWithScanner:sc]]];
			else if([sc _scanPredicateKeyword:@"SIZE"])
				left=[NSExpression expressionForFunction:@"count" arguments:[NSArray arrayWithObject:[self _parseExpressionWithScanner:sc]]];
			else
				left=[NSExpression expressionForFunction:@"_index" arguments:[NSArray arrayWithObjects:left, [self _parseExpressionWithScanner:sc], nil]];
			if(![sc scanString:@"]" intoString:NULL])
				[NSException raise:NSInvalidArgumentException format:@"Missing ] in index argument"];
			}
		else if([sc scanString:@"." intoString:NULL])
			{ // keypath - this parser allows for (a).(b.c) to be properly recognized and even %K.((%K)) if the first %K evaluates to "a" and the second %K to "b.c"
			NSExpression *right;
			if(![left keyPath])
				[NSException raise:NSInvalidArgumentException format:@"Invalid left keypath: %@", left];
			right=[self _parseExpressionWithScanner:sc];
			if(![right keyPath])
				[NSException raise:NSInvalidArgumentException format:@"Invalid right keypath: %@", left];
			left=[NSExpression expressionForKeyPath:[NSString stringWithFormat:@"%@.%@", [left keyPath], [right keyPath]]];	// concatenate
			}
		else
			return left;	// done with suffixes
		}
}

+ (id) _parsePowerExpressionWithScanner:(_NSPredicateScanner *) sc;
{
	NSExpression *left=[self _parseFunctionalExpressionWithScanner:sc];
	while(YES)
		{
		NSExpression *right;
		if([sc scanString:@"**" intoString:NULL])
			{
			right=[self _parseFunctionalExpressionWithScanner:sc];
			}
		else
			return left;
		}
}

+ (id) _parseMultiplicationExpressionWithScanner:(_NSPredicateScanner *) sc;
{
	NSExpression *left=[self _parsePowerExpressionWithScanner:sc];
	while(YES)
		{
		NSExpression *right;
		if([sc scanString:@"*" intoString:NULL])
			{
			right=[self _parsePowerExpressionWithScanner:sc];
			}
		else if([sc scanString:@"/" intoString:NULL])
			{
			right=[self _parsePowerExpressionWithScanner:sc];
			}
		else
			return left;
		}
}

+ (id) _parseAdditionExpressionWithScanner:(_NSPredicateScanner *) sc;
{
	NSExpression *left=[self _parseMultiplicationExpressionWithScanner:sc];
	while(YES)
		{
		NSExpression *right;
		if([sc scanString:@"+" intoString:NULL])
			{
			right=[self _parseMultiplicationExpressionWithScanner:sc];
			}
		else if([sc scanString:@"-" intoString:NULL])
			{
			right=[self _parseMultiplicationExpressionWithScanner:sc];
			}
		else
			return left;
		}
}

+ (id) _parseBinaryExpressionWithScanner:(_NSPredicateScanner *) sc;
{
	NSExpression *left=[self _parseAdditionExpressionWithScanner:sc];
	while(YES)
		{
		NSExpression *right;
		if([sc scanString:@":=" intoString:NULL])	// assignment
			{
			// check left to be a variable?
			right=[self _parseAdditionExpressionWithScanner:sc];
			}
		else
			return left;
		}
}

+ (NSExpression *) expressionForAggregate:(NSArray *) elements;
{
	return NIMP;
}

+ (NSExpression *) expressionForConstantValue:(id) obj;
{
	_NSConstantValueExpression *e=[[[_NSConstantValueExpression alloc] init] autorelease];
	e->_obj=[obj retain];
	return e;
}

+ (NSExpression *) expressionForEvaluatedObject;
{
	return [[[_NSEvaluatedObjectExpression alloc] init] autorelease];
}

+ (NSExpression *) expressionForFunction:(NSExpression *) target selectorName:(NSString *) selector arguments:(NSArray *) args;
{
	_NSFunctionExpression *e=[[[_NSFunctionExpression alloc] init] autorelease];
	e->_selector=NSSelectorFromString(selector);
	if(![e respondsToSelector:e->_selector])
		[NSException raise:NSInvalidArgumentException format:@"Unknown selector: %@", selector];
	e->_argc=[args count];
	e->_args=[args retain];
	e->_eargs=[args mutableCopy];	// make space for evaluated arguments - this is not a deep copy!
	return e;
}

+ (NSExpression *) expressionForFunction:(NSString *) name arguments:(NSArray *) args;
{ // translate built-in function
	return [self expressionForFunction:[[_NSEvaluatedObjectExpression new] autorelease] selectorName:[NSString stringWithFormat:@"_eval_%@:context:", name] arguments:args];
}

+ (NSExpression *) expressionForIntersectSet:(NSExpression *) leftExp with:(NSExpression *) rightExp;
{
	return NIMP;
}

+ (NSExpression *) expressionForMinusSet:(NSExpression *) leftExp with:(NSExpression *) rightExp;
{
	return NIMP;
}

+ (NSExpression *) expressionForKeyPath:(NSString *) path;
{
	_NSKeyPathExpression *e=[[[_NSKeyPathExpression alloc] init] autorelease];
	if(![path isKindOfClass:[NSString class]])
		[NSException raise:NSInvalidArgumentException format:@"Keypath is not NSString: %@", path];
	e->_keyPath=[path retain];
	return e;
}

+ (NSExpression *) expressionForSubquery:(NSExpression *) exp usingIteratorVariable:(NSString *) var predicate:(id) pred;
{
	return NIMP;
}

+ (NSExpression *) expressionForUnionSet:(NSExpression *) leftExp with:(NSExpression *) rightExp;
{
	return NIMP;
}

+ (NSExpression *) expressionForVariable:(NSString *) string;
{
	_NSVariableExpression *e=[[[_NSVariableExpression alloc] init] autorelease];
	e->_variable=[string retain];
	return e;
}

- (NSExpression *) _expressionWithSubstitutionVariables:(NSDictionary *) variables;	{ return SUBCLASS; }

- (NSArray *) arguments; { return SUBCLASS; }
- (id) constantValue; { return SUBCLASS; }
- (id) collection; { return SUBCLASS; }
- (NSString *) description; { return SUBCLASS; }
- (NSExpressionType) expressionType; { SUBCLASS; return 0; }
- (id) expressionValueWithObject:(id) object context:(NSMutableDictionary *) context; { return SUBCLASS; }
- (NSString *) function; { return SUBCLASS; }
- (NSString *) keyPath; { return SUBCLASS; }
- (NSExpression *) leftExpression; { return SUBCLASS; }
- (NSExpression *) operand; { return SUBCLASS; }
- (NSPredicate *) predicate; { return SUBCLASS; }
- (NSExpression *) rightExpression; { return SUBCLASS; }
- (NSString *) variable; { return SUBCLASS; }

- (id) initWithExpressionType:(NSExpressionType) type;
{
	[self release];
	switch(type)
		{
		case NSConstantValueExpressionType:
			return [[_NSConstantValueExpression alloc] init];
		case NSEvaluatedObjectExpressionType:
			return [[_NSEvaluatedObjectExpression alloc] init];
		case NSVariableExpressionType:
			return [[_NSVariableExpression alloc] init];
		case NSKeyPathExpressionType:
			return [[_NSKeyPathExpression alloc] init];
		case NSFunctionExpressionType:
			return [[_NSFunctionExpression alloc] init];
		case NSSubqueryExpressionType:
		case NSAggregateExpressionType:
		case NSUnionExpressionType:
		case NSIntersectExpressionType:
		case NSMinusExpressionType:
			NIMP;
		default:
			return nil;
		}
}

- (id) copyWithZone:(NSZone *) z; { return SUBCLASS; }

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return NIMP;
}

@end

@implementation _NSConstantValueExpression

- (NSExpression *) _expressionWithSubstitutionVariables:(NSDictionary *)variables;	{ return self; }	// no substitution
- (NSArray *) arguments; { return nil; }
- (id) constantValue; { return _obj; }
- (NSString *) description; { return _obj; }
- (NSExpressionType) expressionType; { return NSConstantValueExpressionType; }
- (id) expressionValueWithObject:(id) object context:(NSMutableDictionary *) context; { return _obj; }
- (NSString *) function; { return nil; }
- (NSString *) keyPath; { return nil; }
- (NSExpression *) operand; { return nil; }
- (NSString *) variable; { return nil; }

- (id) copyWithZone:(NSZone *) z;
{
	_NSConstantValueExpression *c=[isa allocWithZone:z];
	if(c)
		{
		c->_obj=[_obj copyWithZone:z];
		}
	return c;
}

- (void) dealloc;
{
	[_obj release];
	[super dealloc];
}

@end

@implementation _NSEvaluatedObjectExpression

- (NSExpression *) _expressionWithSubstitutionVariables:(NSDictionary *)variables;	{ return self; }	// no substitution
- (NSArray *) arguments; { return nil; }
- (id) constantValue; { return nil; }
- (NSString *) description; { return @"SELF"; }
- (NSExpressionType) expressionType; { return NSEvaluatedObjectExpressionType; }
- (id) expressionValueWithObject:(id) object context:(NSMutableDictionary *) context; { return object; }
- (NSString *) function; { return nil; }
- (NSString *) keyPath; { return nil; }
- (NSExpression *) operand; { return nil; }
- (NSString *) variable; { return nil; }
- (id) copyWithZone:(NSZone *) z; { return [self retain]; }

@end

@implementation _NSVariableExpression

- (NSExpression *) _expressionWithSubstitutionVariables:(NSDictionary *)variables;
{
	id val=[variables objectForKey:_variable];
	if(!val)
		return self;	// remains a variable
	return [NSExpression expressionForConstantValue:val];	// substitute object provided by dict
}

- (NSArray *) arguments; { return nil; }
- (id) constantValue; { return nil; }
- (NSString *) description; { return [NSString stringWithFormat:@"$%@", _variable]; }
- (NSExpressionType) expressionType; { return NSVariableExpressionType; }
- (id) expressionValueWithObject:(id) object context:(NSMutableDictionary *) context; { return [context objectForKey:_variable]; }
- (NSString *) function; { return nil; }
- (NSString *) keyPath; { return nil; }
- (NSExpression *) operand; { return nil; }
- (NSString *) variable; { return _variable; }

- (id) copyWithZone:(NSZone *) z;
{
	_NSVariableExpression *c=[isa allocWithZone:z];
	if(c)
		{
		c->_variable=[_variable copyWithZone:z];
		}
	return c;
}

- (void) dealloc;
{
	[_variable release];
	[super dealloc];
}

@end

@implementation _NSKeyPathExpression

- (NSExpression *) _expressionWithSubstitutionVariables:(NSDictionary *)variables;	{ return self; }	// no substitution
- (NSArray *) arguments; { return nil; }
- (id) constantValue; { return nil; }
- (NSString *) description; { return _keyPath; }
- (NSExpressionType) expressionType; { return NSKeyPathExpressionType; }
- (id) expressionValueWithObject:(id) object context:(NSMutableDictionary *) context; { return [object valueForKeyPath:_keyPath]; }
- (NSString *) function; { return nil; }
- (NSString *) keyPath; { return _keyPath; }
- (NSExpression *) operand; { return nil; }
- (NSString *) variable; { return nil; }
- (id) copyWithZone:(NSZone *) z; { return [self retain]; }	// since we can't modify the keyPath

- (void) dealloc;
{
	[_keyPath release];
	[super dealloc];
}

@end

@implementation _NSFunctionExpression

- (NSExpression *) _expressionWithSubstitutionVariables:(NSDictionary *)variables;
{ // substitute in expression arguments
	_NSFunctionExpression *copy=[self copy];
	unsigned int i, count=[copy->_args count];
	for(i=0; i<count; i++)
		[(NSMutableArray *) (copy->_args) replaceObjectAtIndex:i withObject:[[_args objectAtIndex:i] _expressionWithSubstitutionVariables:variables]];
	return [copy autorelease];	
}

- (NSArray *) arguments; { return _args; }
- (id) constantValue; { return nil; }

- (NSString *) description;
{
	// FIXME:
	// here we should recognize binary and unary operators and convert back to standard format
	// and add parentheses only if required
	// below, we must expand description of arguments into a comma-separated list
	return [NSString stringWithFormat:@"%@(%@)", [self function], _args];
}

- (NSExpressionType) expressionType; { return NSFunctionExpressionType; }

- (id) expressionValueWithObject:(id) object context:(NSMutableDictionary *) context;
{ // apply method selector
	unsigned int i;
	for(i=0; i<_argc; i++)
		[_eargs replaceObjectAtIndex:i withObject:[[_args objectAtIndex:i] expressionValueWithObject:object context:context]];
	return [self performSelector:_selector withObject:object withObject:context];
}

- (id) _eval__chs:(id) object context:(NSMutableDictionary *) context;
{
	return [NSNumber numberWithInt:-[[_eargs objectAtIndex:0] intValue]];
}

- (id) _eval__first:(id) object context:(NSMutableDictionary *) context;
{
	return [[_eargs objectAtIndex:0] objectAtIndex:0];
}

- (id) _eval__last:(id) object context:(NSMutableDictionary *) context;
{
	return [[_eargs objectAtIndex:0] lastObject];
}

- (id) _eval__index:(id) object context:(NSMutableDictionary *) context;
{
	if([[_eargs objectAtIndex:0] isKindOfClass:[NSDictionary class]])
		return [(NSDictionary *) [_eargs objectAtIndex:0] objectForKey:[_eargs objectAtIndex:1]];
	return [[_eargs objectAtIndex:0] objectAtIndex:[[_eargs objectAtIndex:1] unsignedIntValue]];	// raises exception if invalid
}

- (id) _eval_count:(id) object context:(NSMutableDictionary *) context;
{
	if(_argc != 1)
		;	// error
	return [NSNumber numberWithUnsignedInt:[[_eargs objectAtIndex:0] count]];
}

- (id) _eval_avg:(NSArray *) expressions context:(NSMutableDictionary *) context;
{
	NIMP;
	return [NSNumber numberWithDouble:0.0];
}

- (id) _eval_sum:(NSArray *) expressions context:(NSMutableDictionary *) context;
{
	NIMP;
	return [NSNumber numberWithDouble:0.0];
}

- (id) _eval_min:(NSArray *) expressions context:(NSMutableDictionary *) context;
{
	NIMP;
	return [NSNumber numberWithDouble:0.0];
}

- (id) _eval_max:(NSArray *) expressions context:(NSMutableDictionary *) context;
{
	NIMP;
	return [NSNumber numberWithDouble:0.0];
}

/* add other arithmetic functions here
	average, median, mode, stddev, sqrt, log, ln, exp, floor, ceiling, abs, trunc, random, randomn, now
*/

- (NSString *) function; { return [NSStringFromSelector(_selector) substringFromIndex:6]; }
- (NSString *) keyPath; { return nil; }
- (NSExpression *) operand; { return nil; }
- (NSString *) variable; { return nil; }

- (id) copyWithZone:(NSZone *) z;
{
	_NSFunctionExpression *c=[isa allocWithZone:z];
	if(c)
		{
		c->_args=[_args copyWithZone:z];
		c->_argc=_argc;
		c->_eargs=[c->_args mutableCopy];	// space for evaluated arguments
		c->_selector=_selector;
		}
	return c;
}

- (void) dealloc;
{
	[_args release];
	[_eargs release];
	[super dealloc];
}

@end

@implementation NSArray (NSPredicate)

- (NSArray *) filteredArrayUsingPredicate:(NSPredicate *) predicate;
{
	NSMutableArray *result=[NSMutableArray arrayWithCapacity:[self count]];
	NSEnumerator *e=[self objectEnumerator];
	id object;
	while((object=[e nextObject]))
		{
		if([predicate evaluateWithObject:object])
			[result addObject:object];	// passes filter
		}
	return result;	// we could/should convert to a non-mutable copy
}

@end
