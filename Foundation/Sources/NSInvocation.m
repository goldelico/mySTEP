/* 
   NSInvocation.m

   Object rendering of an Obj-C message (action).

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>

   Author:  Nikolaus Schaller <hns@computer.org> 
			removed mframe and only rely on libobjc and gcc __builtin and private methods of NSMethodSignature
			(the compiler should hide and manage the processor architecture!).
 
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

// FIXME: get rid of this dependency:
#include "mframe.h"	// this should be the only location to use outside mframe.m and NSMethodSignature.h

#define dump(args, len, X) \
{ \
	int i; \
	NSLog(@"%@ dumping %@ - sig=%s", self, NSStringFromSelector(_cmd), [[self methodSignatureForSelector:_cmd] _methodType]); \
	for(i=0; i<len/4; i++) \
		{ \
		NSString *note=@""; \
		if(((void **)args)[i] == self) note=(@"self"); \
		if(((void **)args)[i] == _cmd) note=(@"_cmd"); \
		if(((void **)args)[i] == args) note=(@"args"); \
		if(((void **)args)[0] == &((void **)args)[i]) note=(@"<- arg[0]"); \
		X; \
		NSLog(@"arg[%2d]:%08x %08x %@", i, &(((void **)args)[i]), ((void **)args)[i], note); \
		} \
}

#ifndef __APPLE__

// the following functions convert their argument into a proper retval_t that can be passed back
// they do it by using __builtin_apply() on well known functions which transparently pass back their argument

typedef struct { id many[8]; } __big;		// For returning structures ...etc

static __big return_block (void *data)		{ return *(__big*)data; }
static void return_void (void)				{ return; }       // void type
static char return_char (char data)			{ NSLog(@"data=%d", data); return data; }  // char types
static short return_short (short data)		{ return data; }  // short types
static int return_int (int data)			{ return data; }  // int types
static long return_long (long data)			{ return data; }  // long types
static long long return_longlong (long long data)		{ return data; }  // long long types
static float return_float (float data)		{ return data; }  // float
static double return_double (double data)	{ return data; }  // double
static void *return_pointer (void *data)	{ return data; }  // pointer

#define APPLY(TYPE) static short return_#TYPE (TYPE data) { return data; } \
		static retval_t apply_##TYPE(void *data) \
		{ void *args = __builtin_apply_args(); return __builtin_apply((apply_t)return_block, args, sizeof(TYPE)); }

// APPLY(void);
// APPLY(char);
// etc...

static retval_t apply_block(void *data)
{
	void *args = __builtin_apply_args();
	return __builtin_apply((apply_t)return_block, args, sizeof(void *));
}

static retval_t apply_void(void)
{
	void *args = __builtin_apply_args();
	return __builtin_apply((apply_t)return_void, args, 8);	// just be safe with "8"
}

static retval_t apply_char(char data)
{
	void *args = __builtin_apply_args();
	NSLog(@"data=%d", data);
	return __builtin_apply((apply_t)return_char, args, sizeof(data));	// this calls return_char(data)
}

static retval_t apply_short(short data)
{
	void *args = __builtin_apply_args();
	return __builtin_apply((apply_t)return_short, args, sizeof(data));
}

static retval_t apply_int(int data)
{
	void *args = __builtin_apply_args();
	return __builtin_apply((apply_t)return_int, args, sizeof(data));
}

static retval_t apply_long(long data)
{
	void *args = __builtin_apply_args();
	return __builtin_apply((apply_t)return_long, args, sizeof(data));
}

static retval_t apply_longlong(long long data)
{
	void *args = __builtin_apply_args();
	return __builtin_apply((apply_t)return_longlong, args, sizeof(data));
}

static retval_t apply_float(float data)
{
	void *args = __builtin_apply_args();
	return __builtin_apply((apply_t)return_float, args, sizeof(data));
}

static retval_t apply_double(double data)
{
	void *args = __builtin_apply_args();
	return __builtin_apply((apply_t)return_double, args, sizeof(data));
}

static retval_t apply_pointer(void *data)
{
	void *args = __builtin_apply_args();
	return __builtin_apply((apply_t)return_pointer, args, sizeof(data));
}

// static /*inline*/ id retframe_id(void *f) { __builtin_return(f); }

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
{ // undocumented in Cocoa	
	return [self _initWithMethodSignature:aSignature andArgFrame:NULL];
}

- (void) setTarget:(id)anObject
{
#if 0
	NSLog(@"NSInvocation setTarget: %@", anObject);
#endif
	if(_argsRetained)
		{
		[anObject retain];	// in case we do [i setTarget:[i target]]
		[[self target] release];	// release current target
		}
	[_sig _setArgument:&anObject forFrame:_argframe atIndex:0];
#if 0
	dump(_argframe, [_sig frameLength], );
#endif
}

- (id) target
{
	id target=nil;	// if _sig is nil
	[_sig _getArgument:&target fromFrame:_argframe atIndex:0];
	return target;
}

- (void) setSelector:(SEL)aSelector
{
	[_sig _setArgument:&aSelector forFrame:_argframe atIndex:1];
#if 0
	dump(_argframe, [_sig frameLength], );
#endif
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
	return [NSString stringWithFormat:@"%@ %p: selector=%@ signature=%s target=%@ validReturn=%@",
		NSStringFromClass(isa),
		self,
		NSStringFromSelector([self selector]), [_sig _methodType],
		[self target],
		_validReturn?@"yes":@"no"
		];
}

- (void) _log:(NSString *) str;
{
	void *buffer;
	int i;
	NSLog(@"%@ %@", str, self);
	for(i=0; i<12+[_sig frameLength]/4; i++)
		{
		NSString *note=@"";
		if(((void **)_argframe)[i] == [self target]) note=(@"self");
		if(((void **)_argframe)[i] == [self selector]) note=(@"_cmd");
		if(((void **)_argframe)[i] == (_argframe+0x28)) note=(@"argp");
		NSLog(@"arg[%2d]:%08x %08x %ld %@", i, &(((void **)_argframe)[i]), ((void **)_argframe)[i], ((void **)_argframe)[i], note);
		}
#if 1
	NSLog(@"allocating buffer - len=%d", MAX([_sig frameLength], [_sig methodReturnLength]));
#endif
	buffer=objc_malloc(MAX([_sig frameLength], [_sig methodReturnLength]));	// make buffer large enough for max value size
	// print argframe
	for(i = _validReturn?-1:0; i < _numArgs; i++)
		{
		unsigned qual=[_sig _getArgumentQualifierAtIndex:i];
		const char *type;
		if(i >= 0)
			{ // normal argument
			type=[_sig _getArgument:buffer fromFrame:_argframe atIndex:i];
			}
		else
			{ // return value
			type=[_sig methodReturnType];
			[self getReturnValue:buffer];
			}
#if 1
		if(*type == _C_ID)
//			NSLog(@"argument %d qual=%d type=%s %p %@", i, qual, type, *(id *) buffer, *(id *) buffer);
			NSLog(@"argument %d qual=%d type=%s %p %p", i, qual, type, *(id *) buffer, *(id *) buffer);
		else if(*type == _C_SEL)
			NSLog(@"argument %d qual=%d type=%s %p %@", i, qual, type, *(SEL *) buffer, NSStringFromSelector(*(SEL *) buffer));
		else
			NSLog(@"argument %d qual=%d type=%s %p %08x", i, qual, type, *(SEL *) buffer, *(long *) buffer);
#endif
		}
	objc_free(buffer);
}

- (id) _initWithMethodSignature:(NSMethodSignature*)aSignature andArgFrame:(arglist_t) argFrame
{
//	NSLog(@"NSInovcation _initWithMethodSignature:%@", aSignature);
	if(!aSignature)
		{ // missing signature
		[self dealloc];
		return nil;
		}
	if((self=[super init]))
		{
		_sig = [aSignature retain];
		_numArgs = [aSignature numberOfArguments];
		_info = [aSignature _methodInfo];	// FIXME: get rid of this
		if(argFrame)
			{ // extract what we need from the existing argframe
			_argframe = argFrame;	// remember
//			_retval=NULL;
//			[_sig _getArgument:&_retval fromFrame:_argframe atIndex:-1];	// oops - this tries to copy the value to *_retval...
//			if(!_retval)
//				{ // allocate locally
				_retval = objc_calloc(1, _info[0].size);
				if(!_retval)
					{ // could not allocate
					[self dealloc];
					return nil;
					}
				_retvalismalloc=YES;
//				}
			}
		else
			{ // create fresh argument frame
			_argframe = [_sig _allocArgFrame];
			if(!_argframe)
				{ // could not allocate
				[self dealloc];
				return nil;
				}
			_argframeismalloc=YES;
			if(_info[0].size > 0)
				{ // and allocate return value space
//				NSLog(@"_retval alloc(%d)", _info[0].size);
				// might we cut off from argframe?
				// ((void **)_argframe)[2] = ((char *) _argframe) + [_sig frameLength] - _info[0].size;
				_retval = objc_malloc(_info[0].size);
				if(!_retval)
					{ // could not allocate
					[self dealloc];
					return nil;
					}
				_retvalismalloc=YES;
//				NSLog(@"_retval %08x", _retval);
				}
#if defined(Linux_ARM)
			// how to get this offset automatically???
			*(char **)_argframe=((char *) _argframe) + 10*4;	// set pointer to stack arguments
			if(_info[0].byRef)
				{ // if struct is returned - set pointer at _argframe+8 as well
//				NSLog(@"argframe=%08x return struct ptr at %08x", _argframe, argframe_arg_addr(_argframe, &_info[0]));
				*(char **)_argframe = ((char *) _argframe) + 12*4;	// we need room for the return value pointer
				[_sig _setArgument:&_retval forFrame:_argframe atIndex:-1];
				}
#endif
			}
		}
#if 1
	[self _log:@"_initWithMethodSignature:andArgFrame:"];
#endif
	return self;
}

- (retval_t) _returnValue;
{ // encode the return value so that it can be passed back in the libobjc forward:: method
#ifndef __APPLE__
	static char ret[MFRAME_RESULT_SIZE];	// we should be able to determine this from _info[0].size
//	NSLog(@"_returnValue");
	if(!_validReturn && *_info[0].type != _C_VOID)
		{ // no valid return value
		NSLog(@"warning - no valid return value set");
		[NSException raise: NSInvalidArgumentException format: @"did not 'setReturnValue:' for non-void NSInvocation"];
		}
	switch(*_info[0].type)
		{
		case _C_VOID:		return apply_void();
		case _C_CHR:
		case _C_UCHR:		return apply_char(*(char*)_retval);
		case _C_SHT:
		case _C_USHT:		return apply_short(*(short*)_retval);
		case _C_INT:
		case _C_UINT:		return apply_int(*(int*)_retval);
		case _C_LNG:
		case _C_ULNG:		return apply_long(*(long*)_retval);
		case _C_LNG_LNG:
		case _C_ULNG_LNG:	return apply_longlong(*(long long*)_retval);
		case _C_FLT:		return apply_float(*(float*)_retval);
		case _C_DBL:		return apply_double(*(double*)_retval);
		case _C_ARY_B:		return apply_pointer(*(void **)_retval);
		case _C_UNION_B:
		case _C_STRUCT_B:
			{
//				NSLog(@"_returnFrame by struct value of size %d", _info[0].size);
//				NSLog(@"_argframe=%08x", _argframe);
//				NSLog(@"_argframe[0]=%08x", ((void **)_argframe)[0]);
//				NSLog(@"_argframe[1]=%08x", ((void **)_argframe)[1]);
//				NSLog(@"_argframe[2]=%08x", ((void **)_argframe)[2]);
//				NSLog(@"_argframe[3]=%08x", ((void **)_argframe)[3]);
//				dump(_argframe, );
// #if 1	// struct return by pointer - at least on ARM_Linux
				// already memcpy'ed here by setReturnValue!
//				memcpy(((void **)_argframe)[2], _retval, _info[0].size);
				if(_info[0].byRef)
					return (retval_t) ret;	// ???
// #else
				if (_info[0].size > 8)
					// should be dependent on maximum size returned in a register (typically 8 but sometimes 4)
					// can we use sizeof(retval_t) for that purpose???
					return apply_block(*(void**)_retval);

// #endif
			}
		default:	// all others
			memcpy(ret, _retval, _info[0].size);	// copy to static location
			return (retval_t) ret;	// uh???
		}
#else
	return (retval_t) NULL;
#endif
}

- (void) dealloc
{
	if(_argsRetained)
		{
		_argsRetained = NO;
		if(_argframe && _sig)
			{
			int i;
			for(i = 0; i < _numArgs; i++)
				{
				const char *type=[_sig getArgumentTypeAtIndex:i];
				if(*type == _C_CHARPTR)
					{
					char *str;
					[_sig _getArgument:&str fromFrame:_argframe atIndex:i];
					objc_free(str);
					}
				else if(*type == _C_ID)
					{
					id obj;
					[_sig _getArgument:&obj fromFrame:_argframe atIndex:i];
					[obj release];
					}
				}
			}
		}	
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
	if((unsigned)index >= _numArgs)
		[NSException raise: NSInvalidArgumentException
					 format: @"bad invocation argument index (%d of %d)", index, _numArgs];
	[_sig _getArgument:buffer fromFrame:_argframe atIndex:index];
}

- (void) getReturnValue:(void *)buffer
{
	int length;
	if(!_validReturn)
		[NSException raise: NSGenericException
					format: @"getReturnValue with no value set"];
	// FIXME: should be moved to _getReturnValue
	length=[_sig methodReturnLength];
	if(length == 0)
		return;	// probably void
#if WORDS_BIGENDIAN
	if(length < sizeof(void *))
		length = sizeof(void *);
#endif
#if 0
	NSLog(@"getReturnValue: len=%d fm=%p to=%p *fm=%x", length, _retval, buffer, *(long *) _retval);
#endif
	memcpy(buffer, _retval, length);
}

- (void) setArgument:(void*)buffer atIndex:(int)index
{
	const char *type;
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
		id old;
		[_sig _getArgument:&old fromFrame:_argframe atIndex:index];	// get previous
		[_sig _setArgument:buffer forFrame:_argframe atIndex:index];
		[*(id*)buffer retain];
		if(old != nil)
			[old release];
		}
	else
		[_sig _setArgument:buffer forFrame:_argframe atIndex:index];
}

- (void) setReturnValue:(void*)buffer
{
	int length=[_sig methodReturnLength];
#if 0
	NSLog(@"setReturnValue buffer=%08x *buffer=%08x", buffer, *(long *) buffer);
#endif
#if 0
	if(*[_sig methodReturnType] == _C_ID)
		NSLog(@"              id=%@", *(id *) buffer);
#endif
	if(_retval && length > 0)
		{ // buffer exists and we have to return something
#if WORDS_BIGENDIAN
		if(length < sizeof(void *))
			length = sizeof(void *);
#endif
		memcpy(_retval, buffer, length);
		}
	_validReturn = YES;
}

- (void) retainArguments
{
	int	i;
	if(_argsRetained)
		return;	// already retained
	_argsRetained = YES;
	if(_argframe == NULL)
		return;
	for(i = 0; i < _numArgs; i++)
		{
		const char *type=[_sig getArgumentTypeAtIndex:i];
		if(*type == _C_CHARPTR)
			{ // store a copy
			char *str;
			[_sig _getArgument:&str fromFrame:_argframe atIndex:i];
			if(str != 0)
				{
				char *tmp = objc_malloc(strlen(str)+1);
				strcpy(tmp, str);
				[_sig _setArgument:tmp forFrame:_argframe atIndex:i];
				}
			}
		else if(*type == _C_ID)
			{ // retain object
			id obj;
			[_sig _getArgument:&obj fromFrame:_argframe atIndex:i];
			[obj retain];
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
//	id old_target;		// save target
	IMP imp;			// method implementation pointer
	int stack_argsize;	// size of stack frame to be pushed
	retval_t retframe;	// returned frame
	id target;
	SEL selector;
	[_sig _getArgument:&target fromFrame:_argframe atIndex:0];
#if 0
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
		NSLog(@"forwarding or something ...");
#endif
		imp = objc_msg_lookup(target, selector);
		}
//	[_sig _prepareFrameForCall:_argframe];	// update stackframe as needed by CPU
#if 1
	[self _log:@"invoke"];
#endif
	stack_argsize = [_sig frameLength];
#if 0
	NSLog(@"sending message %@ to object %@ with argframe %08x", NSStringFromSelector(selector), target, _argframe);
	dump(_argframe, stack_argsize,
	  if(((void **)_argframe)[i] == (void *) _retval) 	note=(@"_retval");
	  if(((void **)_argframe)[i] == (void *) target) 	note=(@"target");
	  if(((void **)_argframe)[i] == (void *) selector) note=(@"selector");
	  if(((void **)_argframe)[i] == (void *) imp) 		note=(@"imp")
	  );
#endif
#if 0
	NSLog(@"__builtin_apply(%08x, %08x, %d)", imp, _argframe, stack_argsize);
#endif
	retframe = __builtin_apply((void(*)(void))imp, _argframe, stack_argsize);	// here, we really invoke the implementation
#if 0
	NSLog(@"retframe= %p", retframe);
#endif
	if([_sig methodReturnLength] > 0)
		{ // the following code fetches a typed value from retframe and makes it available through getReturnValue
#if 0
		NSLog(@"  type:%s save:%p", _info[0].type, _retval);
#endif
		switch(*_info[0].type)
			{
#if 0 // code simplification not yet tested
#define RETURN(CODE, TYPE) case CODE: { /*inline*/ TYPE retframe_##TYPE(void *f) { __builtin_return(f); } *(TYPE *) _retval = retframe_##TYPE(retframe); break; }
			RETURN(_C_ID, id);
			RETURN(_C_CLASS, Class);
			RETURN(_C_SEL, SEL);
	// etc.
#endif
			case _C_ID:
				{
					/* inline */ id retframe_id(void *f)			{ __builtin_return(f); }
#if 0
					NSLog(@"retframe_id returns %p", retframe_id(retframe));
#endif
					*(id *)_retval = retframe_id(retframe);
#if 0
					NSLog(@"invoke returns id %p", *(id *) _retval);
					NSLog(@"  object: %@", *(id *) _retval);
#endif
					break;
				}
			case _C_CLASS:
				{
					// RETURN(Class);
					/*inline*/ Class retframe_Class(void *f)	{ __builtin_return(f); }
					*(Class *)_retval = retframe_Class(retframe);
					break;
				}
			case _C_SEL:
				{
					// RETURN(SEL);
					/*inline*/ SEL retframe_SEL(void *f)		{ __builtin_return (f); }
					*(SEL *)_retval = retframe_SEL(retframe);
					break;
				}
			case _C_CHR:
			case _C_UCHR:
				{
					// RETURN(unsigned char);
					// FIXME: do we have to care about endianness here? probably no since we stay in the same architecture.
					/*inline*/ unsigned char retframe_char(void *f)	{ __builtin_return (f); }
					*(unsigned char *)_retval = retframe_char(retframe);
					break;
				}
			case _C_SHT:
			case _C_USHT:
				{
					/*inline*/ unsigned short retframe_short(void *f) { __builtin_return (f); }
					*(unsigned short *)_retval = retframe_short(retframe);
					break;
				}
			case _C_INT:
			case _C_UINT:
				{
					/*inline*/ unsigned int retframe_int(void *f) { __builtin_return (f); }
					*(unsigned int *)_retval = retframe_int(retframe);
					break;
				}
			case _C_LNG:
			case _C_ULNG:
				{
					/*inline*/ unsigned long retframe_long(void *f) { __builtin_return (f); }
					*(unsigned long *)_retval = retframe_long(retframe);
					break;
				}
			case _C_LNG_LNG:
			case _C_ULNG_LNG:
				{
					/*inline*/ unsigned long long retframe_longlong(void *f) { __builtin_return (f); }
					*(unsigned long long *)_retval = retframe_longlong(retframe);
					break;
				}
			case _C_FLT:
				{
					/*inline*/ float retframe_float(void *f)	{ __builtin_return (f); }
					*(float *)_retval = retframe_float(retframe);
					break;
				}
			case _C_DBL:
				{
					/*inline*/ double retframe_double(void *f)	{ __builtin_return (f); }
					*(double *)_retval = retframe_double(retframe);
					break;
				}
			case _C_PTR:
			case _C_ATOM:
			case _C_CHARPTR:
				{
					/*inline*/ char* retframe_pointer(void *f)	{ __builtin_return (f); }
					*(char **)_retval = retframe_pointer(retframe);
					break;
				}
			case _C_ARY_B:
			case _C_STRUCT_B:
			case _C_UNION_B:
				{
					typedef struct {
						char val[_info[0].size];
					} block;
					/*inline*/ block retframe_block(void *f)	{ __builtin_return (f); }
					*(block *)_retval = retframe_block(retframe);
					break;
				}
			case _C_VOID:
				break;	// should not happen to be called since size==0
			default:
				_validReturn=NO;								// Unknown type
				return;
			}
		}
	_validReturn = YES;
#endif	// #ifndef __APPLE__
}

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder { return self; }	// don't replace by another proxy

/*
 * encoding of in/out/inout paramters is based on the _validReturn flag
 *
 * if validReturn, we assume we are a response and encode the result, out and inout paramters only
 * if no validReturn, we assume a request and encode in and inout parameters only
 */

- (void) encodeWithCoder:(NSCoder*) aCoder
{ // NOTE: only supports NSPortCoder
	const char *types = [_sig _methodType];	// get method type
	void *buffer=objc_malloc(MAX([_sig frameLength], [_sig methodReturnLength]));	// make buffer large enough for max value size
	int i;
#if 0
	NSLog(@"%@ encodeWithCoder types=%s", NSStringFromClass(isa), types);
#endif
#if 0
	NSLog(@"buffer[%d]=%p", MAX([_sig frameLength], [_sig methodReturnLength]), buffer);
#endif
	if(!buffer) return;
	[aCoder encodeValueOfObjCType:@encode(char *) at:&types];
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
		NSLog(@"NSInvocation encode arg %d type %s", i, type);
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
#if 0
	NSLog(@"%@ initWithCoder: %@", self, aCoder);
#endif
	[aCoder decodeValueOfObjCType:@encode(char*) at:&types];
#if 0
	NSLog(@"  decoded type=%s", types);
#endif
	[aCoder decodeValueOfObjCType:@encode(BOOL) at:&_validReturn];
#if 0
	NSLog(@"  validReturn=%@", _validReturn?@"YES":@"NO");
#endif
	[self retainArguments];	
	if(!_sig || !_validReturn)
		{ // assume we have to decode a Request
		self=[self _initWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:types] andArgFrame:NULL];
		}
	else
		{ // a response - assume we already have been initialized for _sig
		// should be the same as we have requested
#if 0
		NSLog(@"  existing type=%s", [_sig _methodType]);
#endif
		}
	buffer=objc_malloc(MAX([_sig frameLength], [_sig methodReturnLength]));	// make buffer large enough for max value size
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
			type=[_sig methodReturnType];
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
			{
			[self setArgument:buffer atIndex:i];
			if(*type == _C_ID)
				NSLog(@"did set argument %d: %@", i, *(id *) buffer);
			}
		}
#if 1
	[self _log:@"initWithCoder:"];
#endif
	objc_free(buffer);
	return self;
}

@end  /* NSInvocation */
