//
//  NSPathCell.h
//  AppKit
//
//  Created by Fabian Spillner on 27.11.07. Further Developement by Jens Idelberger on 09.03.09
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <AppKit/NSActionCell.h>

@class NSPathComponentCell; 
@class NSOpenPanel; 
@class NSMenu; 

enum {
	NSPathStyleStandard,
	NSPathStyleNavigationBar,
	NSPathStylePopUp,
};
typedef NSInteger NSPathStyle;

@interface NSPathCell : NSActionCell 
{
	NSArray *_allowedTypes;
	NSColor *_backgroundColor;
	NSPathComponentCell *_clickedPathComponentCell; 
	id _delegate; 
	NSArray *_pathComponentCells; 
	NSRect *_rects;
	SEL _doubleAction; 
	NSPathStyle _pathStyle;
	NSCell *_dontTruncateCell;
	BOOL _needsSizing;
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
// - (NSString *) placeholderString;	// inherited from superclass
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
// - (void) setPlaceholderString:(NSString *) pStr;	// inherited from superclass
- (void) setURL:(NSURL *) url; 
- (NSURL *) URL; 

@end


@interface NSObject (NSPathCellDelegate)

- (void) pathCell:(NSPathCell *) sender willDisplayOpenPanel:(NSOpenPanel *) openPanel; 
- (void) pathCell:(NSPathCell *) sender willPopUpMenu:(NSMenu *) menu; 

@end
