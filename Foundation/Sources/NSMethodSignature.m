/* 
   NSMethodSignature.m

   Implementation of NSMethodSignature for mySTEP
   This file encapsulates all CPU specific specialities (e.g. how the __builtin_apply() frame is organized, how registers are handled etc.)

   Copyright (C) 1994, 1995, 1996, 1998 Free Software Foundation, Inc.
   
   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	August 1994
   Rewrite:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:	August 1998
   Rewrite: Nikolaus Schaller <hns@computer.org> - remove as much of mframe as possible and only rely on gcc/libobjc to run on ARM processor
   Date:    November 2003, Jan 2006-2007

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.

 Some notes&observations by H. N. Schaller:
 * the argframe passed when forward:: is the one created by the libobjc functions __objc_x_forward(id, SEL, ...)
 * x can be word, double, block
 * that argframe structure can/will be different on ARM from the argframe within a called method with known number of arguments!
 * therefore, the method signature might be different for implemented and non-implemented methods - the latter being
   based on (id, SEL, ...)
 * so we need to create a different structure to call any existing/nonexisting method by __builtin_apply()
 * libobjc seems to use #define OBJC_MAX_STRUCT_BY_VALUE 1 (runtime-info.h) meaning that a char[1] only struct is returned in a register
 * use more support functions from libobjc

*/ 

#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import "NSPrivate.h"

struct NSArgumentInfo
	{ // Info about layout of arguments. Extended from the original OpenStep version
		int offset;
		unsigned size;					// let us know if the arg is passed in 
		const char *type;				// registers or on the stack.  OS 4.0 only
		unsigned align;					// alignment
		unsigned qual;					// qualifier (oneway, byref, bycopy, in, inout, out)
		unsigned index;					// argument index (to decode return=0, self=1, and _cmd=2)
		BOOL isReg;						// is passed in a register (+)
		BOOL byRef;						// argument is not passed by value but by pointer (i.e. structs)
		BOOL floatAsDouble;				// its a float value that is passed as double
	};

#define AUTO_DETECT 0

#if AUTO_DETECT	// to identify calling conventions automatically - EXPERIMENTAL
@interface NSMethodSignature (Autodetect)
+ (id) __call_me:(id) s :(SEL) cmd : (id) arg;
@end

static SEL sel=@selector(__call_me::);

static BOOL passStructByPointer;			// passes structs by pointer
static BOOL returnStructByVirtualArgument;	// returns structs by virtual argument pointer

#endif

// processor specific constants initialized in +initialize

static BOOL isBigEndian;
static BOOL structByRef;
static BOOL floatAsDouble;
static int registerSaveAreaSize;			// how much bytes we need for that (may be 0)
static int structReturnPointerLength;		// how much bytes we need for that (may be 0)

// merge this into NSMethodSignature

static const char *mframe_next_arg(const char *typePtr, struct NSArgumentInfo *info)
{
	NSAssert(info, @"missing NSArgumentInfo");
	// FIXME: NO, we should keep the flags+type but remove the offset
	info->qual = 0;	// start with no qualifier
	info->floatAsDouble = NO;
	// Skip past any type qualifiers,
	for(; YES; typePtr++)
		{
		switch (*typePtr)
			{
			case _C_CONST:  info->qual |= _F_CONST; continue;
			case _C_IN:     info->qual |= _F_IN; continue;
			case _C_INOUT:  info->qual |= _F_INOUT; continue;
			case _C_OUT:    info->qual |= _F_OUT; continue;
			case _C_BYCOPY: info->qual |= _F_BYCOPY; info->qual &= ~_F_BYREF; continue;
#ifdef _C_BYREF
			case _C_BYREF:  info->qual |= _F_BYREF; info->qual &= ~_F_BYCOPY; continue;
#endif
			case _C_ONEWAY: info->qual |= _F_ONEWAY; continue;
			default: break;
			}
		break;	// break loop
		}
	info->type = typePtr;
	
	if(structByRef)
		info->byRef = (*typePtr == _C_STRUCT_B || *typePtr == _C_UNION_B || *typePtr == _C_ARY_B);
	else
		info->byRef = NO;
	
	switch (*typePtr++)				// Scan for size and alignment information.
		{
		case _C_ID:
			info->size = sizeof(id);
			info->align = __alignof__(id);
			break;
			
		case _C_CLASS:
			info->size = sizeof(Class);
			info->align = __alignof__(Class);
			break;
			
		case _C_SEL:
			info->size = sizeof(SEL);
			info->align = __alignof__(SEL);
			break;
			
		case _C_CHR:
			info->size = sizeof(char);
			info->align = __alignof__(char);
			break;
			
		case _C_UCHR:
			info->size = sizeof(unsigned char);
			info->align = __alignof__(unsigned char);
			break;
			
		case _C_SHT:
			info->size = sizeof(short);
			info->align = __alignof__(short);
			break;
			
		case _C_USHT:
			info->size = sizeof(unsigned short);
			info->align = __alignof__(unsigned short);
			break;
			
		case _C_INT:
			info->size = sizeof(int);
			info->align = __alignof__(int);
			break;
			
		case _C_UINT:
			info->size = sizeof(unsigned int);
			info->align = __alignof__(unsigned int);
			break;
			
		case _C_LNG:
			info->size = sizeof(long);
			info->align = __alignof__(long);
			break;
			
		case _C_ULNG:
			info->size = sizeof(unsigned long);
			info->align = __alignof__(unsigned long);
			break;
			
		case _C_LNG_LNG:
			info->size = sizeof(long long);
			info->align = __alignof__(long long);
			break;
			
		case _C_ULNG_LNG:
			info->size = sizeof(unsigned long long);
			info->align = __alignof__(unsigned long long);
			break;
			
		case _C_FLT:
			if(floatAsDouble)
				{
				// I guess we should set align/size differently...
				info->floatAsDouble = YES;
				info->size = sizeof(double);
				info->align = __alignof__(double);
				}
			else
				{
				info->size = sizeof(float);
				info->align = __alignof__(float);
				}
			break;
			
		case _C_DBL:
			info->size = sizeof(double);
			info->align = __alignof__(double);
			break;
			
		case _C_PTR:
			info->size = sizeof(char*);
			info->align = __alignof__(char*);
			if (*typePtr == '?')
				typePtr++;
			else
				{ // recursively
				struct NSArgumentInfo local;
				typePtr = mframe_next_arg(typePtr, &local);
				info->isReg = local.isReg;
				info->offset = local.offset;
				}
			break;
			
		case _C_ATOM:
		case _C_CHARPTR:
			info->size = sizeof(char*);
			info->align = __alignof__(char*);
			break;
			
		case _C_ARY_B:
			{
				struct NSArgumentInfo local;
				int	length = atoi(typePtr);
				
				while (isdigit(*typePtr))
					typePtr++;
				
				typePtr = mframe_next_arg(typePtr, &local);
				info->size = length * ROUND(local.size, local.align);
				info->align = local.align;
				typePtr++;								// Skip end-of-array
			}
			break; 
			
		case _C_STRUCT_B:
			{
				struct NSArgumentInfo local;
				//	struct { int x; double y; } fooalign;
				struct { unsigned char x; } fooalign;
				int acc_size = 0;
				int acc_align = __alignof__(fooalign);
				
				while (*typePtr != _C_STRUCT_E)			// Skip "<name>=" stuff.
					if (*typePtr++ == '=')
						break;
				// Base structure alignment 
				if (*typePtr != _C_STRUCT_E)			// on first element.
					{
					typePtr = mframe_next_arg(typePtr, &local);
					if (typePtr == 0)
						return 0;						// error
					
					acc_size = ROUND(acc_size, local.align);
					acc_size += local.size;
					acc_align = MAX(local.align, __alignof__(fooalign));
					}
				// Continue accumulating 
				while (*typePtr != _C_STRUCT_E)			// structure size.
					{
					typePtr = mframe_next_arg(typePtr, &local);
					if (typePtr == 0)
						return 0;						// error
					
					acc_size = ROUND(acc_size, local.align);
					acc_size += local.size;
					}
				info->size = acc_size;
				info->align = acc_align;
				//printf("_C_STRUCT_B  size %d align %d\n",info->size,info->align);
				typePtr++;								// Skip end-of-struct
			}
			break;
			
		case _C_UNION_B:
			{
				struct NSArgumentInfo local;
				int	max_size = 0;
				int	max_align = 0;
				
				while (*typePtr != _C_UNION_E)			// Skip "<name>=" stuff.
					if (*typePtr++ == '=')
						break;
				
				while (*typePtr != _C_UNION_E)
					{
					typePtr = mframe_next_arg(typePtr, &local);
					if (typePtr == 0)
						return 0;						// error
					max_size = MAX(max_size, local.size);
					max_align = MAX(max_align, local.align);
					}
				info->size = max_size;
				info->align = max_align;
				typePtr++;								// Skip end-of-union
			}
			break;
			
		case _C_VOID:
			info->size = 0;
			info->align = __alignof__(char*);
			break;
			
		default:
			return 0;
		}
	
	if(*typePtr == 0)
		return NULL;								// error
	if(info->type[0] != _C_PTR || info->type[1] == '?')
		{
		if(*typePtr == '+')	 
			{ // register offset
			typePtr++;
			info->isReg = YES;
			}
		else
			{ // stack offset
			info->isReg = NO;
			}
		info->offset = 0;
		while(isdigit(*typePtr))
			info->offset = 10 * info->offset + (*typePtr++ - '0');
		}
	
	// FIXME: to be more compatible, we should return a string incl. qualifier but without offset part!
	// i.e. Vv, R@, O@ etc.

	return typePtr;
}

@implementation NSMethodSignature

+ (void) initialize
{
//	NSLog(@"This is [NSMethodSignature initialize]\n");
#if AUTO_DETECT
	[NSMethodSignature __call_me:self :sel :self];
	passStructByPointer=NO;
	returnStructByVirtualArgument=YES;
#else
#if defined(Linux_ARM)	// for ARM_Linux
	registerSaveAreaSize=4*sizeof(long);		// for ARM processor
	structReturnPointerLength=sizeof(void *);	// if we have one
	isBigEndian=NSHostByteOrder()==NS_BigEndian;
	floatAsDouble=YES;
	structByRef=YES;
#endif
#endif
#if 0
	NSLog(@"NSMethodSignature +initialize: processor is %@", isBigEndian?@"Big Endian":@"Little Endian");
	NSLog(@"NSMethodSignature +initialize: register save area %d bytes", registerSaveAreaSize);
#endif
}

#define NEED_INFO() if(info == NULL) [self _methodInfo]

- (void) _methodInfo
{ // collect all information from methodTypes in a platform independent way
	if(info == NULL) 
			{ // calculate method info
				const char *types = methodTypes;
				int i;
				int allocArgs=5;
				argFrameLength=0;
#if 0
				NSLog(@"methodInfo create");
#endif
				// should we add a struct return pointer
				info = objc_malloc(sizeof(struct NSArgumentInfo) * allocArgs);
				for(i = 0; *types != 0; i++)
						{ // process all types
#if 0
							NSLog(@"%d: %s", i, types);
#endif
							if(i >= allocArgs)
								allocArgs+=5, info = objc_realloc(info, sizeof(struct NSArgumentInfo) * allocArgs);	// we need more space
							types = mframe_next_arg(types, &info[i]);
							info[i].index=i;
							if((info[i].qual & _F_INOUT) == 0)
									{ // add default qualifiers
										if(i == 0)
											info[i].qual |= _F_OUT;		// default to "bycopy out" for the return value
										else if(*info[0].type == _C_PTR || *info[0].type == _C_ATOM || *info[0].type == _C_CHARPTR)
											info[i].qual |= _F_INOUT;	// default to "bycopy in/out"
										else
											info[i].qual |= _F_IN;		// default to "bycopy in"
									}
							if(isBigEndian && info[i].align < 4)
									{ // adjust offset
										info[i].offset+=4-info[i].align;	// point to the correct byte
										info[i].align=4;					// ARM pushes all arguments as long words
									}
							// CHECKME!
							if(i>0 && info[i].isReg && info[0].byRef)
								info[i].offset += structReturnPointerLength;	// adapt offset because we have a virtual first argument
#if 0
							NSLog(@"%d: type=%s size=%d align=%d isreg=%d offset=%d qual=%x byRef=%d fltDbl=%d",
										info[i].index, info[i].type, info[i].size, info[i].align,
										info[i].isReg, info[i].offset, info[i].qual,
										info[i].byRef, info[i].floatAsDouble);
#endif
							if(!info[i].isReg)	// value is on stack - counts for frameLength
								argFrameLength += ((info[i].size+info[i].align-1)/info[i].align)*info[i].align;
						}
				numArgs = i-1;	// return type does not count
#if 0
				NSLog(@"numArgs=%d argFrameLength=%d", numArgs, argFrameLength);
#endif
    	}
}

// standard methods

- (unsigned) frameLength
{
	NEED_INFO();
	return argFrameLength;
}

- (const char *) getArgumentTypeAtIndex:(unsigned)index
{
	if(index >= numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index too high."];
	NEED_INFO();
	return info[index+1].type;
}

- (BOOL) isOneway
{
	NEED_INFO();
	return (info[0].qual & _F_ONEWAY) ? YES : NO;
}

- (void) _makeOneWay;
{ // special function for sending release messages oneway
	NEED_INFO();
	info[0].qual |= _F_ONEWAY;
}

- (unsigned) methodReturnLength
{
	NEED_INFO();
	return info[0].size;
}

- (const char*) methodReturnType
{
	NEED_INFO();
    return info[0].type;
}

- (unsigned) numberOfArguments
{
	NEED_INFO();
	return numArgs;
}

- (void) dealloc
{
    if(methodTypes)
			objc_free((void*) methodTypes);
    if(info)
			objc_free((void*) info);
    [super dealloc];
}

- (void) encodeWithCoder:(NSCoder*)aCoder	{ NIMP; }
- (id) initWithCoder:(NSCoder*)aCoder		{ NIMP; return nil; }

+ (NSMethodSignature *) signatureWithObjCTypes:(const char*) t;
{ // now officially made public (10.5)
	return [[[NSMethodSignature alloc] _initWithObjCTypes:t] autorelease];
}

- (id) _initWithObjCTypes:(const char*) t;
{
	if((self=[super init]))
		{
		methodTypes=objc_malloc(strlen(t)+1);
		strcpy(((char *) methodTypes), t);	// save unchanged
#if 0
		NSLog(@"NSMethodSignature -> %s", t);
#endif
		}
	return self;
}

- (const char*) _methodType	{ return methodTypes; }

- (unsigned) _getArgumentLengthAtIndex:(int) index;
{
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	return info[index+1].size;
}

- (unsigned) _getArgumentQualifierAtIndex:(int)index;
{
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	return info[index+1].qual;
}

- (const char *) _getArgument:(void *) buffer fromFrame:(arglist_t) _argframe atIndex:(int) index;
{ // extract argument from frame
	void *addr;
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	if(index == -1)
			{ // copy return value to buffer
				if(info[0].size > 0)
					memcpy(buffer, _argframe, info[0].size);
				return info[0].type;
			}
	addr = (info[index+1].isReg?((char *)_argframe):(*(char **)_argframe)) + info[index+1].offset;
#if 1
	NSLog(@"_getArgument[%d] offset=%u addr=%p byref=%d double=%d", index, info[index+1].offset, addr, info[index+1].byRef, info[index+1].floatAsDouble);
#endif
	if(info[index+1].byRef)
		memcpy(buffer, *(void**)addr, info[index+1].size);
	else if(info[index+1].floatAsDouble)
		*(float*)buffer = (float)*(double*)addr;
	else
		memcpy(buffer, addr, info[index+1].size);
	return info[index+1].type;
}

- (void) _setArgument:(void *) buffer forFrame:(arglist_t) _argframe atIndex:(int) index;
{
	void *addr;
	if(index < -1 || index >= (int)numArgs)
		[NSException raise: NSInvalidArgumentException format: @"Index %d too high (%d).", index, numArgs];
	NEED_INFO();
	if(index == -1)
			{ // copy return value to buffer
				if(info[0].size > 0)
					memcpy(_argframe, buffer, info[0].size);
				return;
			}
	addr = (info[index+1].isReg?((char *)_argframe):(*(char **)_argframe)) + info[index+1].offset;
#if 0
	NSLog(@"_setArgument[%d] offset=%u addr=%p byref=%d double=%d", index, info[index+1].offset, addr, info[index+1].byRef, info[index+1].floatAsDouble);
#endif
	if(info[index+1].byRef)
		memcpy(*(void**)addr, buffer, info[index+1].size);
	else if(info[index+1].floatAsDouble)
		*(double*)addr = *(float*)buffer;
	else
		memcpy(addr, buffer, info[index+1].size);
}

- (arglist_t) _allocArgFrame:(arglist_t) frame
{ // (re)allocate stack frame for ARM CPU
	if(!frame)
		{ // make a single buffer that is large enough to hold the _builtin_apply() block + space for frameLength arguments
		int part1 = sizeof(void *) + structReturnPointerLength + registerSaveAreaSize;	// first part
		void *args;
		frame=(arglist_t) objc_calloc(part1 + argFrameLength, sizeof(char));
		args=(char *) frame + part1;
#if 0
		NSLog(@"allocated frame=%p args=%p framelength=%d", frame, args, argFrameLength);
#endif
		((void **)frame)[0]=args;		// insert argument pointer (points to part 2 of the buffer)
		}
	else
		((char **)frame)[0]+=12;		// on ARM - forward:: returns the full stack while __builtin_apply() needs only the extra arguments
	return frame;
}

static BOOL wrapped_builtin_apply(void *imp, arglist_t frame, int stack, void *retbuf, struct NSArgumentInfo *info)
{ // wrap call because it fails if called within a Objective-C method
#ifndef __APPLE__
	retval_t retframe=__builtin_apply(imp, frame, stack);	// here, we really invoke the implementation
#if 0
	NSLog(@"retframe= %p", retframe);
#endif
	if(info[0].size)
			{ // the following code fetches a typed value from retframe and makes it available through getReturnValue
				typedef struct {
					char val[info[0].size];
				} block;
#if 0
				NSLog(@"  type:%s save:%p", info[0].type, retframe);
#endif
				switch(*info[0].type)
					{
#define RETURN(CODE, TYPE) case CODE: { /*inline*/ TYPE retframe_##CODE(void *f) { __builtin_return(f); } *(TYPE *) retbuf = retframe_##CODE(retframe); break; }
#if 1	// debugging
						case _C_ID:
							{
								static /* inline or static? */ id retframe_id(void *f)			{ __builtin_return(f); }
								NSLog(@"retframe_id returns %p", retframe_id(retframe));
								*(id *)retbuf = retframe_id(retframe);
								NSLog(@"invoke returns id %p", *(id *) retbuf);
								NSLog(@"  object: %@", *(id *) retbuf);
								break;
							}
#else
							RETURN(_C_ID, id);
#endif
							RETURN(_C_CLASS, Class);
							RETURN(_C_SEL, SEL);
							RETURN(_C_CHR, char);
							RETURN(_C_UCHR, unsigned short);
							RETURN(_C_SHT, char);
							RETURN(_C_USHT, unsigned short);
							RETURN(_C_INT, int);
							RETURN(_C_UINT, unsigned int);
							RETURN(_C_LNG, long);
							RETURN(_C_ULNG, unsigned long);
							RETURN(_C_LNG_LNG, long long);
							RETURN(_C_ULNG_LNG, unsigned long long);
							RETURN(_C_FLT, float);
							RETURN(_C_DBL, double);
							RETURN(_C_PTR, char *);
							RETURN(_C_ATOM, char *);
							RETURN(_C_CHARPTR, char *);
							RETURN(_C_ARY_B, block);
							RETURN(_C_STRUCT_B, block);
							RETURN(_C_UNION_B, block);
						case _C_VOID:
							break;	// should not happen to be called since size==0
					}
				return YES;	// break from switch
			}
#endif
	return NO;
}

- (BOOL) _call:(void *) imp frame:(arglist_t) _argframe retbuf:(void *) retbuf;
{ // preload registers from ARM stack frame and call implementation
	NEED_INFO();
	((void **)_argframe)[1] = ((void **)_argframe)[2];		// copy target/self value to the register frame
	return wrapped_builtin_apply(imp, _argframe, argFrameLength, retbuf, &info[0]);	// here, we really invoke the implementation	
}

#if AUTO_DETECT

+ (id) __call_me:(id) s :(SEL) cmd : (id) arg;
{
	arglist_t argFrame=__builtin_apply_args();
	Method *m;
	const char *type;
//	NSLog(@"This is [NSMethodSignature __call_me::]");
//	NSLog(@"argFrame=%08x", (unsigned) argFrame);
	m=class_get_instance_method(((struct objc_class*) s)->class_pointer, cmd);
//	NSLog(@"m=%08x", (unsigned) m);
	if(m)
		{
		NSLog(@"firstarg=%08x", (unsigned) method_get_first_argument(m, argFrame, &type));
		NSLog(@"nextarg=%08x", (unsigned) method_get_next_argument(argFrame, &type));

// retval_t objc_msg_sendv(id object, SEL op, arglist_t arg_frame)
//{
// Method* m = class_get_instance_method(object->class_pointer, op);
// const char *type;
// *((id*)method_get_first_argument (m, arg_frame, &type)) = object;
// *((SEL*)method_get_next_argument (arg_frame, &type)) = op;
//  return __builtin_apply((apply_t)m->method_imp, arg_frame, method_get_sizeof_arguments (m));
//  }
		}
	return nil;
	}

#endif

@end  /* NSMethodSignature (mySTEP) */
