//
//  NSPathControl.h
//  AppKit
//
//  Created by Fabian Spillner on 29.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <AppKit/NSControl.h>
#import <AppKit/NSDragging.h>
#import <AppKit/NSPathCell.h>

@class NSColor, NSPathComponentCell;

@interface NSPathControl : NSControl {
	NSDragOperation _localDraggingMask;
	NSDragOperation _remoteDraggingMask;
	//NSTrackingArea *_trackingArea; für 10.5
	NSInteger _trackingTag;
#ifdef TESTING
	NSString *_delegate;
#endif
}

- (NSColor *) backgroundColor; 
- (NSPathComponentCell *) clickedPathComponentCell; 
- (id) delegate; 
- (SEL) doubleAction; 
- (NSArray *) pathComponentCells; 
- (NSPathStyle) pathStyle; 
- (void) setBackgroundColor:(NSColor *) col; 
- (void) setDelegate:(id) delegate; 
- (void) setDoubleAction:(SEL) sel; 
- (void) setDraggingSourceOperationMask:(NSDragOperation) mask forLocal:(BOOL) flag; 
- (void) setPathComponentCells:(NSArray *) pathCells; 
- (void) setPathStyle:(NSPathStyle) pathStyle; 
- (void) setURL:(NSURL *) url; 
- (NSURL *) URL; 

@end


@interface NSObject (NSPathControlDelegate)

- (BOOL) pathControl:(NSPathControl *) sender acceptDrop:(id <NSDraggingInfo>) draggingInfo; 
- (BOOL) pathControl:(NSPathControl *) sender shouldDragPathComponentCell:(NSPathComponentCell *) cell withPasteboard:(NSPasteboard *) pboard; 
- (NSDragOperation) pathControl:(NSPathControl *) sender validateDrop:(id <NSDraggingInfo>) draggingInfo; 
- (void) pathControl:(NSPathControl *) sender willDisplayOpenPanel:(NSOpenPanel *) openPanel; 
- (void) pathControl:(NSPathControl *) sender willPopUpMenu:(NSMenu *) menu; 
@end
