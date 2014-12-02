/*
   NSButton.h

   Button control class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007  
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	6. November 2007 - aligned with 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSButton
#define _mySTEP_H_NSButton

#import <AppKit/NSControl.h>
#import <AppKit/NSButtonCell.h>

@class NSAttributedString;
@class NSString;
@class NSEvent;

@interface NSButton : NSControl  <NSCoding>

- (BOOL) allowsMixedState;
- (NSImage *) alternateImage;
- (NSString *) alternateTitle;
- (NSAttributedString *) attributedAlternateTitle;
- (NSAttributedString *) attributedTitle;
- (NSBezelStyle) bezelStyle;
- (void) getPeriodicDelay:(float *) delay interval:(float *) interval;
- (void) highlight:(BOOL) flag;							// Drawing
- (NSImage *) image;
- (NSCellImagePosition) imagePosition;
- (BOOL) isBordered;									// Graphic attributes
- (BOOL) isTransparent;
- (NSString *) keyEquivalent;							// Key equivalent
- (NSUInteger) keyEquivalentModifierMask;
- (BOOL) performKeyEquivalent:(NSEvent *) event;
- (void) setAllowsMixedState:(BOOL) flag;
- (void) setAlternateImage:(NSImage *) anImage;			// Images
- (void) setAlternateTitle:(NSString *) aString;			// Titles 
- (void) setAttributedAlternateTitle:(NSAttributedString *) aString;
- (void) setAttributedTitle:(NSAttributedString *) aString;
- (void) setBezelStyle:(NSBezelStyle) bezelStyle;
- (void) setBordered:(BOOL) flag;
- (void) setButtonType:(NSButtonType) aType;				// Set button type
- (void) setImage:(NSImage *) anImage;
- (void) setImagePosition:(NSCellImagePosition) aPosition;
- (void) setKeyEquivalent:(NSString *) aKeyEquivalent;
- (void) setKeyEquivalentModifierMask:(NSUInteger) mask;
- (void) setNextState;
- (void) setPeriodicDelay:(float) delay interval:(float) interval;
- (void) setShowsBorderOnlyWhileMouseInside:(BOOL) flag;
- (void) setSound:(NSSound *) sound;
- (void) setState:(NSInteger) value;							// Button state
- (void) setTitle:(NSString *) aString;
- (void) setTitleWithMnemonic:(NSString *) aString;
- (void) setTransparent:(BOOL) flag;
- (BOOL) showsBorderOnlyWhileMouseInside;
- (NSSound *) sound;
- (NSInteger) state;
- (NSString *) title;

@end

#endif /* _mySTEP_H_NSButton */
