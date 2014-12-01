//
//  NSDrawer.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Apr 12 2006.
//  Copyright (c) 2006 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import "Foundation/Foundation.h"
#import "AppKit/NSDrawer.h"

NSString *NSDrawerDidCloseNotification=@"NSDrawerDidCloseNotification";
NSString *NSDrawerDidOpenNotification=@"NSDrawerDidOpenNotification";
NSString *NSDrawerWillCloseNotification=@"NSDrawerWillCloseNotification";
NSString *NSDrawerWillOpenNotification=@"NSDrawerWillOpenNotification";

@implementation NSDrawer

- (void) close;
{
	if(!_state)
		return;	// already closed
	[_parentWindow orderOut:nil];	// close
}

- (void) close:(id) sender; { [self close]; }
- (NSSize) contentSize; { return _contentSize; }
- (NSRectEdge) edge; { return _edge; }

- (id) initWithContentSize:(NSSize) size preferredEdge:(NSRectEdge) edge;
{
	if((self=[super init]))
		{
		_contentSize=size;
		_edge=edge;
//		_minSize=NSZeroSize;
//		_maxSize=NSMakeSize(99999.0, 99999.0);
		}
	return self;
}

- (void) dealloc;
{
	[self setDelegate:nil];	// unconnect notifications
	[_parentWindow release];
	[super dealloc];
}

- (CGFloat) leadingOffset; { return _leadingOffset; }
- (NSSize) maxContentSize; { return _maxContentSize; }
- (NSSize) minContentSize; { return _minContentSize; }

- (void) open;
{
	// choose the best edge
	[self openOnEdge:_edge];
}

- (void) open:(id) sender; { return [self open]; }

- (void) openOnEdge:(NSRectEdge) edge;
{
	if(_state)
		return;	// already open
	// handle location
	[_parentWindow makeKeyAndOrderFront:nil];	// open
}

- (NSWindow *) parentWindow; { return _parentWindow; }
- (NSRectEdge) preferredEdge; { return _edge; }

- (void) setContentSize:(NSSize) size;
{
	_contentSize=size;
	// resize the content view
}

- (NSView *) contentView; { return [_drawerWindow contentView]; }
- (id) delegate; { return _delegate; }

- (void) setContentView:(NSView *) view; { [_drawerWindow setContentView:view]; }
- (void) setDelegate:(id) delegate
{
// FIXME: disconnect old and connect new delegate to the 4 notifications
//	[super setDelegate:delegate];
}

- (void) setLeadingOffset:(CGFloat) offset; { _leadingOffset=offset; }
- (void) setMaxContentSize:(NSSize) size; { _maxContentSize=size; }
- (void) setMinContentSize:(NSSize) size; { _minContentSize=size; }
- (void) setParentWindow:(NSWindow *) parent; { ASSIGN(_parentWindow, parent); }
- (void) setPreferredEdge:(NSRectEdge) edge; { _edge=edge; }
- (void) setTrailingOffset:(CGFloat) offset; { _trailingOffset=offset; }
- (int) state; { return _state; }

- (void) toggle:(id) sender;
{
	if(_state)
		[self close];
	else
		[self open];
}

- (CGFloat) trailingOffset; { return _trailingOffset; }

@end
