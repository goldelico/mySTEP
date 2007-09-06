/// should become part of NSMethodSignature as the only class that encapsulates a stack frame

/*
   mframe.m

 -- CHECKME: what is really still used?
 -- CHECKME: why don't we use method_get_next_argument (arg_frame, &type)) from libobjc?
 
   Implementation of functions for dissecting/making method calls
 
   These functions can be used for dissecting and making method calls
   for many different situations.  They are used for distributed objects.

   Copyright (C) 1994, 1996, 1998 Free Software Foundation, Inc.
   
   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	Oct 1994
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.

*/ 

#include "mframe.h"

#import "NSPrivate.h"
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSInvocation.h>

// merge this into NSMethodSignature

const char *
mframe_next_arg(const char *typePtr, NSArgumentInfo *info)
{
	NSArgumentInfo local;					// Step through method encoding
	BOOL flag;								// information extracting details.

	if (info == 0)
		info = &local;						// dummy storage
	
	// Skip past any type qualifiers,
	flag = YES;								// return them if caller wants them
	info->qual = 0;	// no qualifier
	info->floatAsDouble = NO;
	while (flag)
		{
		switch (*typePtr)
			{
			case _C_CONST:  info->qual |= _F_CONST; break;
			case _C_IN:     info->qual |= _F_IN; break;
			case _C_INOUT:  info->qual |= _F_INOUT; break;
			case _C_OUT:    info->qual |= _F_OUT; break;
			case _C_BYCOPY: info->qual |= _F_BYCOPY; info->qual &= ~_F_BYREF; break;
#ifdef _C_BYREF
			case _C_BYREF:  info->qual |= _F_BYREF; info->qual &= ~_F_BYCOPY; break;
#endif
			case _C_ONEWAY: info->qual |= _F_ONEWAY; break;
			default: flag = NO; continue;
			}
		if (flag)
			typePtr++;
		}

	info->type = typePtr;

#if MFRAME_STRUCT_BYREF
	info->byRef = (*typePtr == _C_STRUCT_B || *typePtr == _C_UNION_B || *typePtr == _C_ARY_B);
#else
	info->byRef = NO;
#endif
	
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
#if MFRAME_FLT_IN_FRAME_AS_DBL
			// I guess we should set align/size differently...
			info->floatAsDouble = YES;
			info->size = sizeof(double);
			info->align = __alignof__(double);
#else
			info->size = sizeof(float);
			info->align = __alignof__(float);
#endif
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
				{
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
//			struct { int x; double y; } fooalign;
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

	if (typePtr == 0)
		return 0;									// error
						// If we had a pointer argument, we will already have 
						// gathered (and skipped past) the argframe offset 
						// info - so we don't need to (and can't) do it here.
	if (info->type[0] != _C_PTR || info->type[1] == '?')
		{
		if (*typePtr == '+')					// May tell the caller if item 
			{									// is stored in a register.
			typePtr++;
			info->isReg = YES;
			}
		else 
			if (info->isReg)
				info->isReg = NO;
												// May tell the caller what the 
		info->offset = 0;						// stack/register offset is for
		while (isdigit(*typePtr))				// this argument.
			info->offset = info->offset * 10 + (*typePtr++ - '0');
		}

	return typePtr;
}
