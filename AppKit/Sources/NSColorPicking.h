/* 
   NSColorPicking.h

   Protocols for picking colors

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: 1997
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007  
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSColorPicking
#define _mySTEP_H_NSColorPicking

@class NSColor;
@class NSColorPanel;
@class NSView;
@class NSImage;
@class NSButtonCell;
@class NSColorList;

@protocol NSColorPickingCustom

- (int) currentMode;
- (NSView *) provideNewView:(BOOL) firstRequest;
- (void) setColor:(NSColor *) aColor;
- (BOOL) supportsMode:(int) mode;

@end


@protocol NSColorPickingDefault

- (void) alphaControlAddedOrRemoved:(id) sender;
- (void) attachColorList:(NSColorList *) aColorList;				// Color Lists
- (void) detachColorList:(NSColorList *) aColorList;
- (id) initWithPickerMask:(int) mask colorPanel:(NSColorPanel *) colorPanel;
- (void) insertNewButtonImage:(NSImage *) newImage in:(NSButtonCell *) newButtonCell;
- (NSImage *) provideNewButtonImage;
- (void) setMode:(int) mode;
- (void) viewSizeChanged:(id) sender;

@end

#endif /* _mySTEP_H_NSColorPicking */
