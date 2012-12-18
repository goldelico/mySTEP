/* 
   NSScreen.h

   Class representing a physical display

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSScreen
#define _mySTEP_H_NSScreen

#import <Foundation/NSObject.h>
#import <AppKit/NSGraphics.h>

@class NSArray;
@class NSDictionary;
@class NSMutableDictionary;



@interface NSScreen : NSObject
{
	NSMutableDictionary *_device;
}

+ (NSScreen *) deepestScreen;
+ (NSScreen *) mainScreen;
+ (NSArray *) screens;

- (NSWindowDepth) depth;
- (NSDictionary *) deviceDescription;
- (NSRect) frame;
- (const NSWindowDepth *) supportedWindowDepths;
- (CGFloat) userSpaceScaleFactor;
- (NSRect) visibleFrame;

@end

#endif /* _mySTEP_H_NSScreen */
