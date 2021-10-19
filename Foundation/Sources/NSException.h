/* 
   NSException.h

   Interface for NSException

   Copyright (C) 1995, 1996 Free Software Foundation, Inc.

   Author:	Adam Fedor <fedor@boulder.colorado.edu>
   Date:	1995
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSException
#define _mySTEP_H_NSException

#import <Foundation/NSString.h>

@class NSDictionary;

@interface NSException : NSObject  <NSCoding, NSCopying>
{    
	NSString *e_name;
	NSString *e_reason;
	NSDictionary *e_info;
}

+ (NSException *) exceptionWithName:(NSString *) name
							 reason:(NSString *) reason
						   userInfo:(NSDictionary *) userInfo;
+ (/*volatile*/ void) raise:(NSString *) name
				 format:(NSString *) format, ...;
+ (/*volatile*/ void) raise:(NSString *) name
				 format:(NSString *) format
			  arguments:(va_list) argList;

- (NSArray *) callStackReturnAddresses;
- (id) initWithName:(NSString *) name 
			 reason:(NSString *) reason 
		   userInfo:(NSDictionary *) userInfo;
- (NSString *) name;
- (/*volatile*/ void) raise;
- (NSString *) reason;
- (NSDictionary *) userInfo;

@end


extern NSString *NSInconsistentArchiveException;		// Common exceptions
extern NSString *NSGenericException;
extern NSString *NSInternalInconsistencyException;
extern NSString *NSInvalidArgumentException;
extern NSString *NSMallocException;
extern NSString *NSRangeException;
extern NSString *NSCharacterConversionException;

extern NSString *NSObjectInaccessibleException;
extern NSString *NSObjectNotAvailableException;
extern NSString *NSDestinationInvalidException;
extern NSString *NSPortTimeoutException;
extern NSString *NSInvalidSendPortException;
extern NSString *NSInvalidReceivePortException;
extern NSString *NSPortSendException;
extern NSString *NSPortReceiveException;

// Exception handler definitions (local stack object created by NS_DURING)

#include <setjmp.h>

typedef struct _NSHandler2
{
    jmp_buf jumpState;						// place to longjmp to 
    struct _NSHandler2 *next;				// ptr to next handler
    NSException *exception;
} NSHandler2;

typedef /*volatile*/ void NSUncaughtExceptionHandler(NSException *exception);

extern NSUncaughtExceptionHandler *_NSUncaughtExceptionHandler;
#define NSGetUncaughtExceptionHandler() _NSUncaughtExceptionHandler
#define NSSetUncaughtExceptionHandler(proc) \
			(_NSUncaughtExceptionHandler = (proc))

/* 
   NS_DURING, NS_HANDLER and NS_ENDHANDLER are always used as:

      NS_DURING
	      some code which might raise an error
	  NS_HANDLER
	      code that will be jumped to if an error occurs
	  NS_ENDHANDLER

   If any error is raised within the first block of code, the second block
   of code will be jumped to.  Typically, this code will clean up any
   resources allocated in the routine, possibly case on the error code
   and perform special processing, and default to RERAISE the error to
   the next handler.  Within the scope of the handler, a local variable
   called exception holds information about the exception raised.

   It is illegal to exit the first block of code by any other means than
   NS_VALUERETURN, NS_VOIDRETURN, or just falling out the bottom.
*/

// private support routines.  Do not call directly. 
extern void _NSAddHandler2( NSHandler2 *handler );
extern void _NSRemoveHandler2( NSHandler2 *handler );

#define NS_DURING { NSHandler2 NSLocalHandler;			\
		    _NSAddHandler2(&NSLocalHandler);		\
		    if( !setjmp(NSLocalHandler.jumpState) ) {

#define NS_HANDLER _NSRemoveHandler2(&NSLocalHandler); } else { \
		    NSException *localException;               \
		    localException = NSLocalHandler.exception;

#define NS_ENDHANDLER }}

#define NS_VALUERETURN(val, type)  do { type temp = (val);	\
			_NSRemoveHandler2(&NSLocalHandler);	\
			return(temp); } while (0)
#define NS_VALRETURN(val)  NS_VALUERETURN(val, typeof(val))

#define NS_VOIDRETURN	do { _NSRemoveHandler2(&NSLocalHandler);	\
			return; } while (0)

//
//	Asserts are not compiled in if NS_BLOCK_ASSERTIONS is defined
//

@interface NSAssertionHandler : NSObject
{
}

+ (NSAssertionHandler *) currentHandler;
- (void) handleFailureInMethod:(SEL) sel object:(id) object file:(NSString *) file lineNumber:(NSInteger) line description:(NSString *) desc, ...;
- (void) handleFailureInFunction:(NSString *) name file:(NSString *) file lineNumber:(NSInteger) line description:(NSString *) desc, ...;

@end


#ifndef NS_BLOCK_ASSERTIONS

#define _NSAssertArgs(condition, desc, args...)			\
    do {							\
	if (!(condition)) {					\
		[[NSAssertionHandler currentHandler] 		\
			handleFailureInMethod: _cmd 			\
		object: self 					\
		file: [NSString stringWithUTF8String: __FILE__] 	\
		lineNumber: __LINE__ 				\
		description: (desc) , ## args]; 			\
	}							\
    } while(0)

#define _NSCAssertArgs(condition, desc, args...)		\
    do {							\
	if (!(condition)) {					\
	    [[NSAssertionHandler currentHandler] 		\
	    handleFailureInFunction: [NSString stringWithUTF8String: __PRETTY_FUNCTION__] 				\
	    file: [NSString stringWithUTF8String: __FILE__] 		\
	    lineNumber: __LINE__ 				\
	    description: (desc) , ## args]; 			\
	}							\
    } while(0)

#define NSAssert5(condition,desc,arg1,arg2,arg3,arg4,arg5) _NSAssertArgs((condition), (desc), (arg1), (arg2), (arg3), (arg4), (arg5))
#define NSAssert4(condition, desc, arg1, arg2, arg3, arg4) _NSAssertArgs((condition), (desc), (arg1), (arg2), (arg3), (arg4))
#define NSAssert3(condition, desc, arg1, arg2, arg3) _NSAssertArgs((condition), (desc), (arg1), (arg2), (arg3))
#define NSAssert2(condition, desc, arg1, arg2) _NSAssertArgs((condition), (desc), (arg1), (arg2))
#define NSAssert1(condition, desc, arg1) _NSAssertArgs((condition), (desc), (arg1))
#define NSAssert(condition, desc, args...) _NSAssertArgs((condition), (desc), ##args)

#define NSCAssert5(condition,desc,arg1,arg2,arg3,arg4,arg5) _NSCAssertArgs((condition), (desc), (arg1), (arg2), (arg3), (arg4), (arg5))
#define NSCAssert4(condition, desc, arg1, arg2, arg3, arg4)	_NSCAssertArgs((condition), (desc), (arg1), (arg2), (arg3), (arg4))
#define NSCAssert3(condition, desc, arg1, arg2, arg3) _NSCAssertArgs((condition), (desc), (arg1), (arg2), (arg3))
#define NSCAssert2(condition, desc, arg1, arg2)	_NSCAssertArgs((condition), (desc), (arg1), (arg2))
#define NSCAssert1(condition, desc, arg1) _NSCAssertArgs((condition), (desc), (arg1))
#define NSCAssert(condition, desc, args...) _NSCAssertArgs((condition), (desc), ## args)

#else

#define NSAssert5(condition, desc, arg1, arg2, arg3, arg4, arg5) //
#define NSAssert4(condition, desc, arg1, arg2, arg3, arg4)	//
#define NSAssert3(condition, desc, arg1, arg2, arg3) //
#define NSAssert2(condition, desc, arg1, arg2) //
#define NSAssert1(condition, desc, arg1) //
#define NSAssert(condition, desc, args...) //

#define NSCAssert5(condition, desc, arg1, arg2, arg3, arg4, arg5) //
#define NSCAssert4(condition, desc, arg1, arg2, arg3, arg4)	//
#define NSCAssert3(condition, desc, arg1, arg2, arg3) //
#define NSCAssert2(condition, desc, arg1, arg2)	//
#define NSCAssert1(condition, desc, arg1) //
#define NSCAssert(condition, desc, args...) //

#endif /* NS_BLOCK_ASSERTIONS */

#define NSParameterAssert(condition) _NSAssertArgs((condition), @"Invalid parameter not satisfying: %s", #condition)
#define NSCParameterAssert(condition) _NSCAssertArgs((condition), @"Invalid parameter not satisfying: %s", #condition)

#endif /* _mySTEP_H_NSException */
