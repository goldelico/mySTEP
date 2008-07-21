/* Interface for NSProtocolChecker for GNUStep
   Copyright (C) 1995 Free Software Foundation, Inc.

   Written by:  Mike Kienenberger
   Date: Jun 1998
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

   Fabian Spillner, July 2008 - API revised to be compatible to 10.5

   This file is part of the GNUstep Base Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
   */ 

#ifndef __NSProtocolChecker_h_GNUSTEP_BASE_INCLUDE
#define __NSProtocolChecker_h_GNUSTEP_BASE_INCLUDE

#import <Foundation/NSObject.h>

@interface NSProtocolChecker : NSObject
{
	Protocol *_protocol;
	NSObject *_target;
}

+ (id) protocolCheckerWithTarget:(NSObject *) anObject
						protocol:(Protocol *) aProtocol;

- (id) initWithTarget:(NSObject *) anObject protocol:(Protocol *) aProtocol;
- (Protocol *) protocol;
- (NSObject *) target;

@end

#endif
