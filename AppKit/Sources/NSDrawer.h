/*
	NSDrawer.h	
	mySTEP
 
	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.
	
	Author:	H. N. Schaller <hns@computer.org>
	Date:	Jun 2006 - aligned with 10.4
 
	Author:	Fabian Spillner
	Date: 23. October 2007
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	7. November 2007 - aligned with 10.5 

	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSDrawer
#define _mySTEP_H_NSDrawer

#import "AppKit/NSWindow.h"

typedef enum _NSDrawerState {
	NSDrawerClosedState  = 0,
	NSDrawerOpeningState = 1,
	NSDrawerOpenState    = 2,
	NSDrawerClosingState = 3
} NSDrawerState;

@interface NSDrawer : NSResponder
{
	NSSize _contentSize;
	NSSize _minContentSize;
	NSSize _maxContentSize;
	NSWindow *_parentWindow;
	NSWindow *_drawerWindow;
	id _delegate;
	CGFloat _leadingOffset;
	CGFloat _trailingOffset;
	int _state;
	NSRectEdge _edge;
}

- (void) close;
- (void) close:(id) sender;
- (NSSize) contentSize;
- (NSView *) contentView;
- (id) delegate;
- (NSRectEdge) edge;
- (id) initWithContentSize:(NSSize) size preferredEdge:(NSRectEdge) edge;
- (CGFloat) leadingOffset;
- (NSSize) maxContentSize;
- (NSSize) minContentSize;
- (void) open;
- (void) open:(id) sender;
- (void) openOnEdge:(NSRectEdge) edge;
- (NSWindow *) parentWindow;
- (NSRectEdge) preferredEdge;
- (void) setContentSize:(NSSize) size;
- (void) setContentView:(NSView *) view;
- (void) setDelegate:(id) delegate;
- (void) setLeadingOffset:(CGFloat) offset;
- (void) setMaxContentSize:(NSSize) size;
- (void) setMinContentSize:(NSSize) size;
- (void) setParentWindow:(NSWindow *) parent;
- (void) setPreferredEdge:(NSRectEdge) edge;
- (void) setTrailingOffset:(CGFloat) offset;
- (NSInteger) state;
- (void) toggle:(id) sender;
- (CGFloat) trailingOffset;

@end

// Delegate Methods

@interface NSObject (NSDrawerDelegate)

- (void) drawerDidClose:(NSNotification *) notification;
- (void) drawerDidOpen:(NSNotification *) notification;
- (BOOL) drawerShouldClose:(NSDrawer *) sender;
- (BOOL) drawerShouldOpen:(NSDrawer *) sender;
- (void) drawerWillClose:(NSNotification *) notification;
- (void) drawerWillOpen:(NSNotification *) notification;
- (NSSize) drawerWillResizeContents:(NSDrawer *) sender toSize:(NSSize) size;

@end

// Notifications

extern NSString *NSDrawerDidCloseNotification;
extern NSString *NSDrawerDidOpenNotification;
extern NSString *NSDrawerWillCloseNotification;
extern NSString *NSDrawerWillOpenNotification;

#endif /* _mySTEP_H_NSDrawer */
