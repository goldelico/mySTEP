//
//  NSPathControl.h
//  AppKit
//
//  Created by Fabian Spillner on 29.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <AppKit/NSControl.h>
#import "NSPathCell.h"
#import <AppKit/NSDragging.h>

@class NSColor, NSPathComponentCell;

@interface NSPathControl : NSControl {

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
- (BOOL) pathControl:(NSPathControl *) sender shouldDragPathComponentCell:(NSPathComponentCell *) cell withPasteboard:(NSPasteboard *)pboard; 
- (NSDragOperation) pathControl:(NSPathControl *) sender validateDrop:(id <NSDraggingInfo>) draggingInfo; 
- (void) pathControl:(NSPathControl *) sender willDisplayOpenPanel:(NSOpenPanel *) openPanel; 
- (void) pathControl:(NSPathControl *) sender willPopUpMenu:(NSMenu *) menu; 

@end