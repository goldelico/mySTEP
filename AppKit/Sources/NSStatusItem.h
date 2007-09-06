//
//  NSStatusItem.h
//  myPDA
//
//  Created by Dr. H. Nikolaus Schaller on Sat Apr 05 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSStatusBar.h>
#import <AppKit/NSView.h>
#import <AppKit/NSImage.h>

@interface NSStatusItem : NSObject {
	NSMenuItem *menuItem;
	NSStatusBar *statusBar;
	NSAttributedString *attributedTitle;
	float length;
	BOOL highlightedMode;
	NSView *view;
}

- (SEL) action;
- (NSAttributedString *) attributedTitle;
- (BOOL) highlightMode;
- (NSImage *) image;
- (BOOL) isEnabled;
- (float) length;
- (NSMenu *) menu;
- (void) sendActionOn:(int) mask;
- (void) setAction:(SEL) action;
- (void) setAttributedTitle:(NSAttributedString *) title;
- (void) setEnabled:(BOOL) flag;
- (void) setHighlightMode:(BOOL) highlightMode;
- (void) setImage:(NSImage *) image;
- (void) setLength:(float) length;
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
