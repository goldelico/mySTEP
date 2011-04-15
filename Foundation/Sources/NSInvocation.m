/* 
   NSInvocation.m

   Object rendering of an Obj-C message (action).

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>

   Author:  Nikolaus Schaller <hns@computer.org> 
			removed mframe and only rely on libobjc and gcc __builtin() and private methods of NSMethodSignature
			(the compiler should hide and manage the processor architecture!).
 
			Sept 2007 - should now be machine independent
 
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

#ifndef __APPLE__

// the following functions convert their argument into a proper retval_t that can be passed back
// they do it by using __builtin_apply() on well known functions which transparently pass back their argument

typedef struct { id many[8]; } __big;		// For returning structures ...etc

static __big return_block (void *data)		{ return *(__big*)data; }

static retval_t apply_block(void *data)
{
	void *args = __builtin_apply_args();
	return __builtin_apply((apply_t)return_block, args, sizeof(data));
}

#endif

@implementation NSInvocation

+ (NSInvocation *) invocationWithMethodSignature:(NSMethodSignature *)aSig
{
#if 0
	NSLog(@"NSInvocation invocationWithMethodSignature:%@ %s", aSig, [aSig _methodType]);
#endif
	return [[[NSInvocation alloc] initWithMethodSignature:aSig] autorelease];
}

- (id) init
{
	NSLog(@"don't call -init on NSInvocation");
	[self release];
	return nil;
}

- (id) initWithMethodSignature:(NSMethodSignature*)aSignature
{ // undocumented in Cocoa but exists
	return [self _initWithMethodSignature:aSignature andArgFrame:NULL];
}

- (void) setTarget:(id)anObject
{
#if 0
	NSLog(@"NSInvocation setTarget: %@", anObject);
#endif
	[self setArgument:&anObject	atIndex:0];	// handles retain/release
#if OLD
	if(_argsRetained)
		{
		[anObject retain];	// in case we do [i setTarget:[i target]]
		[[self target] release];	// release current target
		}
	[_sig _setArgument:&anObject forFrame:_argframe atIndex:0];
#endif
}

- (id) target
{
	id target=nil;	// if _sig is nil
	if(_argframe)
		[_sig _getArgument:&target fromFrame:_argframe atIndex:0];
	return target;
}

- (void) setSelector:(SEL)aSelector
{
	[_sig _setArgument:&aSelector forFrame:_argframe atIndex:1];
}

- (SEL) selector
{
	SEL selector=NULL;	// if _sig is nil
	if(_argframe)
		[_sig _getArgument:&selector fromFrame:_argframe atIndex:1];
	return selector;
}

- (BOOL) argumentsRetained					{ return _argsRetained; }
- (NSMethodSignature *) methodSignature		{ return _sig; }

- (NSString*) description
{
	id target=[self target];
	SEL sel=[self selector];
	return [NSString stringWithFormat:@"%@ %p: selector=%@ target=%@ signature=%s validReturn=%@ argsRetained=%@",
					NSStringFromClass(isa),
					self,
					NSStringFromSelector(sel),
					target,
					_types,
					_validReturn?@"yes":@"no",
					_argsRetained?@"yes":@"no"
					];
}

- (void) _log:(NSString *) str;
{
	int i;
	id target=[self target];
	SEL selector=[self selector];
	NSLog(@"%@ %@ types=%s", str, self, _types);
	if(!_argframe)
		return;
	for(i=0; i<18+[_sig frameLength]/4; i++)
		{ // print stack
		NSString *note=@"";
		if(((void **)_argframe)[i] == target) note=(@"self");
		else if(((void **)_argframe)[i] == selector) note=(@"_cmd");
		else if(((void **)_argframe)[i] == (_argframe+0x28)) note=(@"argp");
		else if(((void **)_argframe)[i] == _argframe) note=(@"link");
		NSLog(@"arg[%2d]:%08x %+3d %3d %08x %12ld %@", i, &(((void **)_argframe)[i]), 4*i, ((char *)&(((void **)_argframe)[i]))-(((char **)_argframe)[0]), ((void **)_argframe)[i], ((void **)_argframe)[i], note);
		}
#if 0
		{
			void *buffer;
			NSLog(@"allocating buffer - len=%d", _maxValueLength);
			buffer=objc_malloc(_maxValueLength);	// make buffer large enough for max value size
			// print argframe
			for(i = _validReturn?-1:0; i < _numArgs; i++)
					{
						const char *type;
						unsigned qual=[_sig _getArgumentQualifierAtIndex:i];
						if(i >= 0)
								{ // normal argument
									type=[_sig _getArgument:buffer fromFrame:_argframe atIndex:i];
								}
						else
								{ // return value
									type=[_sig methodReturnType];
									[self getReturnValue:buffer];
								}
						if(*type == _C_ID)
							NSLog(@"argument %d qual=%d type=%s id=%@ <%p>", i, qual, type, NSStringFromClass([*(id *) buffer class]), *(id *) buffer);
						// NSLog(@"argument %d qual=%d type=%s %p %p", i, qual, type, *(id *) buffer, *(id *) buffer);
						else if(*type == _C_SEL)
							NSLog(@"argument %d qual=%d type=%s SEL=%@ <%p>", i, qual, type, NSStringFromSelector(*(SEL *) buffer), *(SEL *) buffer);
						else
							NSLog(@"argument %d qual=%d type=%s %08x", i, qual, type, *(long *) buffer);
					}
			objc_free(buffer);
		}
#endif
}

- (id) _initWithMethodSignature:(NSMethodSignature*)aSignature andArgFrame:(arglist_t) argFrame
{
#if 1
	NSLog(@"NSInovcation _initWithMethodSignature:%@", aSignature);
#endif
	if(!aSignature)
		{ // missing signature
		[self release];
		return nil;
		}
	if((self=[super init]))
		{
		_sig = [aSignature retain];
		_argframe = [_sig _allocArgFrame:argFrame];
		if(!_argframe)
			{ // could not allocate
#if 1
			NSLog(@"_initWithMethodSignature:andArgFrame: could not allocate _argframe");
#endif
			[self release];
			return nil;
			}
		_argframeismalloc=(_argframe != argFrame);	// was re-allocated if different
		_types=[_sig _methodType];	// get method type
		_numArgs=[aSignature numberOfArguments];
		_rettype=[_sig methodReturnType];
		_returnLength=[_sig methodReturnLength];
		_maxValueLength=MAX(_returnLength, [_sig frameLength]);
		if(_returnLength > 0)
			{
			_retval = objc_calloc(1, _returnLength);
			if(!_retval)
				{ // could not allocate
#if 1
				NSLog(@"_initWithMethodSignature:andArgFrame: could not allocate _retval");
#endif
				[self release];
				return nil;
				}
			_retvalismalloc=YES;	// always...
			}
		}
#if 0
	[self _log:@"_initWithMethodSignature:andArgFrame:"];
#endif
	return self;
}

// NOTE: this approach is not sane since the retval_t from __builtin_apply_args() may be a pointer into a stack frame that becomes invalid if we return apply()
// therefore, this mechanism is not signal()-safe (i.e. don't use NSTask)

#define APPLY(NAME, TYPE)  case NAME: { \
	/*static*/ TYPE return##NAME(TYPE data) { fprintf(stderr, "return"#NAME" %x\n", (unsigned)data); return data; } \
	inline retval_t apply##NAME(TYPE data) { void *args = __builtin_apply_args(); fprintf(stderr, "apply"#NAME" args=%p %x\n", args, (unsigned)data); return __builtin_apply((apply_t)return##NAME, args, sizeof(data)); } \
	fprintf(stderr, "case"#NAME":\n"); \
	return apply##NAME(*(TYPE *) _retval); } 

#define APPLY_VOID(NAME)  case NAME: { \
	/*static*/ void return##NAME(void) { return; } \
	inline retval_t apply##NAME(void) { void *args = __builtin_apply_args(); return __builtin_apply((apply_t)return##NAME, args, 0); } \
	return apply##NAME(); } 


- (retval_t) _returnValue;
{ // encode the return value so that it can be passed back to the libobjc forward:: method
#if 1
	NSLog(@"_returnValue");
	if(_rettype[0] == _C_ID)
			{
				id ret;
				[self getReturnValue:&ret];
				NSLog(@"value = %@", ret);
			}
#endif
	if(_argsRetained)
		[self _releaseArguments];
	if(!_argframeismalloc && _argframe)
		_argframe=NULL;	// deallocate since it was inherited from our caller
	if(!_validReturn && *_rettype != _C_VOID)
			{ // no valid return value
				NSLog(@"warning - no valid return value set");
				[NSException raise: NSInvalidArgumentException format: @"did not 'setReturnValue:' for non-void NSInvocation"];
			}
#ifndef __APPLE__
	switch(_rettype[0])
		{
				APPLY_VOID(_C_VOID);
				APPLY(_C_ID, id);
				APPLY(_C_CLASS, Class);
				APPLY(_C_SEL, SEL);
				APPLY(_C_CHR, char);
				APPLY(_C_UCHR, unsigned char);
				APPLY(_C_SHT, short);
				APPLY(_C_USHT, unsigned short);
				APPLY(_C_INT, int);
				APPLY(_C_UINT, unsigned int);
				APPLY(_C_LNG, long);
				APPLY(_C_ULNG, unsigned long);
				APPLY(_C_LNG_LNG, long long);
				APPLY(_C_ULNG_LNG, unsigned long long);
//				APPLY(_C_FLT, float);
//				APPLY(_C_DBL, double);
				APPLY(_C_ARY_B, char *);
				
			case _C_UNION_B:
			case _C_STRUCT_B:
#if FIXME
			{
				// FIXME
//				memcpy(((void **)_argframe)[2], _retval, _info[0].size);
				if(_info[0].byRef)
					return (retval_t) _retval;	// ???
// #else
				if (_info[0].size > 8)
					// should be dependent on maximum size returned in a register (typically 8 but sometimes 4)
					// can we use sizeof(retval_t) for that purpose???
					return apply_block(*(void**)_retval);

// #endif
			}
#endif
			return apply_block(*(void**)_retval);
		default:	// all others
				NSLog(@"unprocessed type %s for _returnValue", _rettype);
			return (retval_t) _retval;	// uh???
		}
#endif
	return (retval_t) NULL;
}

- (void) dealloc
{
#if 0
	NSLog(@"-[NSInvocation dealloc] %p", self);
	NSLog(@"-dealloc %@", self);
#endif
	if(_argsRetained && _argframe && _sig)
			[self _releaseArguments];
	if(_argframeismalloc && _argframe)
		objc_free(_argframe);	// deallocate incl. struct return buffer
	if(_retvalismalloc && _retval)
		objc_free(_retval);
	[_sig release];
	[super dealloc];
}
													
// Access message elements.

- (void) getArgument:(void*)buffer atIndex:(int)index
{
	if(!_argframe)
		return;
	if((unsigned)index >= _numArgs)
		[NSException raise: NSInvalidArgumentException
					 format: @"bad invocation argument index (%d of %d)", index, _numArgs];
	[_sig _getArgument:buffer fromFrame:_argframe atIndex:index];
}

- (void) getReturnValue:(void *)buffer
{
	if(!_validReturn)
		[NSException raise: NSGenericException
					format: @"getReturnValue with no value set"];
	[_sig _getArgument:buffer fromFrame:_retval atIndex:-1];
#if 0
	if(*_rettype == _C_ID)
		NSLog(@"getReturnValue id=%@", *(id *) buffer);
#endif
}

- (void) setArgument:(void*)buffer atIndex:(int)index
{
	const char *type;
	if(!_argframe)
		return;
	if ((unsigned)index >= _numArgs)
		[NSException raise: NSInvalidArgumentException
							 format: @"bad invocation argument index (%d of %d)", index, _numArgs];
	type=[_sig getArgumentTypeAtIndex:index];
	if(*type == _C_CHARPTR && _argsRetained)
		{ // free old, store a copy of new
		char *oldstr;
		char *newstr = *(char**)buffer;
		[_sig _getArgument:&oldstr fromFrame:_argframe atIndex:index];	// get previous
		if(newstr == NULL)
			[_sig _setArgument:buffer forFrame:_argframe atIndex:index];
		else
			{
			char *tmp = objc_malloc(strlen(newstr)+1);
			strcpy(tmp, newstr);
			[_sig _setArgument:tmp forFrame:_argframe atIndex:index];
			}
		if(oldstr != NULL)
			objc_free(oldstr);
		}
	else if(*type == _C_ID && _argsRetained)
		{ // release/retain
		id old=nil;
		[_sig _getArgument:&old fromFrame:_argframe atIndex:index];	// get previous
		[_sig _setArgument:buffer forFrame:_argframe atIndex:index];
		[*(id*)buffer retain];	// retain new
		[old release];	// release old
#if 0
			NSLog(@"retained arg %@", *(id*)buffer);
			NSLog(@"released arg %@", old);
#endif
		}
	else
		[_sig _setArgument:buffer forFrame:_argframe atIndex:index];
}

- (void) setReturnValue:(void*)buffer
{
#if 0
	NSLog(@"setReturnValue buffer=%08x *buffer=%08x", buffer, *(long *) buffer);
	if(*_rettype == _C_ID)
		NSLog(@"              id=%@", *(id *) buffer);
	NSLog(@"_retval=%08x", _retval);
#endif
	[_sig _setArgument:buffer forFrame:_retval atIndex:-1];
#if 0
	if(*_rettype == _C_ID)
		NSLog(@"              id=%@", *(id *) _retval);
#endif
	_validReturn = YES;
}

- (void) retainArguments
{
	int	i;
	if(_argsRetained || !_argframe)
		return;	// already retained or no need to do so
	_argsRetained = YES;
#if 0
	NSLog(@"retaining arguments %@", self);
#endif
	for(i = 0; i < _numArgs; i++)
			{
				const char *type=[_sig getArgumentTypeAtIndex:i];
				switch(*type)
					{
						case _C_CHARPTR:
						{ // store a copy
							char *str=NULL;
							[_sig _getArgument:&str fromFrame:_argframe atIndex:i];
							if(str != NULL)
									{
										char *tmp = objc_malloc(strlen(str)+1);
										strcpy(tmp, str);
										[_sig _setArgument:tmp forFrame:_argframe atIndex:i];
									}
							break;
						}
						case _C_ID:
						{ // retain object
							id obj;
							[_sig _getArgument:&obj fromFrame:_argframe atIndex:i];
#if 1
							NSLog(@"retaining arg %p", obj);
							NSLog(@"retaining arg %@", obj);
#endif
							[obj retain];
							break;
						}
						default:
							break;
					}
			}
}

- (void) _releaseReturnValue;
{ // no longer needed so that we can reuse an invocation
	_validReturn=NO;	// invalidate - so that initWithCoder properly handles requests&responses
}

- (void) _releaseArguments
{
	int	i;
	if(!_argsRetained || !_argframe)
		return;	// already released or no need to do so
	_argsRetained = NO;
#if 0
	NSLog(@"releasing arguments %@", self);
#endif
	for(i = 0; i < _numArgs; i++)
			{
				const char *type=[_sig getArgumentTypeAtIndex:i];
				if(*type == _C_CHARPTR)
						{ // release the copy
							char *str;
							[_sig _getArgument:&str fromFrame:_argframe atIndex:i];
							if(str != NULL)
								objc_free(str);	// ??? immediately, or should we put it into the ARP?
						}
				else if(*type == _C_ID)
						{ // release object
							id obj;
							[_sig _getArgument:&obj fromFrame:_argframe atIndex:i];
#if 0
							NSLog(@"release arg %@", obj);
#endif
							[obj release];
						}
			}
}

- (void) invokeWithTarget:(id)anObject
{
	[_sig _setArgument:&anObject forFrame:_argframe atIndex:0];
	[self invoke];
}

- (void) invoke
{
#ifndef __APPLE__
	IMP imp;			// method implementation pointer
	id target;
	SEL selector;
	if(!_argframe)
			{
				NSLog(@"NSInvocation -invoke without argframe:%@", self);
				return;
			}
	[_sig _getArgument:&target fromFrame:_argframe atIndex:0];
#if 1
	NSLog(@"NSInvocation -invoke withTarget:%@", target);
#endif
	if(target == nil)			// A message to a nil object returns nil
		{
		memset(_retval, 0, [_sig methodReturnLength]);		// wipe out return value
		_validReturn = YES;
		return;
		}

	[_sig _getArgument:&selector fromFrame:_argframe atIndex:1];
	NSAssert(selector != NULL, @"you must set the selector before invoking");

	imp = method_get_imp(object_is_instance(target) ?
	      class_get_instance_method(((struct objc_class *) target )->class_pointer, selector)
	    : class_get_class_method(((struct objc_class *) target )->class_pointer, selector));
	
	if(imp == NULL)
		{ // If fast lookup failed, we may be forwarding or something ...
#if 1
		NSLog(@"invoke: forwarding or something ...");
#endif
		imp = objc_msg_lookup(target, selector);
		}
#if 1
	[self _log:@"invoke"];
//	*((long *)1)=0;
#endif
	_validReturn=[_sig _call:imp frame:_argframe retbuf:_retval];	// call
#endif
}

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder { return self; }	// don't replace by another proxy, i.e. encode bycopy

/*
 * encoding of in/out/inout paramters is based on the _validReturn flag
 *
 * if validReturn, we assume we are a response and encode the result, 'out' and 'inout' paramters only
 * if no validReturn, we assume a request and encode no result, and 'in' and 'inout' parameters only
 */

- (void) encodeWithCoder:(NSCoder*) aCoder
{ // NOTE: only supports NSPortCoder
	void *buffer=objc_malloc(_maxValueLength);	// make buffer large enough for max value size
	int i;
#if 0
	[self _log:@"encodeWithCoder:"];
#endif
#if 0
	NSLog(@"buffer[%d]=%p", _maxValueLength), buffer);
#endif
	if(!buffer)
		return;
	[aCoder encodeValueOfObjCType:@encode(char *) at:&_types];
	[aCoder encodeValueOfObjCType:@encode(BOOL) at:&_validReturn];
	for(i = _validReturn?-1:0; i < _numArgs; i++)
		{ // handle all arguments (and return value)
		const char *type;
		unsigned qual=[_sig _getArgumentQualifierAtIndex:i];
		if(i >= 0)
			{ // normal argument
			type=[_sig _getArgument:buffer fromFrame:_argframe atIndex:i];
			}
		else
			{ // return value
			type=[_sig methodReturnType];
			if(*type == _C_VOID)
				continue;	// don't encode void return value
			[self getReturnValue:buffer];
			}
#if 0
		NSLog(@"NSInvocation encode arg %d qual %x type %s", i, qual, type);
#endif
		if(_validReturn && (qual & _F_IN) != 0)
			continue;	// don't encode in responses
		if(!_validReturn && (qual & _F_OUT) != 0)
			continue;	// don't encode in requests
#if 0
		NSLog(@"buffer=%p", buffer);
		NSLog(@"long buffer[0]=%x", *(long *) buffer);
#endif
		if(*type == _C_ID)
			{
			if((qual & _F_BYCOPY) != 0)
				[aCoder encodeBycopyObject:*(id *)buffer];
			else if((qual & _F_BYREF) != 0)
				[aCoder encodeByrefObject:*(id *)buffer];
			else
				[aCoder encodeObject:*(id *)buffer];
			}
		else
			[aCoder encodeValueOfObjCType:type at:buffer];	// always encode bycopy
		}
	objc_free(buffer);
}

- (id) initWithCoder:(NSCoder*)aCoder
{ // this is special behaviour: we can update an existing (otherwise initialized) NSInvocation by decoding return value and arguments
	const char *types;
	void *buffer;
	int i;
#if 1
	NSLog(@"%@ initWithCoder: %@", self, aCoder);
#endif
	[aCoder decodeValueOfObjCType:@encode(char*) at:&types];
#if 1
	NSLog(@"  decoded type=%s", types);
#endif
	[aCoder decodeValueOfObjCType:@encode(BOOL) at:&_validReturn];
#if 1
	NSLog(@"  validReturn=%@", _validReturn?@"YES":@"NO");
#endif
	if(!_sig || !_validReturn)
		{ // assume we have to decode a Request
		self=[self _initWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:types] andArgFrame:NULL];
		}
	else
		{ // a response - assume we already have been initialized for _sig
			NSAssert(strcmp(types, _types) == 0, @"received different signature");		// should be the same as we have requested
#if 1
		NSLog(@"  existing type=%s", _types);
#endif
		}
#if 1
	NSLog(@"  _sig=%@", _sig);
	NSLog(@"  _maxValueLength=%d", _maxValueLength);
#endif
	buffer=objc_malloc(_maxValueLength);	// make buffer large enough for max value size
	for(i = _validReturn?-1:0; i < _numArgs; i++)
		{
		unsigned qual=[_sig _getArgumentQualifierAtIndex:i];
		const char *type;
		if(i >= 0)
			{ // normal argument
			type=[_sig getArgumentTypeAtIndex:i];
			}
		else
			{ // return value
			type=_rettype;
			if(*type == _C_VOID)
				continue;	// we didn't encode a void return value
			}
#if 1
		NSLog(@"  decode arg %d type %s", i, type);
#endif
		if(_validReturn && (qual & _F_IN) != 0)
			continue;	// wasn't encoded in response
		if(!_validReturn && (qual & _F_OUT) != 0)
			continue;	// wasn't encoded in request
		[aCoder decodeValueOfObjCType:type at:buffer];
		if(i < 0)
			[self setReturnValue:buffer];
		else
			[self setArgument:buffer atIndex:i];
#if 1
		if(*type == _C_ID) NSLog(@"did set argument %d: id=%@ <%p>", i, NSStringFromClass([*(id *) buffer class]), *(id *) buffer);
		if(*type == _C_SEL) NSLog(@"did set argument %d: SEL=%@", i, NSStringFromSelector(*(SEL *) buffer));
#endif
#if 1
			[self _log:@"initWithCoder:"];
#endif
		}
	objc_free(buffer);
	return self;
}

@end  /* NSInvocation */
