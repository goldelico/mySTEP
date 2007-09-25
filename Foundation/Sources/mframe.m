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

