//
//  NSStatusBar.h
//  myPDA
//
//  Created by Dr. H. Nikolaus Schaller on Sat Apr 05 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuView.h>

@class NSStatusItem;

@interface NSStatusBar : NSObject
{
	NSMenuView *menuView;
}

#ifndef NSSquareStatusItemLength
#define NSSquareStatusItemLength ((float) -2.0)		// length == thickness
#define NSVariableStatusItemLength ((float) -1.0)	// variable
#endif

+ (NSStatusBar *) systemStatusBar;
- (BOOL) isVertical;	// NO
- (void) removeStatusItem:(NSStatusItem *) item;
- (NSStatusItem *) statusItemWithLength:(float) length;
- (float) thickness;	// 22 on MacOS X

@end
