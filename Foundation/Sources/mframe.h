
/// should become part of NSMethodSignature as the only class that encapsulates a stack frame

/// CHECKME: which parts do we still use?
/// just some macros...

/*
   mframe.h

   Interface for functions that dissect/make method calls
 
   Copyright (C) 1994, 1996, 1998 Free Software Foundation, Inc.
   
   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	Oct 1994
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef __mframe_h_mySTEP_BASE_INCLUDE
#define __mframe_h_mySTEP_BASE_INCLUDE

#include <Foundation/NSMethodSignature.h>


//*****************************************************************************
//
// 		include platform specific details from DOConfig.h
//
//*****************************************************************************

/*
 machine/operating-system specific macros used to access stack frames.
 
 MFRAME_STACK_STRUCT
	This should be defined to 1 if functions return structures by value
	using the method where the caller places a pointer on the stack.
	Define this to 0 otherwise (eg. when the pointer to the structure is
								passed in a register).
 
 MFRAME_SMALL_STRUCT
	This is the size of the largest structure returned by value on
	the stack.  Normally gcc returns structures of up to 8 bytes on
	the stack.  If your system never returns structures on the stack,
	set this to zero rather than 8.
	NB. If __builtin_apply_args() always returns an argframe for
	structure return via pointer, you should also define this to zero.
 
 MFRAME_STRUCT_BYREF
	This should be defined to 1 if structure arguments are passed in
	the stack frame by reference, 0 otherwise.
 
 MFRAME_ARGS_SIZE
	This must be set to the value computed by the apply_args_size()
	function in expr.c in the gcc source.  It is the size of the
	area of memory allocated in which to pass arguments to a function.
	If you can't figure out how to determine this (hack expr.c to print
												   the result of the function the first time it's called) - try using a
	value like 128 - which will probably be far larger than required
	(and therefore somewhat inefficient) but will most likely work.
 
 MFRAME_RESULT_SIZE
	This must be set to the value computed by the apply_result_size()
	function in expr.c in the gcc source.  It is the size of the area
	of memory allocated in which to return a value from a function.
	If you can't figure out how to determine this (hack expr.c to print
												   the result of the function the first time it's called) - try using a
	value like 128 - which will probably be far larger than required
	(and therefore somewhat inefficient) but will most likely work.
 
 MFRAME_FLT_IN_FRAME_AS_DBL
	This should be defined as 1 if float parameters to functions and
	objective-c methods are passed on the stack as double values.
	Otherwise it should not be defined.
 
 MFRAME_GET_STRUCT_ADDR(ARGFRAME,TYPES)
	If a function returns a structure by copying it into a location
	whose address is set by the caller, this macro must return that
	address within the argframe.
	Otherwise the macro must return zero.
 
 MFRAME_SET_STRUCT_ADDR(ARGFRAME,TYPES,ADDR)
 
 MFRAME_ARGS
	This macro should define a data type to be used for recording
	information about the arguments list of a method.
	See 'CUMULATIVE_ARGS' in the configuration file for your system
	in gcc for a parallel example.
 
 MFRAME_INIT_ARGS(CUM, RTYPE)
	This macro is used to initialise a variable (CUM) of the type
	defined by MFRAME_ARGS.  The RTYPE value is the type encoding for the
	method return type, it is needed so that CUM can take int account any
	invisible first argument used for returning structures by value.
	See 'INIT_CUMULATIVE_ARGS' in the configuration file for your system
	in gcc for a parallel example.
 
 MFRAME_ARG_ENCODING(CUM,TYPES,STACK,DEST)
	This macro is used to to determine the encoding of arguments.
	You will have to write this macro for your system by examining the
	gcc source code to determine how the compiler does this on your
	system - look for the usage of CUMULATIVE_ARGS an INIT_CUMULATIVE_ARGS
	in the configuration files for your hardware and operating system in
	the gcc (or egcs) source, and make your macro mirror it's operation.
 
	Before initial entry,
 CUM should have been initialised using the MFRAME_INIT_ARGS() macro,
 TYPES should be a (const char*) variable initialised to a
 type-encoding string listing the arguments of a function/method,
 STACK should be an integer variable of value 0 in which the size of
 the stack arguments will be accumulated,
 DEST should be a (char*) variable initialised to a pointer to a
 buffer into which the full type encoding will be written.
	After each use of the macro, TYPES is advanced to point to the next
	argument, and DEST is advanced to point after the encoding of the
	previous argument.
	Of course, you must ensure that the buffer pointed to by DEST is
	large enough so that it does not overflow!
	You will be safe if your buffer is at least ten times as big as
	the type-encoding string you start from.
 
 The notation for TYPES is as follows
 i	integer
 v	void
 f	float
 @   id
 :	SEL
 ....
 {name=type...}  structure (named) with component types specified
 
 Each type can be followed by either
 d		denoting that the argument is located at offset d from the saved stack pointer
 +d	denoting that the argument is located at offset d from the frame pointer (meaning being passed in registers)
 */

//	Machine/OS specific information required by mySTEP DO headers.
//
//  Definition to specify if your processor stores words with the most
//  significant byte first (like Motorola and SPARC, unlike Intel and VAX).

#define GS_WORDS_BIGENDIAN	0

//	Size definitions for standard types
#define	GS_SIZEOF_SHORT		2
#define	GS_SIZEOF_INT		4
#define	GS_SIZEOF_LONG		4
#define	GS_SIZEOF_LONG_LONG	8
#define	GS_SIZEOF_FLOAT		4
#define	GS_SIZEOF_DOUBLE	8

//	Size information to be places in bits 5 and 6 of type encoding bytes
//	in archives (bits 0 to 4 are used for basic type info and bit 7 is
//	used to mark cross-references to previously encoded objects).
#define	_GSC_S_SHT		_GSC_I16
#define	_GSC_S_INT		_GSC_I32
#define	_GSC_S_LNG		_GSC_I32
#define	_GSC_S_LNG_LNG	_GSC_I64

// Type definitions for types with known sizes.
typedef signed char gss8;
typedef unsigned char gsu8;
typedef signed short gss16;
typedef unsigned short gsu16;
typedef signed int gss32;
typedef unsigned int gsu32;
typedef signed long long gss64;
typedef unsigned long long gsu64;
typedef struct { gsu8 a16; } gss128;
typedef struct { gsu8 a16; } gsu128;
typedef float gsf32;
typedef double gsf64;

// Integer type with same size as a pointer
typedef	unsigned int gsaddr;

//	Do we have real 64-bit and 128-bit integers or are we just pretending.
#define GS_HAVE_I64  1
#define GS_HAVE_I128 0

#if defined(ALPHA) || (defined(MIPS) && (_MIPS_SIM == _ABIN32))
typedef long long smallret_t;
#else
typedef int smallret_t;
#endif

static inline gsu32 GSSwapI32(gsu32 in)
{
	union swap 
	{
		gsu32 num;
		gsu8  byt[4];
	} dst;
	
	union swap *src = (union swap*)&in;
	dst.byt[0] = src->byt[3];
	dst.byt[1] = src->byt[2];
	dst.byt[2] = src->byt[1];
	dst.byt[3] = src->byt[0];
	
	return dst.num;
}

static inline gsu16 GSSwapI16(gsu16 in)
{
	union swap 
	{
		gsu16 num;
		gsu8  byt[2];
	} dst;
	
	union swap *src = (union swap*)&in;
	dst.byt[0] = src->byt[1];
	dst.byt[1] = src->byt[0];
	
	return dst.num;
}


#if	GS_WORDS_BIGENDIAN

static inline gsu32 GSSwapBigI32ToHost(gsu32 in)	{ return in; }
static inline gsu32 GSSwapHostI32ToBig(gsu32 in)	{ return in; }
static inline gsu16 GSSwapHostI16ToBig(gsu16 in)	{ return in; }

#else

static inline gsu32 GSSwapBigI32ToHost(gsu32 in)	{ return GSSwapI32(in); }
static inline gsu32 GSSwapHostI32ToBig(gsu32 in)	{ return GSSwapI32(in); }
static inline gsu16 GSSwapBigI16ToHost(gsu16 in)	{ return GSSwapI16(in); }
static inline gsu16 GSSwapHostI16ToBig(gsu16 in)	{ return GSSwapI16(in); }

#endif

//*****************************************************************************
//
// 		Linux i386 
//
//*****************************************************************************

#if defined (i386) && defined (linux)

#define	__MacrosDefined__	1

#define	MFRAME_STACK_STRUCT	1
#define	MFRAME_STRUCT_BYREF	0
#define MFRAME_SMALL_STRUCT	0
#define MFRAME_ARGS_SIZE	8
#define MFRAME_RESULT_SIZE	116

#define MFRAME_GET_STRUCT_ADDR(ARGS, TYPES) \
((*(TYPES)==_C_STRUCT_B || *(TYPES)==_C_UNION_B || *(TYPES)==_C_ARY_B) ? \
 *(void**)(ARGS)->arg_ptr : (void*)0)

#define MFRAME_SET_STRUCT_ADDR(ARGS, TYPES, ADDR) \
({if (*(TYPES)==_C_STRUCT_B || *(TYPES)==_C_UNION_B || *(TYPES)==_C_ARY_B) \
	*(void**)(ARGS)->arg_ptr = (ADDR);})

#define MFRAME_ARGS int

#define MFRAME_INIT_ARGS(CUM, RTYPE)	\
((CUM) = (*(RTYPE)==_C_STRUCT_B || *(RTYPE)==_C_UNION_B || \
		  *(RTYPE)==_C_ARY_B) ? sizeof(void*) : 0)

#define MFRAME_ARG_ENCODING(CUM, TYPE, STACK, DEST) \
({  \
	const char* type = (TYPE); \
		int align = objc_alignof_type(type); \
			int size = objc_sizeof_type(type); \
				\
				(CUM) = ROUND((CUM), align); \
					(TYPE) = objc_skip_typespec(type); \
						sprintf((DEST), "%.*s%d", (TYPE)-type, type, (CUM)); \
							if (*(TYPE) == '+') \
								{ \
									(TYPE)++; \
								} \
							while (isdigit(*(TYPE))) \
								{ \
									(TYPE)++; \
								} \
							(DEST)=&(DEST)[strlen(DEST)]; \
								if ((*type==_C_STRUCT_B||*type==_C_UNION_B||*type==_C_ARY_B)&&size>2) \
									{ \
										(STACK) = (CUM) + ROUND(size, align); \
									} \
								else \
									{ \
										(STACK) = (CUM) + size; \
									} \
								(CUM) += ROUND(size, sizeof(void*)); \
})

#endif /* defined (i386) && defined (linux) */

//*****************************************************************************
//
// 		FreeBSD i386 
//
//*****************************************************************************

#ifdef FreeBSD_i386

#define	__MacrosDefined__	1

#define	MFRAME_STACK_STRUCT	0
#define	MFRAME_STRUCT_BYREF	0
#define	MFRAME_SMALL_STRUCT	0
#define MFRAME_ARGS_SIZE	8
#define MFRAME_RESULT_SIZE	116

#define MFRAME_GET_STRUCT_ADDR(ARGS, TYPES) \
((*(TYPES)==_C_STRUCT_B || *(TYPES)==_C_UNION_B || *(TYPES)==_C_ARY_B) ? \
 *(void**)((ARGS)->arg_regs + sizeof(void*)) : (void*)0)

#define MFRAME_SET_STRUCT_ADDR(ARGS, TYPES, ADDR) \
({if (*(TYPES)==_C_STRUCT_B || *(TYPES)==_C_UNION_B || *(TYPES)==_C_ARY_B) \
	*(void**)((ARGS)->arg_regs + sizeof(void*)) = (ADDR);})

#define MFRAME_ARGS int

#define MFRAME_INIT_ARGS(CUM, RTYPE)	\
((CUM) = (*(RTYPE)==_C_STRUCT_B || *(RTYPE)==_C_UNION_B || \
		  *(RTYPE)==_C_ARY_B) ? sizeof(void*) : 0)

#define MFRAME_ARG_ENCODING(CUM, TYPE, STACK, DEST) \
({  \
	const char* type = (TYPE); \
		int align = objc_alignof_type(type); \
			int size = objc_sizeof_type(type); \
				\
				(CUM) = ROUND((CUM), align); \
					(TYPE) = objc_skip_typespec(type); \
						sprintf((DEST), "%.*s%d", (TYPE)-type, type, (CUM)); \
							if (*(TYPE) == '+') (TYPE)++; \
								while (isdigit(*(TYPE))) \
									{ \
										(TYPE)++; \
									} \
								(DEST)=&(DEST)[strlen(DEST)]; \
									if ((*type==_C_STRUCT_B||*type==_C_UNION_B||*type==_C_ARY_B)&&size>2) \
										{ \
											(STACK) = (CUM) + ROUND(size, align); \
										} \
									else \
										{ \
											(STACK) = (CUM) + size; \
										} \
									(CUM) += ROUND(size, sizeof(void*)); \
})

#endif /* FreeBSD_i386 */

#ifdef PowerPC

// taken from GNUstep-base-1.6.0 by hns

/* See ../README for copyright */

/*
 * The first eight words of non-FP are in registers (offset 4 in frame).
 * The first 13 FP args are in registers (offset 40 in frame).
 * If the method returns a structure, it's address is passed as an invisible
 * first argument, so only seven words of non-FP are passed in the registers.
 * Structures are always passed by reference.
 * Floats are placed in the frame as doubles.
 */

#define MFRAME_STRUCT_BYREF     1
#define MFRAME_SMALL_STRUCT     0
#define MFRAME_ARGS_SIZE        144
#define MFRAME_RESULT_SIZE      16
#define MFRAME_FLT_IN_FRAME_AS_DBL      1

/*
 * Structures are passed by reference as an invisible first argument, so
 * they go in the first register space for non-FP arguments - at offset 4.
 */
#define MFRAME_GET_STRUCT_ADDR(ARGS, TYPES) \
((*(TYPES)==_C_STRUCT_B || *(TYPES)==_C_UNION_B || *(TYPES)==_C_ARY_B) ? \
 *(void**)(((char*)(ARGS))+4): (void*)0)

#define MFRAME_SET_STRUCT_ADDR(ARGS, TYPES, ADDR) \
({if (*(TYPES)==_C_STRUCT_B || *(TYPES)==_C_UNION_B || *(TYPES)==_C_ARY_B) \
	*(void**)(((char*)(ARGS))+4) = (ADDR);})

/*
 * Typedef for structure to keep track of argument info while processing
 * a method.
 */
typedef struct rs6000_args
{
	int int_args;         /* Number of integer arguments so far.          */
	int float_args;       /* Number of FP arguments so far.               */
	int regs_position;    /* The current position for non-FP args.        */
	int stack_position;   /* The current position in the stack frame.     */
} MFRAME_ARGS;


/*
 * Initialize a variable to keep track of argument info while processing a
 * method.  Keeps count of the number of arguments of each type seen and
 * the current offset in the non-FP registers.  This offset is adjusted
 * to take account of an invisible first argument used to return structures.
 */

#define MFRAME_INIT_ARGS(CUM, RTYPE) \
({ \
	(CUM).int_args = 0; \
		(CUM).float_args = 0; \
			(CUM).stack_position = 0; \
				(CUM).regs_position = \
				((*(RTYPE)==_C_STRUCT_B || *(RTYPE)==_C_UNION_B || *(RTYPE)==_C_ARY_B) ? \
				 sizeof(void*) : 4); \
})

#define MFRAME_ARG_ENCODING(CUM, TYPE, STACK, DEST) \
({  \
	const char* type = (TYPE); \
		\
		(TYPE) = objc_skip_typespec(type); \
			if (*type == _C_FLT || *type == _C_DBL) \
				{ \
					if (++(CUM).float_args > 13) \
						{ \
							(CUM).stack_position += ROUND ((CUM).stack_position, \
														   __alignof__(double)); \
															   sprintf((DEST), "%.*s%d", (TYPE)-type, type, (CUM).stack_position); \
																   (STACK) = ROUND ((CUM).stack_position, sizeof(double)); \
						} \
					else \
						{ \
							sprintf((DEST), "%.*s+%d", (TYPE)-type, type, \
									40 + sizeof (double) * ((CUM).float_args - 1)); \
						} \
				} \
			else \
				{ \
					int align, size; \
						\
						if (*type == _C_STRUCT_B || *type == _C_UNION_B || *type == _C_ARY_B) \
							{ \
								align = __alignof__(void*); \
									size = sizeof (void*); \
							} \
						else \
							{ \
								align = __alignof__(int); \
									size = objc_sizeof_type (type); \
							} \
						\
						if (++(CUM).int_args > 8) \
							{ \
								(CUM).stack_position += ROUND ((CUM).stack_position, align); \
									sprintf((DEST), "%.*s%d", (TYPE)-type, type, (CUM).stack_position); \
										(STACK) = ROUND ((CUM).stack_position, size); \
							} \
						else \
							{ \
								(CUM).regs_position = ROUND((CUM).regs_position, align); \
									/* FIXME: This mostly accounts for the addition in mframe_arg_addr \
									due to WORDS_BIGENDIAN */ \
									if (*type == _C_STRUCT_B && objc_sizeof_type(type) < sizeof(int)) \
										(CUM).regs_position -= sizeof(int) - objc_sizeof_type(type); \
											sprintf((DEST), "%.*s+%d", (TYPE)-type, type, (CUM).regs_position); \
												if (*type == _C_STRUCT_B && objc_sizeof_type(type) < sizeof(int)) \
													(CUM).regs_position += sizeof(int) - objc_sizeof_type(type); \
														(CUM).regs_position += ROUND (size, align); \
							} \
				} \
			(DEST)=&(DEST)[strlen(DEST)]; \
				if (*(TYPE) == '+') \
					{ \
						(TYPE)++; \
					} \
				while (isdigit(*(TYPE))) \
					{ \
						(TYPE)++; \
					} \
})

#endif

//*****************************************************************************
//
// Linux ARM (e.g. Zaurus 5500)
// added by H. Nikolaus Schaller <hns@computer.org>
// based on
// http://www.arm.com/armwww.ns4/img/12-Technical+Specs-ARM+Thumb+Procedure+Call+Standard+PDF/$File/ATPCSA05.pdf?OpenElement
//
//*****************************************************************************

#if defined (Linux_ARM)

/* The Stack Frame of Linux_ARM (Sharp Zaurus)
from http://www.redhat.com/docs/manuals/gnupro/GNUPro-Toolkit-99r1/pdf/6_embed.pdf

- Structures that are less than or equal to 32 bits in length are passed as values.
- Structures that are greater than 32 bits in length are passed as pointers.
	? how small structs are returned
- The stack grows downwards from high addresses to low addresses.
- A leaf function need not allocate a stack frame if it does not need one.
- A frame pointer need not be allocated.
- The stack pointer shall always be aligned to 4 byte boundaries.
- The stack pointer always points to the lowest addressed word currently stored on the stack.
- Arguments start at the frame pointer and above (for fixed number of arguments)
- For fixed number of arguments, the first arguments are passed in registers
- For stack frames with a variable number of arguments:
- there is a save area starting at FP for anonymous parms passed in registers
- the size of this area may be zero
	? Obj-C always uses the variable argument stack frame and therefore allocates a save area
- Floats and integer-like values are returned in register, r0
- A type is integer-like if its size is less than or equal to one word and if the type is a
	structure, union or array, then all of its addressable sub-fields must have an offset of
	zero (i.e. union or bitfields)
- All other values are returned by placing them into a suitably sized area of memory
	provided for this purpose by the functionÕs caller. A pointer to this area of memory is
	passed to the function as a hidden first argument, generated at compile time.
- arguments of type float are widened to double
- Character, short, pointer and other integral values occupy one word in an argument list
- Character and short values are widened by the C compiler during argument marshalling.
- A structure always occupies an integral number of words
	Argument values are collated in the order written in the source program The first four
	words of the argument values are loaded into r0 through r3, and the remainder are
	pushed on to the stack in reverse order (so that arguments later in the argument list
											 have higher addresses than those earlier in the argument list). As a consequence, a FP
	value can be passed in integer registers, or even split between an integer register and
	the stack.

	But how does an Objective-C stack frame look like?

Analysis has revealed the following model as being passed to forward:: (which seems to be different
																		to the frame if the method
																		is implemented!)

	Call for [obj method:arg1 withArg:arg2]

+-------+
+48     ! arg2  !	variable number of words (e.g. for structs by value)
+-------+
+44     ! arg1  !	variable number of words (e.g. for structs by value)
+-------+
+40     ! _cmd  !
+-------+
+36     !  ?    !
+-------+
+32	    ! PC    !	r7? return address
+-------+
+28	    !  ?    !	r6?
+-------+
+24	    !  ?    !	r5?
+-------+
+20	    ! copy3 !   r4?
+-------+
+16    	! copy2 !   r3?
+-------+
+12	    ! copy1 !	r2? copy of the first 3 words starting at _cmd, therefore copy1==_cmd
+-------+
+8	    !  obj  !	r1? the self variable
+-------+
	opt.    ! rptr  !	optional pointer where a struct (by value) is to be retured; if present, relative offsets of all other arguments change
+-------+
+4      ! copy0 !   r0? a copy of the next word, i.e. either 'self' or the struct return pointer
+-------+
frame:  ! aptr  !	argument pointer points to the _cmd argument
+-------+

frame is the address passed to - (retval_t) forward:(SEL)aSel :(arglist_t)frame

	Type signatures use
	i+8		to access frame + 8
	i8		to access (aptr) + 8

NOTE: gcc documentation is giving a good description (if you have learned to interpret it correctly)

	__builtin_apply_args ()
	This built-in function returns a pointer of type void * to data describing how to perform a call with the same arguments as were passed to the current function.
	The function saves the arg pointer register, structure value address, and all registers that might be used to pass arguments to a function into a block of memory allocated on the stack. Then it returns the address of that block.

i.e.
* the void * structure contains
  - arg-pointer-register: a pointer to the argument values pushed on the stack (this is not necessarily in the same data block!)
  - optionally structure value address
  - all registers that might be used to pass arguments (this is CPU specific)

	__builtin_apply (function, arguments, size)
	This built-in function invokes function (type void (*)()) with a copy of the parameters described by arguments (type void *) and size (type int).
	The value of arguments should be the value returned by __builtin_apply_args. The argument size specifies the size of the stack argument data, in bytes.

* i.e. the arguments descriptor as defined above
* size specifies how many bytes should be copied to the stack - it does not need to include the register arguments!

	This function returns a pointer of type void * to data describing how to return whatever value was returned by function. The data is saved in a block of memory allocated on the stack.

	It is not always simple to compute the proper value for size. The value is used by __builtin_apply to compute the amount of data that should be pushed on the stack and copied from the incoming argument area.

* it should be possible to derive it properly from the @encode()


	__builtin_return (result)
	This built-in function returns the value described by result from the containing function. You should specify, for result, a value returned by __builtin_apply.

	*/

#define	__MacrosDefined__	1

#define	MFRAME_STACK_STRUCT	1	// functions return structs by passing a pointer as an additional first argument
#define	MFRAME_STRUCT_BYREF	0	// function struct arguments are passed by pointer on stack (and not a pointer)
#define	MFRAME_SMALL_STRUCT	4	// small structs up to 1 word (4 bytes) are returned in a register and not on stack
#define	MFRAME_ARGS_SIZE	128	// just be safe
#define	MFRAME_RESULT_SIZE	128
// #define MFRAME_FLT_IN_FRAME_AS_DBL - floats are converted to double unless passed to varargs etc.

// argframe contains 2 words before first argument starts

#define MFRAME_GET_STRUCT_ADDR(ARGS, TYPES) \
((*(TYPES) ==_C_STRUCT_B || *(TYPES)==_C_UNION_B || *(TYPES)==_C_ARY_B) ? \
 *(void**)((ARGS)+4)->arg_ptr : (void*)0)

#define MFRAME_SET_STRUCT_ADDR(ARGS, TYPES, ADDR) \
({if (*(TYPES)==_C_STRUCT_B || *(TYPES)==_C_UNION_B || *(TYPES)==_C_ARY_B) \
	*(void**)((ARGS)+4)->arg_ptr = (ADDR);})

#define MFRAME_ARGS int

#define MFRAME_INIT_ARGS(CUM, RTYPE)	\
((CUM) = (*(RTYPE)==_C_STRUCT_B||*(RTYPE)==_C_UNION_B||*(RTYPE)==_C_ARY_B)?-7:0)	// ROUND(): (-7+sizeof(id)-1)/sizeof(id) == -1

#define MFRAME_ARG_ENCODING(CUM, TYPE, STACK, DEST) \
({  \
	const char* type = (TYPE); \
		int align = objc_alignof_type(type); \
			int size = objc_sizeof_type(type); \
				\
				(CUM) = ROUND((CUM), align); \
					(TYPE) = objc_skip_typespec(type); \
						if((CUM) >=0 /*>=4*/) \
							sprintf((DEST), "%.*s%d", (TYPE)-type, type, (CUM)); /* other parameter */ \
								else \
									sprintf((DEST), "%.*s+%d", (TYPE)-type, type, (CUM)<0?12:8), (CUM)=0; /* self */ \
										if (*(TYPE) == '+') \
											{ \
												(TYPE)++; \
											} \
										while (isdigit(*(TYPE))) \
											{ \
												(TYPE)++; \
											} \
										(DEST)=&(DEST)[strlen(DEST)]; \
											(STACK) = (CUM) + size; \
												(CUM) += ROUND(size, sizeof(void*)); \
})

#endif /* Linux_ARM */

#endif /* __mframe_h_mySTEP_BASE_INCLUDE */

