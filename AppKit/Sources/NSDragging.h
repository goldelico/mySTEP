/* 
   NSDragging.h

   Protocols for drag 'n' drop.

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date:    1997
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Apr 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	23. October 2007
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	7. November 2007 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSDragging
#define _mySTEP_H_NSDragging

#import <Foundation/NSGeometry.h>

@class NSWindow;
@class NSPasteboard;
@class NSImage;

enum {
	NSDragOperationNone		= 0,					// no op == rejection
	NSDragOperationCopy		= 1,
	NSDragOperationLink		= 2,
	NSDragOperationGeneric	= 4,
	NSDragOperationPrivate	= 8,
	NSDragOperationMove		= 16,
	NSDragOperationDelete	= 32,
	NSDragOperationEvery	= 0xffff,
	// the following constant is deprecated
	NSDragOperationAll		= 15   
};

typedef NSUInteger NSDragOperation;

													// protocol for sender of 
@protocol NSDraggingInfo							// messages to a drag 
													// destination
- (NSImage *) draggedImage;
- (NSPoint) draggedImageLocation;
- (NSWindow *) draggingDestinationWindow;
- (NSPoint) draggingLocation;
- (NSPasteboard *) draggingPasteboard;
- (NSInteger) draggingSequenceNumber;
- (id) draggingSource;
- (NSDragOperation) draggingSourceOperationMask;
- (NSArray *) namesOfPromisedFilesDroppedAtDestination:(NSURL *) destination;
- (void) slideDraggedImageTo:(NSPoint) screenPoint;

@end

													// Methods implemented by 
@interface NSObject (NSDraggingDestination)			// a reciever of drag ops 
													// (drag destination)
- (void) concludeDragOperation:(id <NSDraggingInfo>) sender;
- (void) draggingEnded:(id <NSDraggingInfo>) sender;
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>) sender;
- (void) draggingExited:(id <NSDraggingInfo>) sender;
- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>) sender;
- (BOOL) performDragOperation:(id <NSDraggingInfo>) sender;
- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>) sender;
- (BOOL) wantsPeriodicDraggingUpdates;

@end
													// Methods implemented by
													// object that initiated 
@interface NSObject (NSDraggingSource)				// the drag session.  First 
													// must be implemented
- (void) draggedImage:(NSImage *) image
			  beganAt:(NSPoint) screenPoint;
- (void) draggedImage:(NSImage*) image
			  endedAt:(NSPoint) screenPoint
			operation:(NSDragOperation) operation;
- (void) draggedImage:(NSImage *) image
			  movedTo:(NSPoint) screenPoint;
- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL) isLocal;
- (BOOL) ignoreModifierKeysWhileDragging;
- (NSArray *) namesOfPromisedFilesDroppedAtDestination:(NSURL *) dropDestination;

@end

@interface NSObject (NSDraggingSourceDeprecated)
- (void) draggedImage:(NSImage*)image
			  endedAt:(NSPoint)screenPoint
			deposited:(BOOL)didDeposit;
@end

#endif /* _mySTEP_H_NSDragging */
