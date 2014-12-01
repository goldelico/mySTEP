/*
	NSStatusBar.h
	myPDA
 
	Created by Dr. H. Nikolaus Schaller on Sat Apr 05 2003.
	Copyright (c) 2003 DSITRI. All rights reserved.
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	12. December 2007 - aligned with 10.5
*/

#import <Foundation/Foundation.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuView.h>

@class NSStatusItem;

@interface NSStatusBar : NSObject
{
	NSMenuView *menuView;
}

#ifndef NSSquareStatusItemLength
#define NSSquareStatusItemLength ((CGFloat) -2.0)		// length == thickness
#define NSVariableStatusItemLength ((CGFloat) -1.0)	// variable
#endif

+ (NSStatusBar *) systemStatusBar;

- (BOOL) isVertical;	// NO
- (void) removeStatusItem:(NSStatusItem *) item;
- (NSStatusItem *) statusItemWithLength:(CGFloat) length;
- (CGFloat) thickness;	// 22 on MacOS X

@end
