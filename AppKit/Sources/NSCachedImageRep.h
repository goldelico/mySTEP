/* 
   NSCachedImageRep.h

   Cached image representation.

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007   
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSCachedImageRep
#define _mySTEP_H_NSCachedImageRep

#import <AppKit/NSImageRep.h>
#import <AppKit/NSGraphics.h>

@class NSWindow;

@interface NSCachedImageRep : NSImageRep
{
    NSPoint _origin;
	NSWindow *_window;
}

- (id) initWithSize:(NSSize) aSize depth:(NSWindowDepth) aDepth separate:(BOOL) separate alpha:(BOOL) alpha;
- (id) initWithWindow:(NSWindow *) aWindow rect:(NSRect) aRect;
- (NSRect) rect;
- (NSWindow *) window;

@end

#endif /* _mySTEP_H_NSCachedImageRep */
