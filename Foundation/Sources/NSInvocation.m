/* 
 NSInvocation.m
 
 Object rendering of an Obj-C message (action).
 
 Copyright (C) 1998 Free Software Foundation, Inc.
 
 Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
 
 Author:  Nikolaus Schaller <hns@computer.org> 
 removed mframe so that we only rely on libobjc
 plus some private methods of NSMethodSignature that wrap __builtin_apply()
 (the compiler should hide and manage the processor architecture as good as possible!).
 
 Sept 2007		- should now be machine independent
 2008 - 2014	- further extensions and improvements
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 
 Known Bugs:
 * it is not tested if we properly encode C-Strings etc. especially as bycopy inout...
 
 */ 

#import <Foundation/NSException.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSMethodSignature.h>
#import "NSPrivate.h"

@implementation NSInvocation

+ (NSInvocation *) invocationWithMethodSignature:(NSMethodSignature *) aSig
{
#if 0
	NSLog(@"NSInvocation invocationWithMethodSignature:%@ %s", aSig, [aSig _methodTypes]);
#endif
	return [[[NSInvocation alloc] initWithMethodSignature:aSig] autorelease];
}

- (id) init
{
//	NSLog(@"don't call -init on NSInvocation");
	[self release];
	return nil;
}

- (void) setTarget:(id) anObject
{
#if 0
	NSLog(@"NSInvocation setTarget: %@", anObject);
#endif
	[_sig _setArgument:&anObject forFrame:_argframe atIndex:0 retainMode:_argsRetained];
}

- (id) target
{
	id target=nil;	// if _sig is nil (which should not happen)
	[_sig _getArgument:&target fromFrame:_argframe atIndex:0];
	return target;
}

- (void) setSelector:(SEL) aSelector
{
#if 0
	NSLog(@"NSInvocation setSelector: %@", NSStringFromSelector(aSelector));
#endif
	[_sig _setArgument:&aSelector forFrame:_argframe atIndex:1 retainMode:_argsRetained];
}

- (SEL) selector
{
	SEL selector=NULL;	// if _sig is nil
	[_sig _getArgument:&selector fromFrame:_argframe atIndex:1];
	return selector;
}

- (BOOL) argumentsRetained					{ return _argsRetained; }
- (NSMethodSignature *) methodSignature		{ return _sig; }

- (NSString*) description
{
	id target=[self target];
	SEL sel=[self selector];
#if 0	// this would lead to a recursive NSLog!
	NSLog(@"target=%p", target);
	NSLog(@"target=%@", target);
	NSLog(@"sel=%p", sel);
	NSLog(@"sel=%@", NSStringFromSelector(sel));
#endif
	return [NSString stringWithFormat:@"%@ %p: selector=%@ target=%@ signature=%s validReturn=%@ argsRetained=%@ numargs=%u sig=%@",
			NSStringFromClass([self class]),
			self,
			NSStringFromSelector(sel),
			target==self?@"(self)":target,
			_types,
			_validReturn?@"yes":@"no",
			_argsRetained?@"yes":@"no",
			[_sig numberOfArguments],
			_sig
			];
}

- (void) dealloc
{
#if 0
	NSLog(@"-[NSInvocation dealloc] %p", self);
	NSLog(@"-dealloc %@", self);
#endif
	if(_argsRetained && _argframe && _sig)
		[self _releaseArguments];
	if(_argframe)
		objc_free(_argframe);	// deallocate buffer
	[_sig release];
	[super dealloc];
}

// Access message elements.

- (void) getArgument:(void*) buffer atIndex:(NSInteger) index
{
#if 0
	NSLog(@"invocation argument index (%d of %d)", index, _numArgs);
#endif
	if(index < -1 || index >= _numArgs)
		[NSException raise: NSInvalidArgumentException
					format: @"bad invocation argument index (%d of %d)", index, _numArgs];
	if(!buffer)
		[NSException raise: NSInvalidArgumentException format: @"NULL buffer"];
	[_sig _getArgument:buffer fromFrame:_argframe atIndex:index];
}

- (void) getReturnValue:(void *) buffer
{
	[_sig _getArgument:buffer fromFrame:_argframe atIndex:-1];
#if 0
	if(_validReturn && *_rettype == _C_ID)
		NSLog(@"getReturnValue id=%@", *(id *) buffer);
#endif		
}

- (void) setArgument:(void*) buffer atIndex:(NSInteger) index
{
#if 0
	NSLog(@"setArgument: %p atIndex:%d", buffer, index);
#endif
	if (index < -1 || index >= _numArgs)
		[NSException raise: NSInvalidArgumentException
					format: @"bad invocation argument index (%d of %d)", index, _numArgs];
	if(!buffer)
		[NSException raise: NSInvalidArgumentException format: @"NULL buffer"];
#if 0
	NSLog(@"argtype = %s", type);
#endif
	[_sig _setArgument:buffer forFrame:_argframe atIndex:index retainMode:_argsRetained];
}

- (void) setReturnValue:(void *) buffer
{
#if 0
	NSLog(@"setReturnValue: _argframe=%p", _argframe);
	if(*_rettype == _C_ID)
		NSLog(@"  object id=%p %@", *(id *) buffer, *(id *) buffer);
	NSLog(@"a");
#endif
	[_sig _setArgument:buffer forFrame:_argframe atIndex:-1 retainMode:_argsRetained];
	NSLog(@"b");
	_validReturn = YES;
}

- (void) retainArguments
{
	if(!_argsRetained)
		{
		int	i;
#if 0
		NSLog(@"retaining arguments %@", self);
#endif
		for(i = _validReturn?-1:0; i < _numArgs; i++)
			[_sig _setArgument:NULL forFrame:_argframe atIndex:i retainMode:_INVOCATION_ARGUMENT_RETAIN];
		_argsRetained = YES;
		}
}

- (void) invokeWithTarget:(id) anObject
{
	[_sig _setArgument:&anObject forFrame:_argframe atIndex:0 retainMode:_argsRetained];
	[self invoke];
}

- (void) invoke
{
	IMP imp;			// method implementation pointer
	id target;
	SEL selector;
	[_sig _getArgument:&target fromFrame:_argframe atIndex:0];
#if 0
	NSLog(@"-[NSInvocation invoke]: target=%p %@", target, target);
#endif
	if(target == nil)
		{ // a message to a nil object returns nil or 0 or 0.0 etc.
		[_sig _setArgument:NULL forFrame:_argframe atIndex:-1 retainMode:_argsRetained];	// wipe out return value
		_validReturn = YES;
		return;
		}
	[_sig _getArgument:&selector fromFrame:_argframe atIndex:1];
	if(!selector)
		[NSException raise:NSInvalidArgumentException format:@"-[NSInvocation invoke]: can't invoke NULL selector: %@", self];
#if 0
	NSLog(@"-[NSInvocation invoke]: selector=%@", NSStringFromSelector(selector));
#endif

	imp = class_getMethodImplementation(object_getClass(target), selector);
	// FIXME: do we still need this?
	if(!imp)
		{ // If fast lookup failed, we may be forwarding or something ...
#if 1
			NSLog(@"invoke: forwarding or something ...");
#endif
#ifndef __APPLE__
		imp = objc_msg_lookup(target, selector);
#endif
		}
	if(!imp)
		{ // still undefined
			[NSException raise:NSInvalidArgumentException format:@"-[NSInvocation invoke]: can't invoke: %@", self];
		}
#if 0
	NSLog(@"imp = %p", imp);
#endif
#if 0
	[self _log:@"stack before _call"];
	//	*((long *)1)=0;
#endif
	_validReturn=[_sig _call:imp frame:_argframe];	// call
	if(!_validReturn)
		[NSException raise:NSInvalidArgumentException format:@"-[NSInvocation invoke]: failed to invoke: %@", self];
#if 0
	[self _log:@"stack after _call"];
	//	*((long *)1)=0;
#endif
}

- (void) encodeWithCoder:(NSCoder*) aCoder
{ // NOTE: only supports NSPortCoder
	NSMethodSignature *sig=[self methodSignature];
	unsigned char len=[sig methodReturnLength];	// this should be the length really allocated
	void *buffer=objc_malloc(MAX([sig frameLength], len));	// allocate a buffer
	NSUInteger cnt=[sig numberOfArguments];	// encode arguments (incl. target&selector)
	// if we move this to NSInvocation we don't even need the private methods
	const char *type=[[sig _typeString] UTF8String];	// private method (of Cocoa???) to get the type string
	//	const char *type=[sig _methodTypes];	// would be a little faster
	id target=[self target];
	SEL selector=[self selector];
	int j;
	[aCoder encodeValueOfObjCType:@encode(id) at:&target];
	[aCoder encodeValueOfObjCType:@encode(int) at:&cnt];	// argument count
	[aCoder encodeValueOfObjCType:@encode(SEL) at:&selector];
#if 0
	type=translateSignatureToNetwork(type);
#endif
	[aCoder encodeValueOfObjCType:@encode(char *) at:&type];	// method type
	if(_validReturn)
		[_sig _getArgument:buffer fromFrame:_argframe atIndex:-1];
	else
		{
		NSLog(@"encodeInvocation has no return value to encode");	// e.g. if [i invoke] did result in an exception!
		len=1;	// this may also be some default value
		*(char *) buffer=[sig methodReturnType][0];	// first character of return type
		}
	[aCoder encodeValueOfObjCType:@encode(unsigned char) at:&len];
	[aCoder encodeArrayOfObjCType:@encode(char) count:len at:buffer];	// encode the bytes of the return value (not the object/type which can be done by encodeReturnValue)
	for(j=2; j<cnt; j++)
		{ // encode arguments
			[self getArgument:buffer atIndex:j];	// get value
			[aCoder encodeValueOfObjCType:[sig getArgumentTypeAtIndex:j] at:buffer];
		}
	objc_free(buffer);
}

- (id) initWithCoder:(NSCoder*) aCoder
{
	// FIXME: is not correctly implemented (at least some note in NSPortCoder says so)
	
	NSMethodSignature *sig;
	void *buffer;
	char *type;
	int cnt;	// number of arguments (incl. target&selector)
	unsigned char len;
	id target;
	SEL selector;
	int j;
	return NIMP;
	[aCoder decodeValueOfObjCType:@encode(id) at:&target];
	[aCoder decodeValueOfObjCType:@encode(int) at:&cnt];
	[aCoder decodeValueOfObjCType:@encode(SEL) at:&selector];
	[aCoder decodeValueOfObjCType:@encode(char *) at:&type];
	[aCoder decodeValueOfObjCType:@encode(unsigned char) at:&len];	// should set the buffer size internal to the NSInvocation
#if 0
	type=translateSignatureFromNetwork(type);
#endif
	sig=[NSMethodSignature signatureWithObjCTypes:type];
	buffer=objc_malloc(MAX([sig frameLength], len));	// allocate a buffer for return value and arguments
	self=[self _initWithMethodSignature:sig argFrame:[sig _allocArgFrame]];
	if(!self)
		return nil;	// failed
	// FIXME: raise exception?
	if(cnt != [sig numberOfArguments])
		NSLog(@"mismatch in number of arguments");
	[aCoder decodeArrayOfObjCType:@encode(char) count:len at:buffer];	// decode byte pattern for return value
	// FIXME: how can we decode _validReturn?
	[self setReturnValue:buffer];	// set value
	[self setTarget:target];
	[self setSelector:selector];
	for(j=2; j<cnt; j++)
		{ // decode arguments
			[aCoder decodeValueOfObjCType:[sig getArgumentTypeAtIndex:j] at:buffer];
			// FIXME: decodeValueOfObjCType returns (id) objects that are retained!
			[self setArgument:buffer atIndex:j];	// set value
		}
	objc_free(buffer);
	return self;
}

@end  /* NSInvocation */

@implementation NSInvocation (NSUndocumented)

- (id) initWithMethodSignature:(NSMethodSignature*) aSignature
{ // undocumented in Cocoa but exists in some releases
	return [self _initWithMethodSignature:aSignature argFrame:[aSignature _allocArgFrame]];
}

- (id) copyWithZone:(NSZone *) z;
{
	NIMP;
	return nil;
}

- (void) invokeSuper;
{
	NIMP;
}

- (void) _addAttachedObject:(id) obj
{
	// does this handle the Imports for DO?
	// and is this additionally encoded by the PortCoder?
	NIMP;
}

@end

@implementation NSInvocation (NSPrivate)

- (void) _log:(NSString *) str;
{
	id target=[self target];
	SEL selector=[self selector];
	NSLog(@"%@ types=%s argframe=%p", str, _types, _argframe);
	if(!_argframe)
		return;
	[_sig _logFrame:_argframe target:target selector:selector];
}

// this is called to initialize an NSInvocation with a malloc'ed argframe

- (id) _initWithMethodSignature:(NSMethodSignature *) aSignature argFrame:(void *) argframe
{
#if 0
	NSLog(@"NSInovcation _initWithMethodSignature:%@ retp:%p args:p", aSignature, retp, args);
#endif
	if(!aSignature)
		{ // missing signature
			[self release];
			[NSException raise:NSInvalidArgumentException format:@"NSInvocation needs a method signature"];
		}
	if(!argframe)
		{ // could not allocate
#if 0
			NSLog(@"_initWithMethodSignature: missing argframe");
#endif
			[self release];
			[NSException raise:NSInvalidArgumentException format:@"NSInvocation needs an argframe"];
		}
	if((self=[super init]))
		{
		_sig=[aSignature retain];
		_argframe=argframe;
		_numArgs=[aSignature numberOfArguments];
		_rettype=[_sig methodReturnType];
		// FIXME: isn't used
		_returnLength=[_sig methodReturnLength];
		// FIXME: used only for debugging
		_types=[_sig _methodTypes];	// get method type
#if 0
		NSLog(@"-[NSInvocation(%p) _initWithMethodSignature:%s] successfull", self, _types, argFrame);
		NSLog(@"self target: %@", [self target]);
#endif
		}
	return self;
}

- (void) _releaseArguments
{ // used by -dealloc
	if(_argsRetained && _argframe)
		{
		int	i;
#if 0
		NSLog(@"releasing arguments %@", self);
#endif
		for(i = 0; i < _numArgs; i++)
			[_sig _setArgument:NULL forFrame:_argframe atIndex:i retainMode:_INVOCATION_ARGUMENT_RELEASE];		
		_argsRetained = NO;
		}
}

@end
