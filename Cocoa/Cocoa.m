/* 
   Cocoa.m

   mySTEP Cocoa Library global include file

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  H.Nikolaus Schaller <hns@computer.org>
   Date:	2003
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Cocoa/Cocoa.h>

void __dummy(void)
{
	[NSString class];	// reference Foundation
	[NSWindow class];	// reference AppKit
//	[NSWindow class];	// reference CoreData
}
