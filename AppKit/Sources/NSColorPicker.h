/* 
   NSColorPicker.h

   Abstract superclass of custom color pickers

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007   
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSColorPicker
#define _mySTEP_H_NSColorPicker

#import <Foundation/NSObject.h>
#import <AppKit/NSColorPicking.h>

@class NSColorPanel;
@class NSColorList;
@class NSImage;
@class NSButtonCell;

@interface NSColorPicker : NSObject <NSColorPickingDefault>
{
	NSColorPanel *_colorPanel;
}

- (void) attachColorList:(NSColorList *) colorList;
- (NSColorPanel *) colorPanel;
- (void) detachColorList:(NSColorList *) colorList;
- (id) initWithPickerMask:(int) aMask colorPanel:(NSColorPanel *) colorPanel;
- (void) insertNewButtonImage:(NSImage *) newImage in:(NSButtonCell *) newButtonCell;
- (NSImage *) provideNewButtonImage;
- (void) setMode:(int) mode;
- (void) viewSizeChanged:(id) sender;

@end

#endif /* _mySTEP_H_NSColorPicker */
