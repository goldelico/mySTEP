/* 
   NSCursor.h

   Cursor class

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSCursor
#define _mySTEP_H_NSCursor

#import <Foundation/NSObject.h>

@class NSColor;
@class NSImage;
@class NSEvent;

@interface NSCursor : NSObject
{
@public
	NSImage *_image;
	NSPoint _hotSpot;
//	void *_backendPrivate;	// X11 Cursor *
@protected
	int _characterCode;
	BOOL _isSetOnMouseEntered;
	BOOL _isSetOnMouseExited;
}

+ (NSCursor *) arrowCursor;
+ (NSCursor *) closedHandCursor;
+ (NSCursor *) crosshairCursor;
+ (NSCursor *) currentCursor;
+ (NSCursor *) disappearingItemCursor;
+ (void) hide;
+ (NSCursor *) IBeamCursor;
+ (BOOL) isHiddenUntilMouseMoves;
+ (NSCursor *) openHandCursor;
+ (NSCursor *) pointingHandCursor;
+ (void) pop;
+ (NSCursor *) resizeDownCursor;
+ (NSCursor *) resizeLeftCursor;
+ (NSCursor *) resizeLeftRightCursor;
+ (NSCursor *) resizeRightCursor;
+ (NSCursor *) resizeUpCursor;
+ (NSCursor *) resizeUpDownCursor;
+ (void) setHiddenUntilMouseMoves:(BOOL) flag;
+ (void) unhide;

- (NSPoint) hotSpot;
- (NSImage *) image;
- (id) initWithImage:(NSImage *) image
 foregroundColorHint:(NSColor *) fg
 backgroundColorHint:(NSColor *) bg
			 hotSpot:(NSPoint) spot;
- (id) initWithImage:(NSImage *) image
			 hotSpot:(NSPoint) spot;
- (BOOL) isSetOnMouseEntered;
- (BOOL) isSetOnMouseExited;
- (void) mouseEntered:(NSEvent *) event;					// Setting the Cursor
- (void) mouseExited:(NSEvent *) event;
- (void) pop;
- (void) push;
- (void) set;
- (void) setOnMouseEntered:(BOOL) flag;
- (void) setOnMouseExited:(BOOL) flag;

@end

#endif /* _mySTEP_H_NSCursor */
