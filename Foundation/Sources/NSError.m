//
//  NSError.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Oct 05 2004.
//  Copyright (c) 2004 DSITRI.
//
//    This file is part of the mySTEP Library and is provided
//    under the terms of the GNU Library General Public License.
//

#import "Foundation/Foundation.h"

NSString *NSPOSIXErrorDomain			=@"NSPOSIXErrorDomain";
NSString *NSOSStatusErrorDomain			=@"NSOSStatusErrorDomain";
NSString *NSMachErrorDomain				=@"NSMachErrorDomain";
NSString *NSURLErrorDomain				=@"NSURLErrorDomain";

NSString *NSErrorFailingURLStringKey	=@"NSErrorFailingURLStringKey";
NSString *NSLocalizedDescriptionKey		=@"NSLocalizedDescriptionKey";
NSString *NSUnderlyingErrorKey			=@"NSUnderlyingErrorKey";

NSString *NSLocalizedFailureReasonErrorKey		=@"NSLocalizedFailureReasonErrorKey";
NSString *NSLocalizedRecoverySuggestionErrorKey	=@"NSLocalizedRecoverySuggestionErrorKey";
NSString *NSLocalizedRecoveryOptionsErrorKey	=@"NSLocalizedRecoveryOptionsErrorKey";
NSString *NSRecoveryAttempterErrorKey			=@"NSRecoveryAttempterErrorKey";

@implementation NSError

+ (id) errorWithDomain:(NSString *) domain code:(int) code userInfo:(NSDictionary *) dict;
{
	return [[[self alloc] initWithDomain:domain code:code userInfo:dict] autorelease];
}

- (int) code; { return _code; }
- (NSString *) domain; { return _domain; }
- (NSDictionary *) userInfo; { return _dict; }

- (NSString *) localizedDescription;
{
	NSString *l=[_dict objectForKey:NSLocalizedDescriptionKey];
	if(l)
		return l;
	return [NSString stringWithFormat:@"Error %@ (%d)", _domain, _code];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"Error %@ (%d) - %@", _domain, _code, _dict];
}

- (id) initWithDomain:(NSString *) domain code:(int) code userInfo:(NSDictionary *) dict;
{
	self=[super init];
	if(self)
		{
		_domain=[domain retain];
		_code=code;
		_dict=[dict retain];
		}
	return self;
}

- (void) dealloc;
{
	[_domain release];
	[_dict release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) z;
{
	NSError *c=[isa allocWithZone:z];
	c->_domain=[_domain retain];
	c->_code=_code;
	c->_dict=[_dict retain];
	return c;
}

- (void) encodeWithCoder:(NSCoder*) coder
{ 
	[coder encodeObject:_domain];
	[coder encodeValueOfObjCType:@encode(int) at:&_code];
	[coder encodeObject:_dict];
}

- (id) initWithCoder:(NSCoder*) coder
{
	_domain=[[coder decodeObject] retain];
	[coder decodeValueOfObjCType:@encode(int) at:&_code];
	_dict=[[coder decodeObject] retain];
	return self;
}

- (NSString *) localizedFailureReason; { return [_dict objectForKey:NSLocalizedFailureReasonErrorKey]; }
- (NSArray *) localizedRecoveryOptions; { return [_dict objectForKey:NSLocalizedRecoveryOptionsErrorKey]; }
- (NSString *) localizedRecoverySuggestion; { return [_dict objectForKey:NSLocalizedRecoveryOptionsErrorKey]; }
- (id) recoveryAttempter; { return [_dict objectForKey:NSRecoveryAttempterErrorKey]; }

@end