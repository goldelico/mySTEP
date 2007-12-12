/*
	NSStatusItem.h
	myPDA

	Created by Dr. H. Nikolaus Schaller on Sat Apr 05 2003.
	Copyright (c) 2003 DSITRI. All rights reserved.
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	12. December 2007 - aligned with 10.5
*/

#import <Foundation/Foundation.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSStatusBar.h>
#import <AppKit/NSView.h>
#import <AppKit/NSImage.h>

@interface NSStatusItem : NSObject
{
	NSMenuItem *menuItem;
	NSStatusBar *statusBar;
	NSAttributedString *attributedTitle;
	NSView *view;
	float length;
	BOOL highlightedMode;
}

- (SEL) action;
- (NSImage *) alternateImage; 
- (NSAttributedString *) attributedTitle;
- (SEL) doubleAction;
- (void) drawStatusBarBackgroundInRect:(NSRect) rect withHighlight:(BOOL) flag; 
- (BOOL) highlightMode;
- (NSImage *) image;
- (BOOL) isEnabled;
- (CGFloat) length;
- (NSMenu *) menu;
- (void) popUpStatusItemMenu:(NSMenu *) menu; 
- (void) sendActionOn:(NSInteger) mask;
- (void) setAction:(SEL) action;
- (void) setAlternateImage:(NSImage *) img;
- (void) setAttributedTitle:(NSAttributedString *) title;
- (void) setDoubleAction:(SEL) sel; 
- (void) setEnabled:(BOOL) flag;
- (void) setHighlightMode:(BOOL) highlightMode;
- (void) setImage:(NSImage *) image;
- (void) setLength:(CGFloat) length;
- (void) setMenu:(NSMenu *) menu;
- (void) setTarget:(id) target;
- (void) setTitle:(NSString *) title;
- (void) setToolTip:(NSString *) toolTip;
- (void) setView:(NSView *) view;
- (NSStatusBar *) statusBar;
- (id) target;
- (NSString *) title;
- (NSString *) toolTip;
- (NSView *) view;

@end
