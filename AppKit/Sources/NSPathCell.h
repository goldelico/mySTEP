//
//  NSPathCell.h
//  AppKit
//
//  Created by Fabian Spillner on 27.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <AppKit/NSActionCell.h>

@class NSPathComponentCell; 

enum {
	NSPathStyleStandard,
	NSPathStyleNavigationBar,
	NSPathStylePopUp,
};
typedef NSInteger NSPathStyle;

@interface NSPathCell : NSActionCell 
{

}

+ (Class) pathComponentCellClass;

- (NSArray *) allowedTypes;
- (NSColor *) backgroundColor;
- (NSPathComponentCell *) clickedPathComponentCell; 
- (id) delegate; 
- (SEL) doubleAction; 
- (void) mouseEntered:(NSEvent *) evt withFrame:(NSRect) frame inView:(NSView *) view;
- (void) mouseExited:(NSEvent *) evt withFrame:(NSRect) frame inView:(NSView *) view;
- (NSPathComponentCell *) pathComponentCellAtPoint:(NSPoint) pt withFrame:(NSRect) rect inView:(NSView *) view;
- (NSArray *) pathComponentCells; 
- (NSPathStyle) pathStyle;
- (NSAttributedString *) placeholderAttributedString;
- (NSString *) placeholderString;
- (NSRect) rectOfPathComponentCell:(NSPathComponentCell *) c withFrame:(NSRect) rect inView:(NSView *) view;
- (void) setAllowedTypes:(NSArray *) types;
- (void) setBackgroundColor:(NSColor *) col;
- (void) setControlSize:(NSControlSize) controlSize; 
- (void) setDelegate:(id) delegate; 
- (void) setDoubleAction:(SEL) sel; 
- (void) setObjectValue:(id <NSCopying>) obj;
- (void) setPathComponentCells:(NSArray *) cells; 
- (void) setPathStyle:(NSPathStyle) pathStyle; 
- (void) setPlaceholderAttributedString:(NSAttributedString *) attrStr;
- (void) setPlaceholderString:(NSString *) pStr;
- (void) setURL:(NSURL *) url; 
- (NSURL *) URL; 

@end
