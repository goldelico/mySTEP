/* 
 NSWindow.m
 
 Window class
 
 Copyright (C) 1998 Free Software Foundation, Inc.
 
 Author:  Felipe A. Rodriguez <far@pcmagic.net>
 Date:    June 1998
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSException.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSDictionary.h>

#import <AppKit/NSWindow.h>
#import <AppKit/NSWindowController.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSCachedImageRep.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSSliderCell.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSDragging.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarItem.h>
#import <AppKit/NSAnimation.h>
#import <AppKit/NSBezierPath.h>

#import "NSAppKitPrivate.h"
#import "NSBackendPrivate.h"

#define NOTE(notif_name) NSWindow##notif_name##Notification

// Class variables
static id __responderClass = nil;
static id __lastKeyDown = nil;
static id __frameNames = nil;
static BOOL __cursorHidden = NO;

@interface NSView (LifeResize)
- (void) _performOnAllSubviews:(SEL) sel;
@end

@implementation NSView (LifeResize)
- (void) _performOnAllSubviews:(SEL) sel
{
	NSEnumerator *e=[sub_views objectEnumerator];
	NSView *v;
	[self performSelector:sel];
	while((v=[e nextObject]))
		[v _performOnAllSubviews:sel];
}
@end

@interface _NSThemeWidget : NSButton
- (id) initWithFrame:(NSRect) f forStyleMask:(unsigned int) aStyle;
@end

@interface _NSThemeCloseWidget : _NSThemeWidget
{
	BOOL isDocumentEdited;
}
- (BOOL) isDocumentEdited;
- (void) setDocumentEdited:(BOOL) flag;	// changes image
@end

@interface NSThemeDocumentButton : _NSThemeWidget
@end

@interface NSThemeFrame : NSView
{
	NSString *_title;
	NSImage *_titleIcon;
	NSButton *_resizeButton;	// really here?
	NSToolbar *_toolbar;
	NSColor *_backgroundColor;	// window background color
	float _height;	// title bar height (w/o ToolbarView!)
	unsigned int _style;
	BOOL _inLiveResize;
	BOOL _didSetShape;
	BOOL _drawsResizeIndicator;
}

// handle active/inactive by dimming out everything

- (id) initWithFrame:(NSRect) frame forStyleMask:(unsigned int) aStyle forScreen:(NSScreen *) screen;
- (unsigned int) style;

- (NSString *) title;
- (void) setTitle:(NSString *) title;
- (NSImage *) titleIcon;
- (void) setTitleIcon:(NSImage *) img;
- (NSColor *) titleBarBackgroundColor;
- (NSColor *) backgroundColor;
- (void) setBackgroundColor:(NSColor *) color;

- (NSButton *) standardWindowButton:(NSWindowButton) button;
- (NSView *) contentView;
- (void) setContentView:(NSView *) view;
- (void) layout;	// set frame of content view to fit to buttons bar and toolbar (if present)
- (NSToolbar *) toolbar;
- (NSToolbarView *) toolbarView;
- (void) setToolbar:(NSToolbar *) toolbar;
- (BOOL) showsToolbarButton;
- (void) setShowsToolbarButton:(BOOL) flag;
- (BOOL) showsResizeIndicator;
- (void) setShowsResizeIndicator:(BOOL) flag;
- (void) _setTexturedBackground:(BOOL)flag;

@end

@interface NSGrayFrame : NSThemeFrame	// for textured windows
@end

@interface NSNextStepFrame : NSThemeFrame	// for borderless windows (has no buttons and only contentView)
@end

// what about panels?

@interface NSToolbarView : NSView
{
	NSToolbar *_toolbar;
	NSRect *_itemRects;
	float _toolbarHeight;
	int _itemRectCount;
	int _itemRectCapacity;
	int _clickedCell;			// used internally when clicked
	int _highlightedCell;	// used internally to highlight a clicked item
	BOOL _needsOverflowMenu;
}

- (void) setToolbar:(NSToolbar *) _toolbar;
- (NSToolbar *) toolbar;
- (BOOL) popUpMode;	// run in popup mode
- (float) height;
- (NSRect) rectForToolbarItem:(int) idx;
- (int) itemIndexForPoint:(NSPoint) pnt;
- (IBAction) popUpOverflowMenu:(id) sender;

@end

@implementation NSThemeFrame

- (BOOL) isOpaque;	{ return YES; }	// only if background color has alpha==1.0
- (BOOL) isFlipped;	{ return YES; }	// to simplify coordinate calculations: titlebar is at (0,0)

- (id) initWithFrame:(NSRect) f forStyleMask:(unsigned int) aStyle forScreen:(NSScreen *) screen;
{
#if 1
	NSLog(@"init theme frame 1: subviews=%@", sub_views);
#endif
	if((aStyle&GSAllWindowMask) == NSBorderlessWindowMask)
		{
		[self release];
		self=[NSNextStepFrame alloc];
		}
	else if(aStyle&NSTexturedBackgroundWindowMask)
		{
		[self release];
		self=[NSGrayFrame alloc];
		}
	if((self=[super initWithFrame:f]))	// NOTE: this calls -setMenu with class.defaultMenu
		{
#if 0
		NSLog(@"init theme frame 2: subviews=%@", sub_views);
#endif
		_style=aStyle;
		_drawsResizeIndicator=(_style & NSResizableWindowMask) != 0 && !([self interfaceStyle] >= NSPDAInterfaceStyle);
		[self setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];	// resize with window
		[self setAutoresizesSubviews:YES];
		if((aStyle&GSAllWindowMask) != NSBorderlessWindowMask)
			{ // not a NSNextStepFrame
				NSButton *b0, *b1, *b2, *b3;
#if 0
				NSLog(@"init theme frame 3: subviews=%@", sub_views);
#endif
				[self addSubview:b0=[NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:aStyle]];
				[self addSubview:b1=[NSWindow standardWindowButton:NSWindowMiniaturizeButton forStyleMask:aStyle]];
				[self addSubview:b2=[NSWindow standardWindowButton:NSWindowZoomButton forStyleMask:aStyle]];
				if([self interfaceStyle] >= NSPDAInterfaceStyle)
					[b1 setHidden:YES], [b2 setHidden:YES];	// standard PDA screen is not large enough for multiple resizable windows
				else
					if((aStyle & (NSClosableWindowMask | NSMiniaturizableWindowMask| NSResizableWindowMask)) == 0)
						{ // no visible buttons!
							[b0 setHidden:YES], [b1 setHidden:YES], [b2 setHidden:YES];
						}
				[self addSubview:b3=[NSWindow standardWindowButton:NSWindowDocumentIconButton forStyleMask:aStyle]];
				[b3 setFrameSize:NSMakeSize(f.size.width - 50.0, 15.0)]; // resize to fit between buttons and toolbar button
			}
		[self layout];
		ASSIGN(_backgroundColor, [NSColor windowBackgroundColor]);	// default background
		}
	return self;
}

- (void) dealloc;
{
	[_title release];
	[_titleIcon release];
	[_backgroundColor release];
	[super dealloc];
}

- (NSColor *) titleBarBackgroundColor;
{
	if([_window isKeyWindow] && [NSApp isActive])		// other conditions? E.g. for panels and utility panels?
		return [NSColor windowFrameColor];
	else
		return [NSColor windowBackgroundColor];
}

- (void) drawRect:(NSRect)rect
{ // draw window background
	static NSDictionary *a;
	if(!_didSetShape)
		{
		if((_style&NSUtilityWindowMask) == 0)
			{ // make title bar with rounded corners
				NSGraphicsContext *ctxt=[NSGraphicsContext currentContext];
				float radius=9.0;
				NSBezierPath *b=[NSBezierPath new];
				[b appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(_frame)+radius, NSMinY(_frame)+radius)
											  radius:radius
										  startAngle:180.0
											endAngle:270.0
										   clockwise:NO];	// top left corner
				[b appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(_frame)-radius, NSMinY(_frame)+radius)
											  radius:radius
										  startAngle:270.0
											endAngle:360.0
										   clockwise:NO];	// top right corner
				[b lineToPoint:NSMakePoint(NSMaxX(_frame), NSMaxY(_frame))];	// bottom right
				[b lineToPoint:NSMakePoint(0.0, NSMaxY(_frame))];	// bottom left
				[b closePath];
#if 0
				NSLog(@"set window shape %@", b);
#endif
				[ctxt _setShape:b];
				[b release];
			}
		_didSetShape=YES;
		}
	[_backgroundColor set];
	NSRectFill(rect);	// draw window background
	if(NSMinY(rect) < _height)
		{ // needs to redraw the titlebar
			NSParagraphStyle *paragraph=nil;
			[[self titleBarBackgroundColor] set];
			NSRectFill((NSRect){NSZeroPoint, {_bounds.size.width, _height }});	// fill titlebar background
			[[NSColor windowFrameColor] set];
			NSFrameRect(_bounds);	// draw a frame around the window (using current fill color)
			if(!_title && !_titleIcon)
				return;
			// draw document icon
			// or shouldn't we better use a resizable NSButton with center alignment to store and draw both, the window icon and title?
			// or at least use a centered paragraph style!
			// [_titleButton drawInteriorWithFrame:rect between buttons inView:self];
			if(_titleIcon && _title)
				{
				[_titleIcon compositeToPoint:NSMakePoint((_bounds.size.width-[_title sizeWithAttributes:a].width)/2.0-[_titleIcon size].width,
														 1.0+(_height-16.0)/2.0)
								   operation:NSCompositeSourceOver
									fraction:[_window isKeyWindow]?1.0:0.8];	// should be dimmed out if we are not the main window
				}
			a=[NSDictionary dictionaryWithObjectsAndKeys:
			   [_window isKeyWindow]?[NSColor windowFrameTextColor]:[NSColor grayColor], NSForegroundColorAttributeName,
			   [NSFont titleBarFontOfSize:(_style&NSUtilityWindowMask)?9.0:12.0], NSFontAttributeName,
			   paragraph, NSParagraphStyleAttributeName,
			   nil];
			[_title drawAtPoint:NSMakePoint((_bounds.size.width-[_title sizeWithAttributes:a].width)/2.0, ((_style&NSUtilityWindowMask)?5.0:4.0)+(_height-16.0)/2.0) withAttributes:a]; // draw centered window title
		}
}

- (void) unlockFocus;
{ // last chance to draw anything - note that we start with the graphics state left over by the previous operations
	if(_drawsResizeIndicator)
		{ // draw resizing handle in the lower right corner
			[NSGraphicsContext setGraphicsState:[_window gState]];
			[[NSBezierPath bezierPathWithRect:_bounds] setClip];
			[[NSColor grayColor] set];
#if 0
			[[NSColor redColor] set];
#endif
			[NSBezierPath strokeLineFromPoint:NSMakePoint(_bounds.size.width-2, _bounds.size.height-8)
									  toPoint:NSMakePoint(_bounds.size.width-8, _bounds.size.height-2)];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(_bounds.size.width-2, _bounds.size.height-11)
									  toPoint:NSMakePoint(_bounds.size.width-11, _bounds.size.height-2)];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(_bounds.size.width-2, _bounds.size.height-14)
									  toPoint:NSMakePoint(_bounds.size.width-14, _bounds.size.height-2)];
		}
	[super unlockFocus];
}

- (unsigned int) style; { return _style; }

- (void) _setTexturedBackground:(BOOL)flag;
{
	_style &= ~NSTexturedBackgroundWindowMask;
	if(flag)
		_style |= NSTexturedBackgroundWindowMask;
	[self setNeedsDisplay:YES];
}

- (NSString *) title; { return _title; }
- (void) setTitle:(NSString *) title; { ASSIGN(_title, title); [self setNeedsDisplay:YES]; }
- (NSImage *) titleIcon; { return _titleIcon; }
- (void) setTitleIcon:(NSImage *) img; { ASSIGN(_titleIcon, img); [self setNeedsDisplay:YES]; }
- (NSColor *) backgroundColor; { return _backgroundColor; }
- (void) setBackgroundColor:(NSColor *) color; { ASSIGN(_backgroundColor, color); [self setNeedsDisplay:YES]; }

- (NSButton *) standardWindowButton:(NSWindowButton) button;
{
	/* subviews
	 0:	close button
	 1: miniaturize button
	 2: zoom button
	 3: title/document icon button
	 4: content view (0 if borderless)
	 5: toolbar button
	 6: toolbar view
	 */
#if 1
	NSLog(@"standardWindowButton %d", button);
	NSLog(@"subviews %@", sub_views);
#endif
	switch(button) {
		case NSWindowCloseButton: return [sub_views objectAtIndex:0];
		case NSWindowMiniaturizeButton: return [sub_views objectAtIndex:1];
		case NSWindowZoomButton: return [sub_views objectAtIndex:2];
		case NSWindowDocumentIconButton: return [sub_views objectAtIndex:3];
		case NSWindowToolbarButton: return [sub_views count] > 5?[sub_views objectAtIndex:5]:nil;
		default: return nil;
	}
}

- (NSButton *) documentIcon; { return [sub_views count] > 3?[sub_views objectAtIndex:3]:nil; }
- (NSView *) contentView; { return [sub_views count] > 4?[sub_views objectAtIndex:4]:nil; }
- (NSToolbarView *) toolbarView; { return [sub_views count] > 6?[sub_views objectAtIndex:6]:nil; }
- (NSMenuView *) windowMenuView; { return nil; }	// if we have a horizontal menu inside the window
- (NSToolbar *) toolbar; { return [sub_views count] > 6?[[sub_views objectAtIndex:6] toolbar]:(NSToolbar *) nil; }

- (void) layout;
{ // NOTE: if the window fills the screen, the content view has to be made smaller
	NSView *cv;
	NSRect f=[self frame];
	_height=[NSWindow _titleBarHeightForStyleMask:_style];
	f.origin.y+=_height;		// add room for buttons
	f.size.height-=_height;
	if([_window canBecomeMainWindow] && [self menu])
		{ // has a window menu
			NSMenuView *mv=[self windowMenuView];
			float height=[mv frame].size.height;
			NSRect tf=f;
			f.origin.y+=height;
			f.size.height-=height;	// make room for menu
			tf.size.height=height;
			[mv setFrame:tf];					// adjust menu view
			[mv setNeedsDisplay:YES];	// needs redraw
		}
	if([sub_views count] >= 7)
		{ // has a toolbar
			NSToolbarView *tv=[self toolbarView];
			float height=[tv height];
			NSRect tf=f;
			f.origin.y+=height;
			f.size.height-=height;	// make room for toolbar
			tf.size.height=height;
			[tv setFrame:tf];					// adjust toobar view
			[tv setNeedsDisplay:YES];	// needs redraw
		}
	cv=[self contentView];
#if 0
	NSLog(@"layout %@", self);
	NSLog(@"  cv=%@", cv);
	NSLog(@"  frame=%@", NSStringFromRect(f));
#endif
	if(!cv)
		[self addSubview:[[[NSView alloc] initWithFrame:f] autorelease]];	// add an initial content view
	else
		[cv setFrame:f];	// enforce size of content view to fit
	[cv setNeedsDisplay:YES];	// needs redraw
	_didSetShape=NO;	// and reset shape
}

- (void) viewWillMoveToWindow:(NSWindow *) win;
{
	if(win)
		[self layout];	// update layout initially
}

- (void) setContentView:(NSView *) view;
{
	NSView *cv=[self contentView];	// current content view
#if 0
	NSLog(@"setContentView %@", self);
	NSLog(@"  view=%@", view);
	NSLog(@"  cv=%@", [self contentView]);
#endif
	[self replaceSubview:cv with:view];	// this checks if a content view exists
	[view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
	[view setAutoresizesSubviews:YES];	// enforce for content view
	[self layout];
	[self setNeedsDisplay:YES];	// show everything
#if 0
	NSLog(@"self=%@", [self _descriptionWithSubviews]);
#endif	
}

- (NSMenu *) menu { return [[self windowMenuView] menu]; }	// current window menu

- (void) setMenu:(NSMenu *) menu
{
	if([sub_views count] == 0)
		return;	// ignore when called from -initWithFrame:
	if(menu && ![self windowMenuView])
		; // allocate/deallocate a horizontal NSMenuView (subview)
	else if(!menu && [self windowMenuView])
		[[self windowMenuView] removeFromSuperviewWithoutNeedingDisplay];
	else
		[[self windowMenuView] setMenu:menu];	// just update menu
	[self layout];	// update layout
}

- (void) setToolbar:(NSToolbar *) toolbar;
{
	if(toolbar && [sub_views count] <= 5)
		{ // we don't have a toolbar (yet)
			NSRect wf=[_window frame];	// window frame
			NSToolbarView *tv;
			NSButton *wb;
			NSRect f;
			[self addSubview:wb=[NSWindow standardWindowButton:NSWindowToolbarButton forStyleMask:_style]];
			[wb setTarget:_window];
			f=[wb frame];		// button frame
			f.origin.x=wf.size.width-f.size.width-4.0;
			[wb setFrameOrigin:f.origin];	// flush toolbar button to the right end
			tv=[[NSToolbarView alloc] initWithFrame:(NSRect){{0.0, 0.0}, {wf.size.width, 50.0}}];	// as wide as the window
			[tv setAutoresizingMask:NSViewWidthSizable|NSViewMaxYMargin];
			[tv setAutoresizesSubviews:YES];
			[self addSubview:tv];	// becomes #5
			[tv release];
			// reduce size of title bar
		}
	if(!toolbar && [sub_views count] > 6)
		{ // remove button and toolbar
			[[sub_views objectAtIndex:6] removeFromSuperviewWithoutNeedingDisplay];	// toolbar view
			[[sub_views objectAtIndex:5] removeFromSuperviewWithoutNeedingDisplay];	// toolbar button
			// increase size of title bar
		}
	else if(toolbar)
		[[sub_views objectAtIndex:6] setToolbar:toolbar];	// just update
	[self layout];
	[self setNeedsDisplay:YES];
}

- (BOOL) showsToolbarButton; { NSButton *button=[self standardWindowButton:NSWindowToolbarButton]; return button && ![button isHidden]; }
- (void) setShowsToolbarButton:(BOOL) flag; { [[self standardWindowButton:NSWindowToolbarButton] setHidden:!flag]; }
- (BOOL) showsResizeIndicator; { return _drawsResizeIndicator; }
- (void) setShowsResizeIndicator:(BOOL) flag; { _drawsResizeIndicator=flag; }

- (BOOL) inLiveResize	{ return _inLiveResize; }

- (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent;
{
	return NO;	// don't ink on theme frame...
}

- (BOOL) mouseDownCanMoveWindow; { return YES; }

// might need to modify hit-test to detect resize...

- (BOOL) acceptsFirstMouse:(NSEvent *) event; { return YES; }	// send us the first event
- (BOOL) acceptsFirstResponder;	{ return YES; }	// to allow selecting the window

// FIXME: try to cache since it will be called at least twice for each inking/mouseDown event and may got through the whole hierarchy
// FIXME: it might be better to know the event and cache per event

- (NSView *) hitTest:(NSPoint) aPoint
{
	// FIXME: we should make a triangular shape...
	if((_style & NSResizableWindowMask) == 0 || aPoint.y > 10.0 || aPoint.x < _frame.size.width-10.0)
		return [super hitTest:aPoint];	// normal mode
	return self;	// handle resize handle directly
}

- (void) mouseDown:(NSEvent *) theEvent
{ // NSTheme frame
	NSPoint initial;
	NSRect initialFrame=[_window frame];
	NSRect visibleRect=[[_window screen] visibleFrame];
#if 1
	NSLog(@"NSThemeFrame clicked (%@)", NSStringFromPoint([theEvent locationInWindow]));
#endif
	if((_style & NSResizableWindowMask) != 0 && ([self interfaceStyle] >= NSPDAInterfaceStyle))
		return;	// resizable window has already been resized for full screen mode - don't permit to move
	while(YES)
		{ // loop until mouse goes up
#if 1
			NSLog(@"NSThemeFrame event %@", theEvent);
#endif
			
#define OLDMOVE 1
			
			switch([theEvent type]) {
				case NSLeftMouseDown: {
					// FIXME: check for click on document icon or title cell
					// if representedURL defined and crtl-click, call - (BOOL)window:(NSWindow *)sender shouldPopUpDocumentPathMenu:(NSMenu *)titleMenu
#if OLDMOVE
					NSPoint p=[_window mouseLocationOutsideOfEventStream];	// (0,0) is lower left corner!
					initial=[NSEvent mouseLocation];
#else
					NSPoint p=[theEvent locationInWindow];
					initial=p;
#endif
					if(p.y < _frame.size.height-_height)
						{ // check if we a have resize enabled in _style and we clicked on lower right corner
							if((_style & NSResizableWindowMask) == 0 || p.y > 10.0 || p.x < _frame.size.width-10.0)
								{
								// FIXME: we can also check if we are textured and the point we did hit is considered "background"
#if 1
								NSLog(@"inside");
#endif
								return;	// ignore if neither in title bar nor resize area
								}
							_inLiveResize=YES;
#if 0
							NSLog(@"liveResize started");
#endif
							// FIXME: should also be called exactly once if view is added/removed repeatedly to the hierarchy during life resize
							[self _performOnAllSubviews:@selector(viewWillStartLiveResize)];
						}
#if 0
					NSLog(@"initial = %@ (%@)", NSStringFromPoint(initial), NSStringFromPoint(p));
#endif
					break;
				}
				case NSLeftMouseUp:			// update to final location
				case NSLeftMouseDragged: {
					float deltax, deltay;
					NSRect wframe=initialFrame;
#if OLDMOVE
					// NOTE: we can't use [event locationInWindow] if we move the window - is not reliable because it is not synchronized with really moving the window!
					NSPoint loc=[NSEvent mouseLocation];
#else
					NSPoint loc=[theEvent locationInWindow];
#endif
					deltax=loc.x-initial.x;	// how much we have moved
					deltay=loc.y-initial.y;
					NSLog(@"moved by (%g %g)", deltax, deltay);
#if 0
					NSLog(@"window dragged loc=%@ mouse=%@", NSStringFromPoint(loc), NSStringFromPoint([theEvent locationInWindow]));
#endif
					if(_inLiveResize)
						{ // resizing
							wframe.origin.y+=wframe.size.height;		// keep top left corner stable
							// FIXME: handle resizeIncrements
							// FIXME: protect against empty or negative window size...
							wframe.size.width+=deltax;
							if(wframe.size.width < 0)
								wframe.size.width = 0;
							wframe.size.height-=deltay;	// resize as mouse moves
							if(wframe.size.height < 0)
								wframe.size.height = 0;
							if(wframe.origin.y - wframe.size.height < NSMinY(visibleRect))
								;	// limit height
							// FIXME: should this be part of setFrame: ?
							wframe.size.width = MIN(MAX(wframe.size.width, [_window minSize].width), [_window maxSize].width);
							wframe.size.height = MIN(MAX(wframe.size.height, [_window minSize].height), [_window maxSize].height);
							wframe.origin.y-=wframe.size.height;		// calculate new bottom left corner
#if 0
							NSLog(@"resize window from (%@) to (%@)", NSStringFromRect([_window frame]), NSStringFromRect(wframe));
#endif
							[NSApp discardEventsMatchingMask:NSLeftMouseDraggedMask beforeEvent:nil];	// discard all further movements queued up so far
							[_window setFrame:wframe display:NO];	// resize - will redisplay by ConfigureNotify event
							// called by ConfigureNotify event
							// [self setNeedsDisplay:YES];
						}
					else
						{ // moving
							wframe.origin.x+=deltax;
							wframe.origin.y+=deltay;	// move as mouse moves
							
							// limit title bar to stay below menu
							
							// can we use [window constrainFrameRect:wframe toScreen:[window screen]];
							
							if(NSMaxY(wframe) > NSMaxY(visibleRect))
								wframe.origin.y-=NSMaxY(wframe)-NSMaxY(visibleRect);	// limit so that window can't be moved under the menu bar
							if(YES)
								{ // in PDA mode/style: clamp window to [screen visibleFrame]
									if(NSMinY(wframe) < NSMinY(visibleRect))
										wframe.origin.y+=NSMinY(visibleRect)-NSMinY(wframe);	// limit so that window can't be moved under the bottom menu bar
									if(NSMaxX(wframe) > NSMaxX(visibleRect))
										wframe.origin.x-=NSMaxX(wframe)-NSMaxX(visibleRect);
									if(NSMinX(wframe) < NSMinX(visibleRect))
										wframe.origin.x+=NSMinX(visibleRect)-NSMinX(wframe);
								}
							[_window setFrameOrigin:wframe.origin];	// move window (no need to redisplay)
							NSLog(@"move child windows %@", [_window childWindows]);
#if OLDMOVE
#else
							// can be cleaned up if it works!!!
							initial=loc;	// window has moved - assume next event is relative to new location
							initialFrame=wframe;
#endif
						}
					break;
				}
				default:
					break;	// ignore other events
			}
			if([theEvent type] == NSLeftMouseUp)
				break;	// done
			theEvent = [NSApp nextEventMatchingMask:GSTrackingLoopMask
										  untilDate:[NSDate distantFuture]
											 inMode:NSEventTrackingRunLoopMode 
											dequeue:YES];							// get next event
		}
	if(_inLiveResize)
		{
		_inLiveResize=NO;
		[self _performOnAllSubviews:@selector(viewDidEndLiveResize)];
		}
#if 1
	NSLog(@"NSThemeFrame tracking done");
#endif
}

@end

@implementation NSGrayFrame		// used for NSTexturedBackgroundWindowMask

// we don't distinguish here
// but might initialize our window for a different layout and style here

@end

@implementation NSNextStepFrame	// used for borderless window

- (void) drawRect:(NSRect)rect
{ // draw window background only (no title, no shape!)
	[_backgroundColor set];
	NSRectFill(rect);	// draw window background
}

- (NSButton *) standardWindowButton:(NSWindowButton) button;
{
	return nil;	// has no buttons
}

- (NSView *) contentView; { return [sub_views count] > 0?[sub_views objectAtIndex:0]:nil; }

- (void) layout;
{ // we don't have a button bar
	NSView *cv=[self contentView];
	NSRect f=[self frame];
#if 0
	NSLog(@"layout %@", self);
	NSLog(@"  cv=%@", cv);
	NSLog(@"  frame=%@", NSStringFromRect(f));
#endif
	if(!cv)
		[self addSubview:[[[NSView alloc] initWithFrame:f] autorelease]];	// add an initial content view
	else
		[cv setFrame:f];	// enforce size of content view to fit
	[cv setNeedsDisplay:YES];	// needs redraw
}

- (void) setToolbar:(NSToolbar *) toolbar; { NIMP; }	// can't save/create for borderless windows

// - (BOOL) mouseDownCanMoveWindow; { return YES; } but only in titlebar area!

@end

@implementation _NSThemeWidget

// handle graying out of buttons if our window is not main window or App is not active

- (void) drawRect:(NSRect)rect
{
	[super drawRect:rect];
}

- (id) initWithFrame:(NSRect) f forStyleMask:(unsigned int) aStyle;
{
	if((self=[super initWithFrame:f]))
		{ // set some defaults
			[self setButtonType:NSMomentaryChangeButton];	// toggle images
			[self setAutoresizesSubviews:YES];
			[self setAutoresizingMask:(NSViewMaxXMargin|NSViewMinYMargin)];	// don't resize with window
			[_cell setAlignment:NSCenterTextAlignment];
			[_cell setImagePosition:NSImageOverlaps];
			[_cell setBordered:NO];	// no bezel
			[_cell setFont:[NSFont titleBarFontOfSize:0]];
			[_cell setShowsFirstResponder:NO];	// don't show
		}
	return self;
}

- (void) viewDidMoveToWindow
{ // set window as target for buttons
	[self setTarget:_window];
}

- (BOOL) shouldDelayWindowOrderingForEvent:(NSEvent*)event	{ return YES; }		// always delay window ordering
- (BOOL) acceptsFirstResponder; { return NO; }
- (BOOL) acceptsFirstMouse; { return YES; }

- (void) mouseDown:(NSEvent *) e;
{
	[NSApp preventWindowOrdering];	// don't ever order front
	[super mouseDown:e];
}

@end

@implementation _NSThemeCloseWidget

- (BOOL) isDocumentEdited; { return isDocumentEdited; }
- (void) setDocumentEdited:(BOOL) flag;
{
	isDocumentEdited=flag;
	[self setImage:[NSImage imageNamed:flag?@"NSWindowChangedButton":@"NSWindowCloseButton"]];	// change button image
	[self setNeedsDisplay];
	// notify backend (external window manager)
}

@end

@implementation NSThemeDocumentButton

- (NSView *) hitTest:(NSPoint) aPoint
{
	// enable only D&D for the icon
	return nil;	// don't hit
}

@end

@implementation NSToolbarView

static NSButtonCell *sharedCell;

- (BOOL) isOpaque; { return NO; }

- (id) initWithFrame:(NSRect) frame
{
	if((self=[super initWithFrame:frame]))
		{
		_clickedCell=-1;			// none
		_highlightedCell=-1;	// none
		_itemRectCount= -1;		// unknown
		}
	return self;
}

- (void) dealloc;
{
	if(_itemRects)
		objc_free(_itemRects);
	[_toolbar release];
	[super dealloc];
}

- (void) setToolbar:(NSToolbar *) toolbar;
{
	ASSIGN(_toolbar, toolbar);
	[toolbar _setToolbarView:self];	// create link
	[self layout];
}

- (NSToolbar *) toolbar; { return _toolbar; }

- (void) layout;
{
	_itemRectCount= -1;	// clear cache
	[self setNeedsDisplay:YES];
}

- (void) setFrame:(NSRect) frame; { [super setFrame:frame]; [self layout]; }
- (void) setFrameOrigin:(NSPoint) point; { [super setFrameOrigin:point]; [self layout]; }

- (BOOL) popUpMode
{ // should we use popUpMode?
	if([_toolbar displayMode] != NSToolbarDisplayModeIconOnly)
		{ // unless we have IconOnly mode, make it depend on screen size
			if([(NSThemeFrame *) [self superview] showsToolbarButton])
				{
				NSSize size=[[[NSScreen screens] objectAtIndex:0] frame].size;
				return size.height > size.width;	// portrait mode screen
				}
		}
	return NO;	// always show icons
}

- (NSRect) rectForToolbarItem:(int) idx;
{
	if(_itemRectCount < 0 && [_toolbar isVisible])
		{ // recache
			NSArray *items=[_toolbar _activeItems];
			unsigned cnt=[items count];
			int i;
			NSToolbarItem *item;
			NSControlSize csize=([_toolbar sizeMode] == NSToolbarSizeModeSmall)?NSSmallControlSize:NSRegularControlSize;
			if(!sharedCell)
				{
				sharedCell=[[NSButtonCell alloc] init];
				[sharedCell setButtonType:NSMomentaryLightButton];	// ???
				[sharedCell setBordered:NO];	// no border (i.e. ignores bezelStyle)
				[sharedCell setImageScaling:NSImageScaleProportionallyUpOrDown];
				[sharedCell setShowsFirstResponder:NO];
				[sharedCell setImageDimsWhenDisabled:YES];
				[sharedCell setAction:@selector(dummy:)];	// so that the cell calls our sendAction:to: method
				}
			switch([_toolbar displayMode]) {
				case NSToolbarDisplayModeDefault:
				case NSToolbarDisplayModeIconAndLabel:
					[sharedCell setImagePosition:NSImageAbove];
					break;
				case NSToolbarDisplayModeLabelOnly:
					[sharedCell setImagePosition:NSNoImage];
					break;
				case NSToolbarDisplayModeIconOnly:
					[sharedCell setImagePosition:NSImageOnly];
					break;
			}
			[sharedCell setControlSize:csize];
			_itemRectCount=0;
			_toolbarHeight=0.0;
			if([self popUpMode])
				_needsOverflowMenu=YES;
			else
				{ // we have a large screen, so we can really layout a toolbar
					float border=3.0;
					NSRect rect={ { border, border }, { 0, 0 } };
					_needsOverflowMenu=NO;
					_toolbarHeight=12.0;	// minimum height
					for(i=0; i<cnt; i++)
						{ // allocate next item
							NSView *iv;	// item view
							NSSize min, max;
							item=[items objectAtIndex:i];
							iv=[item view];
							[sharedCell setTitle:[item label]];
							if(iv)
								{ // item has its own view - use min/max algorithm
									float labelheight;
									[sharedCell setImage:nil];	// no image
									if([iv respondsToSelector:@selector(cell)])
										[[(NSControl *) iv cell] setControlSize:csize];	// try to adjust size of cell - this should also adjust font to systemFontSizeForControlSize:
									else if([iv respondsToSelector:@selector(setControlSize:)])
										[(NSScroller *) iv setControlSize:csize];	// try to adjust size of view
									[iv setAutoresizingMask:0];	// don't autoresize
									labelheight=[sharedCell cellSize].height;
									min=[item minSize];
									min.height+=labelheight;
									max=[item maxSize];
								}
							else
								{
								[sharedCell setImage:[item image]];
								min=max=[sharedCell cellSize];	// use as much as needed by contents
								if(min.width < 10.0)
									min=max=NSMakeSize(10.0, 10.0);
								}
							// how much space do we want or have left over to distribute
							while((rect.size.width=MIN([self frame].size.width-2*border-NSMinX(rect), max.width)) < min.width)
								{ // is not enough
									float squeeze=min.width-rect.size.width;	// how much room we need
									int j;
									NSToolbarItem *other;
									for(j=0; j<i; j++)
										{ // try to squeeze flexible items down to their minSize.width
											other=[items objectAtIndex:j];
											if(![other view])
												continue;	// not variable size
											if(_itemRects[j].size.width-squeeze >= [other minSize].width)
												{
												_itemRects[j].size.width-=squeeze;	// squeeze as needed
												break;
												}
										}
									if(j == i)
										{ // if it does not suffice, kick out items with lower priority
											int prio=[item visibilityPriority];
											for(j=0; j<i; j++)
												{
												other=[items objectAtIndex:j];
												if([other visibilityPriority] < prio)
													{ // yes, has lower priority
														_itemRects[j].size.width=0.0;	// kick out
														break;
													}
												}
										}
									if(j == i)
										{ // neither squeezing nor kicking out is sufficient - we must leave out the new element
											rect.size.width=0.0;
											_needsOverflowMenu=YES;
											break;
										}
									for(; j < i; j++)
										{ // reposition elements
											rect.origin.x=NSMaxX(_itemRects[j]);	// this will update up to our current element which may now fit
											if(j+1 < i)
												_itemRects[j+1].origin.x=rect.origin.x;
											if(_itemRects[j].size.width > 0)
												rect.origin.x += 2*border;
										}
								}
							if(rect.size.width > 0 && _toolbarHeight < min.height)
								_toolbarHeight = min.height; // make _toolbarHeight at least as our minimum
#if 0
							NSLog(@"item %@ size %@", [item paletteLabel], NSStringFromSize(rect.size));
#endif
							if(_itemRects == NULL || _itemRectCount >= _itemRectCapacity)
								_itemRects=objc_realloc(_itemRects, sizeof(_itemRects[0])*(_itemRectCapacity=2*_itemRectCapacity+3));	// allocate more space
							_itemRects[_itemRectCount++]=rect;	// store
#if 0
							NSLog(@"item %@ located at %@", [item paletteLabel], NSStringFromRect(rect));
#endif
							if(rect.size.width > 0)
								rect.origin.x += rect.size.width + 2*border;	// advance to next position
						}
					_toolbarHeight+=border;
					for(i=0; i<cnt; i++)
						{	// adjust / reposition subviews (if iv exists)
							NSView *iv;	// item view
							item=[items objectAtIndex:i];
							iv=[item view];
							if(iv)
								{
								NSSize max=[item maxSize];
								_itemRects[i].size.height=MIN(_toolbarHeight, max.height);	// limit
								_itemRects[i].origin.y += (_toolbarHeight - _itemRects[i].size.height)/2;	// vertically centered
								if(!NSIsEmptyRect(_itemRects[i]))
									{ // not invisible
										[iv setFrame:_itemRects[i]];
										if(![sub_views containsObject:iv])
											[self addSubview:iv];	// not yet visible, add to view hierarchy
									}
								else
									[iv removeFromSuperview];	// not visible
								}
							else
								_itemRects[i].size.height=_toolbarHeight;
						}
				}
		}
	if(idx >= _itemRectCount)
		return NSZeroRect;
	return _itemRects[idx];
}

- (int) itemIndexForPoint:(NSPoint) pnt;
{
	int i;
	float border = -3.0;	// don't leave an unresponsive space between items
	for(i=0; i<_itemRectCount; i++)
		{
		if(NSMouseInRect(pnt, NSInsetRect(_itemRects[i], border, border), [self isFlipped]))	// include border
			return i;	// found
		}
	return -1;	// not found
}

- (float) height;
{
	if(![_toolbar isVisible] || [self popUpMode])
		return 0.0;	// if space limited, use popup menu
	if(_itemRectCount < 0 && _toolbar)
		[self rectForToolbarItem:0];	// load cache
	return _toolbarHeight;
}

- (void) drawRect:(NSRect) rect
{
	int i;
	NSArray *items=[_toolbar _activeItems];
	[[(NSThemeFrame *) super_view titleBarBackgroundColor] set];
	NSRectFill(rect);
	if([_toolbar showsBaselineSeparator])
		{ // draw separator
			[[NSColor whiteColor] set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(0, NSMaxY(_bounds)) toPoint:NSMakePoint(NSMaxX(_bounds), NSMaxY(_bounds))];
		}
	if(_itemRectCount < 0)
		[self rectForToolbarItem:0];	// load cache
	[_toolbar validateVisibleItems];	// check if items need to be drawn enabled
	for(i=0; i<_itemRectCount; i++)
		{
		// FIXME: shouldn't we read out the "config dict" to get the active items???
		
		NSToolbarItem *item=[items objectAtIndex:i];
		if(NSIsEmptyRect(_itemRects[i]))
			continue;	// entry to ignore
		if(NSIntersectsRect(_itemRects[i], rect))
			{ // is visible - draw
				[sharedCell setEnabled:[item isEnabled]];	// grey out label/image
				[sharedCell setTitle:[item label]];
				if([item view])
					[sharedCell setImage:nil];	// no image
				else
					[sharedCell setImage:[item image]];
				[sharedCell setHighlighted:(i == _highlightedCell)];
				[sharedCell drawWithFrame:_itemRects[i] inView:self];
			}
		}
	if(_needsOverflowMenu)
		{ // draw overflow indicator
		}
}

- (void) addConfigItems:(NSMenu *) menu;
{ // add some items we need in both, the control popup menu or in the overflow menu
	NSMenuItem *item;
	[item=[menu addItemWithTitle:@"Icon & Text" action:@selector(iconAndLabel:) keyEquivalent:@""] setTarget:self];
	[item setState:[_toolbar displayMode] == NSToolbarDisplayModeIconAndLabel?NSOnState:NSOffState];
	[item=[menu addItemWithTitle:@"Icon Only" action:@selector(iconOnly:) keyEquivalent:@""] setTarget:self];
	[item setState:[_toolbar displayMode] == NSToolbarDisplayModeIconOnly?NSOnState:NSOffState];
	[item=[menu addItemWithTitle:@"Label Only" action:@selector(labelOnly:) keyEquivalent:@""] setTarget:self];
	[item setState:[_toolbar displayMode] == NSToolbarDisplayModeLabelOnly?NSOnState:NSOffState];
	[menu addItem:[NSMenuItem separatorItem]];
	if([_toolbar sizeMode] == NSToolbarSizeModeSmall)
		[[menu addItemWithTitle:@"Use Large Size" action:@selector(regular:) keyEquivalent:@""] setTarget:self];
	else
		[[menu addItemWithTitle:@"Use Small Size" action:@selector(small:) keyEquivalent:@""] setTarget:self];
}

- (IBAction) popUpOverflowMenu:(id) sender;
{ // show popup menu
	/// for proper popup, this should be the action when the button is pressed (not when released)
	NSMenu *menu=[[NSMenu alloc] initWithTitle:@"Toolbar Menu"];
	NSEnumerator *e=[[_toolbar _activeItems] objectEnumerator];
	NSToolbarItem *item;
	NSMenuItem *mi;
	int idx=0;
	[_toolbar setVisible:NO];	// make toolbar invisible (unconditionally)
	[_toolbar validateVisibleItems];	// check if items need to be enabled
	[menu setAutoenablesItems:NO];
	[self rectForToolbarItem:0];	// this may update the layout
	while((item=[e nextObject]))
		{ // build menu on the fly, copying visibility to enable the menu items
			NSView *iv;
			NSMenu *submenu=nil;
			NSString *ident=[item itemIdentifier];
#if 0
			NSLog(@"ident %@", ident);
#endif
			if(!NSIsEmptyRect(_itemRects[idx++]))
				continue;	// is being displayed and not empty
			if([ident isEqualToString:NSToolbarSeparatorItemIdentifier] ||
			   [ident isEqualToString:NSToolbarSpaceItemIdentifier] ||
			   [ident isEqualToString:NSToolbarFlexibleSpaceItemIdentifier])
				continue;	// skip these in our menu
			if((iv=[item view]))
				{ // may be a popup button
					if([iv respondsToSelector:@selector(menu)])
						{ // if it responds to -menu (e.g. an NSPopUpButton) and that one is defined, make a submenu
							submenu=[iv menu];
						}
					else
						{
						}
				}
			mi=[[NSMenuItem alloc] initWithTitle:[item label] action:[item action] keyEquivalent:@""];
			if(submenu)
				[mi setMenu:submenu];
			else
				[mi setTarget:[item target]];
			[mi setImage:[item image]];
			[mi setEnabled:[item isEnabled]];
			[mi setTag:[item tag]];
			[menu addItem:mi];
			[mi release];
		}	
	[menu addItem:[NSMenuItem separatorItem]];
	[self addConfigItems:menu];	// standard items
	[menu addItem:[NSMenuItem separatorItem]];
	if([_toolbar allowsUserCustomization])
		{
		mi=[menu addItemWithTitle:@"Customize Toolbar" action:@selector(runCustomizationPalette:) keyEquivalent:@""];
		[mi setImage:[NSImage imageNamed:@"NSToolbarCustomize"]];
		[mi setTarget:_toolbar];	// not through first responder
		}
	[NSMenu popUpContextMenu:menu withEvent:[NSApp currentEvent] forView:[(NSThemeFrame *) [self superview] standardWindowButton:NSWindowToolbarButton]];	// pop up over the toolbar button
	[menu release];
}

- (IBAction) iconOnly:(id) sender; { [_toolbar setDisplayMode:NSToolbarDisplayModeIconOnly]; }
- (IBAction) labelOnly:(id) sender; { [_toolbar setDisplayMode:NSToolbarDisplayModeLabelOnly]; }
- (IBAction) iconAndLabel:(id) sender; { [_toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel]; }

// shouldn't this be a toggle action?
- (IBAction) regular:(id) sender; { [_toolbar setSizeMode:NSToolbarSizeModeRegular]; }
- (IBAction) small:(id) sender; { [_toolbar setSizeMode:NSToolbarSizeModeSmall]; }

- (IBAction) removeItem:(id) sender;
{
	if(_clickedCell >= 0)
		{ // send to highlighted item
			NSToolbarItem *item=[[_toolbar _activeItems] objectAtIndex:_clickedCell];
			// FIME: remove item and ask themeframe to re-layout
		}
}

- (IBAction) keepItemVisible:(id) sender;
{
	if(_clickedCell >= 0)
		{ // send to highlighted item
			NSToolbarItem *item=[[_toolbar _activeItems] objectAtIndex:_clickedCell];
			[item setVisibilityPriority:([item visibilityPriority] == NSToolbarItemVisibilityPriorityUser)?NSToolbarItemVisibilityPriorityStandard:NSToolbarItemVisibilityPriorityUser];	// toggle
		}
}

- (BOOL) acceptFirstResponder;				{ return NO; }
- (BOOL) acceptsFirstMouse;						{ return YES; }

- (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent;
{ // don't start inking in toolbar (although it would be a nice spot...)
	// we could allow inking in spaces (flexible and implcit)
	return NO;
}

- (void) mouseDown:(NSEvent *) event
{ // did click into toolbar
	// check control-click and popup toolbar item config menu (may include/exclude Keep Visible item)
	// if item has a (visible) view, pass down to the view, e.g. a NSControl
	// otherwise highlight track and action
	BOOL done;
	NSRect rect;
	NSToolbarItem *item=nil;
	NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];	// location on view
	_clickedCell=[self itemIndexForPoint:location];
	[_toolbar validateVisibleItems];	// check if items need to be enabled
	if(_clickedCell >= 0)
		{ // clicked into a cell, update control menu
			NSView *iv;
			NSMenu *controlMenu;
			NSMenuItem *mi;
			item=[[_toolbar _activeItems] objectAtIndex:_clickedCell];
			iv=[item view];
			controlMenu=[[[NSMenu alloc] initWithTitle:@"Toolbar Item Menu"] autorelease];
			[self addConfigItems:controlMenu];
			[controlMenu addItem:[NSMenuItem separatorItem]];
			// the next entry/entries is/are not to be shown for all items! How do we control that?
			[mi=[controlMenu addItemWithTitle:@"Keep Item Visible" action:@selector(keepItemVisible:) keyEquivalent:@""] setTarget:self];
			[mi setState:[item visibilityPriority] == NSToolbarItemVisibilityPriorityUser?NSOnState:NSOffState];
			[[controlMenu addItemWithTitle:@"Remove Item" action:@selector(removeItem:) keyEquivalent:@""] setTarget:self];
			if([_toolbar allowsUserCustomization])
				{
				[controlMenu addItem:[NSMenuItem separatorItem]];
				[[controlMenu addItemWithTitle:@"Customize Toolbar..." action:@selector(runCustomizationPalette:) keyEquivalent:@""] setTarget:_toolbar];
				}
			if(iv)
				{ // implemented by subview
					[iv setMenu:controlMenu];	// set the menu (NSResponder)
					[iv mouseDown:event];	// pass to item view and track there
					return;
				}
			[sharedCell setMenu:controlMenu];	// define for control-click
			[sharedCell setEnabled:[item isEnabled]];
			rect=[self rectForToolbarItem:_clickedCell];
		}
	else	// click outside of cell(s) - we still do "virtual" tracking to be able to show the control-menu
		{
		rect=NSMakeRect(location.x-1.0, location.y+1.0, 3.0, 3.0);	// small rect around initial point
		[sharedCell setEnabled:YES];
		}
	done=NO;
#if 1
	NSLog(@"tracking rect %@", NSStringFromRect(rect));
#endif
	while([event type] != NSLeftMouseUp)
		{ // loop outside until mouse finally goes up
			if(NSMouseInRect(location, rect, [self isFlipped]))
				{ // track the cell while we are in the initial cell
					if([item isEnabled])
						_highlightedCell=_clickedCell;	// highlight
					[self setNeedsDisplayInRect:rect];
					done = [sharedCell trackMouse:event
										   inRect:rect
										   ofView:self
									 untilMouseUp:NO];			// YES if mouse went up in cell, NO if we leave the cell
					_highlightedCell=-1;
					[self setNeedsDisplayInRect:rect];
					if(done)
						break;	// break loop if we are done
				}
			event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
									   untilDate:[NSDate distantFuture]
										  inMode:NSEventTrackingRunLoopMode
										 dequeue:YES];
			location = [self convertPoint:[event locationInWindow] fromView:nil];	// new location
		}
}

- (BOOL) sendAction:(SEL) action to:(id) target
{
	if(_clickedCell >= 0)
		{ // send to highlighted item
			NSToolbarItem *item=[[_toolbar _activeItems] objectAtIndex:_clickedCell];
			if([item isEnabled])
				return [NSApp sendAction:[item action] to:[item target] from:item];	// checkme - who is the sender?
		}
	return NO;
}

@end

@implementation NSWindow

+ (void) initialize
{
	if (self == [NSWindow class])
		{
		NSDebugLog(@"Initialize NSWindow class\n");
		__responderClass = [NSResponder class];
		}
}

+ (NSWindowDepth) defaultDepthLimit							{ return 32; }

+ (NSRect) contentRectForFrameRect:(NSRect)aRect
						 styleMask:(unsigned int)aStyle
{
	aRect.size.height-=[self _titleBarHeightForStyleMask:aStyle];  // remove space for title bar
	return aRect;
}

+ (NSRect) frameRectForContentRect:(NSRect)aRect
						 styleMask:(unsigned int)aStyle
{
	aRect.size.height+=[self _titleBarHeightForStyleMask:aStyle];  // make space for title bar
	return aRect;
}

+ (float) minFrameWidthWithTitle:(NSString *)aTitle
					   styleMask:(unsigned int)aStyle
{
	return 0.0;
}

+ (float) _titleBarHeightForStyleMask:(unsigned int) mask
{ // make dependent on total window height (i.e. smaller title bar on a QVGA PDA screen)
	if((mask&GSAllWindowMask) == NSBorderlessWindowMask && [[NSScreen screens] count] > 0)
		return 0.0;	// no title bar
	if([[[NSScreen screens] objectAtIndex:0] frame].size.height < 400)
		return (mask&NSUtilityWindowMask)?12.0:16.0;
	else
		return (mask&NSUtilityWindowMask)?16.0:23.0;
}

#if 1
- (void) release
{
#if 0 && defined(__mySTEP__)
	free(malloc(8192));
#endif
	NSLog(@"release %p %@", self, self);
	[super release];
}
#endif

- (void) dealloc
{
#if 1
	NSLog(@"dealloc - %p %@ [%d]", self, self, [self retainCount]);
#endif
	[_parentWindow removeChildWindow:self];	// if we have a parent...
	[self setDelegate:nil];	// release delegate
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidChangeScreenParametersNotification object:nil];
	[self resignKeyWindow];
#if 0
	NSLog(@"a");
#endif
	[self resignMainWindow];
	[_windowController release];	// if any
	[_fieldEditor release];	// if it exists
	[_themeFrame _setWindow:nil];
#if 0
	NSLog(@"b3");
#endif
	[_themeFrame release]; // delete old one (does not really have a superview, therefore we don't call removeFromSuperview)
#if 0
	NSLog(@"c");
#endif
	//	[_backgroundColor release];
	[_miniWindowImage release];
	[_miniWindowTitle release];
	[_representedFilename release];
	[_windowTitle release];
	[_childWindows release];
#if 0
	NSLog(@"d");
#endif
	[_frameSaveName release];
	[_context release];	// if still existing
#if 0
	NSLog(@"e");
#endif
	[super dealloc];
}

- (id) init
{
	NSLog(@"should not -init NSWindow");
	return [self initWithContentRect:NSMakeRect(0.0, 0.0, 48.0, 48.0)
						   styleMask:GSAllWindowMask				// default style mask
							 backing:NSBackingStoreBuffered
							   defer:NO
							  screen:nil];
}

- (NSWindow *) initWithWindowRef:(void *) ref;
{
	if((self=[super init]))
		{
		_context=[[NSGraphicsContext graphicsContextWithGraphicsPort:ref flipped:YES] retain];
		[self _setFrame:[_context _frame]];	// get frame from existing window
		_w.isOneShot=NO;
		// FIXME: anything else to init?
		}
	return self;
}

- (void) _screenParametersNotification:(NSNotification *) notification;
{
#if 0
	NSLog(@"%@ _screenParametersNotification: %@", NSStringFromClass([self class]), notification);
#endif
	if(notification)
		; // FIXME: we might have to rearrange menu bars! - better solutions: menu bars separately register for this notification
	if( _w.visible)
		[self orderFront:nil];	// this will resize the window if needed
}

- (id) initWithContentRect:(NSRect)cRect
				 styleMask:(unsigned int)aStyle
				   backing:(NSBackingStoreType)bufferingType
					 defer:(BOOL)flag
{
	return [self initWithContentRect:cRect 
						   styleMask:aStyle
							 backing:bufferingType 
							   defer:flag 
							  screen:nil];
}

- (id) initWithContentRect:(NSRect)cRect
				 styleMask:(unsigned int)aStyle
				   backing:(NSBackingStoreType)bufferingType
					 defer:(BOOL)defer
					screen:(NSScreen *)aScreen
{
	if((self=[super init]))
		{
#if 0
		NSLog(@"NSWindow initWithContentRect:%@ styleMask:%04x backing:%04x screen:%@", NSStringFromRect(cRect), aStyle, bufferingType, aScreen);
#endif
		_miniWindowTitle = _windowTitle = _representedFilename = @"Window";
		if(!aScreen)
			aScreen=[NSScreen mainScreen];	// use main screen (defined by keyWindow) if possible
		if(!aScreen)
			aScreen=[[NSScreen screens] objectAtIndex:0];	// menu bar screen if there is no main screen (yet)
		if(!aScreen)
			[NSException raise:NSGenericException format:@"Unable to find a default NSScreen"];
		_screen=aScreen;	// screens are never released
		_w.menuExclude = [self isKindOfClass:[NSPanel class]];
		_level=NSNormalWindowLevel;	// default for NSWindows
		if(aStyle&NSUnscaledWindowMask)
			_userSpaceScaleFactor=1.0;
		else
			_userSpaceScaleFactor=[_screen userSpaceScaleFactor];	// ask the screen
		_w.backingType = bufferingType;
		_w.styleMask = aStyle;
		_w.needsDisplay = NO;	// will be set by first expose
		_w.autodisplay = YES;
		_w.optimizeDrawing = YES;
		_w.dynamicDepthLimit = YES;
		_w.releasedWhenClosed = YES;
		_w.acceptsMouseMoved = NO;  // default
		_w.cursorRectsEnabled = YES;
		_w.canHide = YES;
		_w.hidesOnDeactivate = NO;	// default
		_frame=[NSWindow frameRectForContentRect:cRect styleMask:aStyle];		// get requested screen frame
		_themeFrame=[[NSThemeFrame alloc] initWithFrame:(NSRect){{0, 0}, _frame.size} forStyleMask:aStyle forScreen:_screen];	// create view hierarchy
		[_themeFrame _setWindow:self];
		[_themeFrame setNextResponder:self];
		[self setNextResponder:NSApp];	// NSApp is next responder
		if(!defer)
			[self orderWindow:NSWindowAbove relativeTo:0];	// insert sort relative to self; add to Window menu when being mapped
#if 0
		NSLog(@"NSWindow end of designated initializer\n");
#endif
		// fixme - should we register each individual window???
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_screenParametersNotification:)
													 name:NSApplicationDidChangeScreenParametersNotification
												   object:nil];
		}
	return self;
}

- (void) _allocateGraphicsContext
{
	if(!_context)
		{ // allocate context (had been temporarily deallocated if we are a oneshot window)
			_context=[[NSGraphicsContext graphicsContextWithWindow:self] retain];	// now, create window on server (will set level)
			_gState=[_context _currentGState];			// save gState
		}
}

- (NSString *) title						{ return _windowTitle; }
- (NSString *) miniwindowTitle				{ return _miniWindowTitle; }
- (NSString *) representedFilename			{ return _representedFilename; }
- (NSImage *) miniwindowImage				{ return _miniWindowImage; }
- (unsigned int) styleMask					{ return _w.styleMask; }
- (void)setBackingType:(NSBackingStoreType)t{ _w.backingType = t; }	// FIXME: should be reflected in the backend!
- (NSBackingStoreType) backingType			{ return _w.backingType; }
- (NSDictionary *) deviceDescription		{ return [_screen deviceDescription]; }
- (NSGraphicsContext*) graphicsContext		{ return _context; }
- (int) gState								{ return _gState; }
- (int) windowNumber						{ return [_context _windowNumber]; }
- (void *) windowRef						{ return [_context graphicsPort]; }
- (NSColor *) backgroundColor				{ return [(NSThemeFrame *) _themeFrame backgroundColor]; }
- (void) setBackgroundColor:(NSColor*)color	{ [(NSThemeFrame *) _themeFrame setBackgroundColor:color]; }
- (void) setMiniwindowImage:(NSImage*)image	{ ASSIGN(_miniWindowImage,image); }
- (void) setOneShot:(BOOL)flag				{ _w.isOneShot = flag; }
- (void) _setTexturedBackground:(BOOL)flag;	{ [(NSThemeFrame *) _themeFrame _setTexturedBackground:flag]; }	// undocumented method

- (void) setTitle:(NSString*)aString
{
	ASSIGN(_windowTitle, aString);						// local cache
	[(NSThemeFrame *) _themeFrame setTitle:aString];	// theme frame
	[_context _setTitle:aString];						// backend might want to pass to some window manager
	[(NSThemeFrame *) _themeFrame setTitleIcon:nil];				// no icon
	if(_w.visible && !_w.menuExclude)
		[NSApp changeWindowsItem:self title:_windowTitle filename:NO];
}

- (void) setTitleWithRepresentedFilename:(NSString*)aString
{
	aString=[aString stringByExpandingTildeInPath];
	[self setRepresentedFilename: aString];
	ASSIGN(_windowTitle, [aString lastPathComponent]);	// local cache
	[(NSThemeFrame *) _themeFrame setTitle:aString];	// theme frame
	[_context _setTitle:aString];						// backend might want to pass to some window manager
	if([aString isAbsolutePath])
		[(NSThemeFrame *) _themeFrame setTitleIcon:[[NSWorkspace sharedWorkspace] iconForFile:aString]];	// get document icon - if found
	if(_w.visible && !_w.menuExclude)
		[NSApp changeWindowsItem:self title:_windowTitle filename:YES];
}

- (BOOL) isOneShot							{ return _w.isOneShot; }
- (id) contentView							{ return [(NSThemeFrame *) _themeFrame contentView]; }
- (NSView *) _themeFrame					{ return _themeFrame; }

- (void) setContentView:(NSView *)aView				
{
#if 0
	NSLog(@"setContentView: %@", [aView _descriptionWithSubviews]);
#endif
	[(NSThemeFrame *) _themeFrame setContentView:aView];
}

- (void) setRepresentedFilename:(NSString *)aString
{
	ASSIGN(_representedFilename, aString);
}

- (void) setRepresentedURL:(NSURL *) url
{
	//	ASSIGN(_representedFilename, aString);
	//	[[<window> standardWindowButton:NSWindowDocumentIconButton] setImage:<image>]
}

- (void) setMiniwindowTitle:(NSString *)title
{
	ASSIGN(_miniWindowTitle, title);
	//	if (_w.miniaturized == NO);					// FIX ME redisplay miniWin
}

- (void) endEditingFor:(id)anObject					// field editor
{
#if 1
	NSLog(@"NSWindow endEditingFor: %@", anObject);
#endif
	if(![_fieldEditor resignFirstResponder] && _fieldEditor == _firstResponder)
		{ // if not then force resignation
			NSLog(@" NSWindow endEditingFor: current field editor did not resign voluntarily.");
			[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidEndEditingNotification
																object:_fieldEditor];
			[(_firstResponder = self) becomeFirstResponder];
		}
	[anObject removeFromSuperview];
	[anObject setDelegate:nil];
	[anObject setString:@""];	// emtpy any text
}

- (NSText *) fieldEditor:(BOOL)createFlag forObject:(id)anObject
{
	SEL s = @selector(windowWillReturnFieldEditor:toObject:);
	NSText *d;											// ask delegate if it can provide a field editor
	if (_delegate && [_delegate respondsToSelector:s])
		if ((d = [_delegate windowWillReturnFieldEditor:self toObject:anObject]))
			return d;
	if(!_fieldEditor && createFlag)					// each window has a global
		{											// text field editor, if it
			_fieldEditor = [NSTextView new];			// doesn't exist create it
			[_fieldEditor setFieldEditor:YES]; 			// if create flag is set					 
		}
	return _fieldEditor;							
}

- (int) level								{ return _level; }
- (BOOL) canHide							{ return _w.canHide; }
- (BOOL) hidesOnDeactivate					{ return _w.hidesOnDeactivate; }
- (BOOL) isMiniaturized						{ return _w.miniaturized; }
- (BOOL) isVisible							{ return _w.visible; }

- (void) _setIsVisible:(BOOL) flag
{
#if 1
	NSLog(@"_setIsVisible: %d", flag);
#endif
	if(_w.visible == flag)
		return;
	_w.visible=flag;
	if(flag)
		[_themeFrame setNeedsDisplay:YES];
}

- (BOOL) isKeyWindow						{ return [_context _windowNumber] == [_screen _keyWindowNumber]; }	// this asks the backend if we are really the key window!
- (BOOL) isMainWindow						{ return _w.isMain; }

- (void) becomeKeyWindow
{
#if 0
	NSLog(@"becomeKeyWin %@", _windowTitle);
#endif
	if(_w.isKey)	// we are already key window
		return;
	_w.isKey = YES;
	if(_w.visible)	// already visible
		{
#if 0
		NSLog(@"becomeKeyWindow _makeKeyWindow");
#endif
		[_context _makeKeyWindow];
		[_context flushGraphics];
		}
	if(!_w.cursorRectsValid)
		[self resetCursorRects];	
	[_firstResponder becomeFirstResponder];
	[_themeFrame setNeedsDisplay:YES];	// update title bar, buttons etc.
	[[NSNotificationCenter defaultCenter] postNotificationName: NOTE(DidBecomeKey) object: self];
}

- (void) becomeMainWindow
{
	if (_w.isMain)
		return;										
	_w.isMain = YES;								// We are the main window
	[_themeFrame setNeedsDisplay:YES];	// update title bar, buttons etc.
	[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidBecomeMainNotification object: self];
}

- (BOOL) canBecomeKeyWindow					
{ 
	return (_w.styleMask & (NSTitledWindowMask|NSResizableWindowMask)); 
}

- (BOOL) canBecomeMainWindow					
{ 
	return (_w.styleMask & (NSTitledWindowMask|NSResizableWindowMask));
}

- (void) makeKeyAndOrderFront:(id) sender
{
#if 0
	NSLog(@"makeKeyAndOrderFront: %@", self);
#endif
	[self orderFront:sender];						// order self to the front
#if 0
	NSLog(@"isKey: %d", _w.isKey);
#endif
	if(!_w.isKey)
		{
		[self makeKeyWindow];						// Make self the key window
		[self makeMainWindow];
		}
}

- (void) makeKeyWindow
{													// Can we become the key
#if 0
	NSLog(@"makeKeyWindow: %@", self);
#endif
	if ((_w.isKey) || ![self canBecomeKeyWindow]) 	// window?
		return;										
	[[NSApp keyWindow] resignKeyWindow];			// ask current key window to resign status
	[self becomeKeyWindow];
}													 

- (void) makeMainWindow
{													// Can we become main win
	if ((_w.isMain) || ![self canBecomeMainWindow])
		return;
	// ask current main window
	[[NSApp mainWindow] resignMainWindow];			// to resign status
	[self becomeMainWindow];
}													

- (void) resignKeyWindow
{
#if 0
	NSLog(@"resignKeyWindow");
#endif
	if (!(_w.isKey))
		return;
	_w.isKey = NO;
	[_firstResponder resignFirstResponder];
	[NSCursor pop];									// empty cursor stack
	[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResignKeyNotification object: self];
#if 0
	NSLog(@"notified");
#endif
	[_themeFrame setNeedsDisplay:YES];	// update title bar, buttons etc.
}

- (void) resignMainWindow
{
	if (!(_w.isMain))
		return;
	_w.isMain = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResignMainNotification object:self];
	[_themeFrame setNeedsDisplay:YES];	// update title bar and buttons
}

- (void) orderWindow:(NSWindowOrderingMode) place 
		  relativeTo:(int) otherWin
{ // main interface call
#if 1
	NSString *str[]={ @"Below", @"Out", @"Above" };
	NSLog(@"orderWindow:NSWindow%@ relativeTo:%d - %@", str[place+1], otherWin, self);
#endif
	if(place == NSWindowOut)
		{ // close window
			if(!_context)
				return;	// wasn't ordered in
		}
	else
		{
		[self _allocateGraphicsContext];
		[self setFrame:[self constrainFrameRect:_frame toScreen:_screen] display:_w.visible animate:_w.visible];	// constrain window frame if needed
		if(!_w.visible)
			{ // wasn't visible yet
				_w.needsDisplay = NO;							// reset first -display may result in callbacks that will set this flag again
				[_themeFrame displayIfNeeded];					// Draw the window view hierarchy (if changed) before mapping
			}
		
		// FIXME: don't move a window in front of the key window unless both are in the same application
		// => make dependent on [self isKeyWindodow];
		
		if(!otherWin)
			{ // find first/last window on same level to place in front/behind
				int i;
				int thisWin=[self windowNumber];
				int n=[NSScreen _systemWindowListForContext:0 size:99999 list:NULL];	// get number of windows
				int *list=(int *) objc_malloc(n*sizeof(int));	// allocate buffer
				[NSScreen _systemWindowListForContext:0 size:n list:list];	// fetch window list (must be front to back stacking order, i.e. highest to lowest levels)
#if 0
				{
				int prevlevel=999999;
				for(i=0; i<n; i++)
					{
					int level=[NSWindow _getLevelOfWindowNumber:list[i]];
					NSLog(@"[%02d]: %d %d %@", i, list[i], level, [NSApp windowWithWindowNumber:list[i]]);
					if(level >= 0)
						{
						if(level > prevlevel)
							NSLog(@"window stacking problem!");
						prevlevel=level;
						}
					}
				}
#endif
				for(i=0; i<n; i++)
					{ // go from front to back to find insertion position
						int level;
						if(list[i] == thisWin)
							continue;	// skip ourselves in calculating new position
						level=[NSWindow _getLevelOfWindowNumber:list[i]];	// BACKEND extension
#if 0
						NSLog(@"win %d level %d", list[i], level);
#endif
						//							if(level < 0)
						//								continue;	// we don't know - so ignore
						if(place == NSWindowBelow && level < _level)
							break;	// window has a lower level as ours, i.e. the previous was the last of our level
						otherWin=list[i];
						if(place == NSWindowAbove && level <= _level)
							break;	// window is first with same or lower level as ours, i.e. the current front window on this level
					} // otherwin may remain 0 which means total front or back!
				if(i == n && place == NSWindowAbove)	// did not find an appropriate level (all others have higher level)
					place=NSWindowBelow, otherWin=0;	// move behind all levels
#if 1
				NSLog(@"otherwin = %d", otherWin);
#endif
				objc_free(list);
			}
		}
	[_context _orderWindow:place relativeTo:otherWin];	// request map/umap/restack from backend
	if(place != NSWindowOut)
		{
		if(!_w.menuExclude)
			[NSApp changeWindowsItem:self title:_windowTitle filename:NO];	// update
#if 0
		if(_w.isKey)
			NSLog(@"orderWindow XSetInputFocus");
#endif
		if(_w.isKey)
			[_context _makeKeyWindow];
		if(_initialFirstResponder && !_firstResponder && ![self makeFirstResponder:_initialFirstResponder])
			NSLog(@"refused initialFirstResponder %@", _initialFirstResponder);
		[_firstResponder becomeFirstResponder];
		}
	else if(_w.isOneShot)
		{ // also close the screen representation
			[_context release];
			_context=nil;
			_gState=0;
		}
}

// convenience calls
// FIXME: if([[NSUserDefaults standardUserDefaults] boolValueForKey:@"animatedWindowOrdering"]
// then slide the windows in/out

- (void) orderFront:(id) Sender; { [self orderWindow:NSWindowAbove relativeTo:0]; }
- (void) orderBack:(id) Sender; { [self orderWindow:NSWindowBelow relativeTo:0]; }
- (void) orderOut:(id) Sender; { [self orderWindow:NSWindowOut relativeTo:0]; }
- (void) orderFrontRegardless	{ [self orderFront:nil]; }

- (void) setLevel:(int)newLevel
{
	if(_level == newLevel)
		return;	// unchanged
	_level=newLevel;
	if(_w.visible)
		[self orderWindow:NSWindowAbove relativeTo:0];	// if visible - order front
}

- (void) setCanHide:(BOOL)flag				{ _w.canHide = flag; }
- (void) setHidesOnDeactivate:(BOOL)flag	{ _w.hidesOnDeactivate = flag; }

- (NSPoint) cascadeTopLeftFromPoint:(NSPoint)topLeftPoint
{
	static NSPoint cascadePoint = { 0, 0 };
	NSSize screenSize = [_screen visibleFrame].size;
	NSPoint new = { topLeftPoint.x + 25, topLeftPoint.y - 25 };
	
	if(NSEqualPoints(topLeftPoint, NSZeroPoint))
		; // constrain to screen but don't move
	else
		[self setFrameTopLeftPoint:topLeftPoint];
	
	if(new.x + _frame.size.width > screenSize.width)
		{
		new.x = 30 + cascadePoint.x;
		cascadePoint.x = (cascadePoint.x < 200) ? cascadePoint.x + 50 : 25;
		}
	if(new.y - _frame.size.height < 0)
		{
		new.y = screenSize.height - (30 + cascadePoint.y);
		cascadePoint.y = (cascadePoint.y < 200) ? cascadePoint.y + 50 : 25;
		}
	return new;
}

- (void) center
{ // center the window within it's screen (not within visibleFrame)
	NSSize screenSize = [_screen frame].size;
	NSPoint origin = _frame.origin;
	origin.x = (screenSize.width - _frame.size.width) / 2;
	origin.y = (screenSize.height - _frame.size.height) / 2;
#if 0
	NSLog(@"screenSize = %@", NSStringFromSize(screenSize));
	NSLog(@"frame = %@", NSStringFromRect(_frame));
	NSLog(@"origin = %@", NSStringFromPoint(origin));
#endif
	[self setFrameOrigin:origin];
#if 0
	NSLog(@"new frame = %@", NSStringFromRect(_frame));
#endif
}

- (NSRect) constrainFrameRect:(NSRect)rect toScreen:(NSScreen *)screen
{
	BOOL autoEnlarge=[[NSUserDefaults standardUserDefaults] boolForKey:@"autoZoomResizableWindowsToScreen"];	// should be set in global user defaults
	NSRect vf;
#if 0
	NSLog(@"constrain rect %@ forscreen %@ mask %0x", NSStringFromRect(rect), NSStringFromRect([screen visibleFrame]), _w.styleMask);
#endif
	if((_w.styleMask & GSAllWindowMask) == NSBorderlessWindowMask)
		{
#if 0
		NSLog(@"borderless");
#endif
		return rect;	// never constrain
		}
	vf=[screen visibleFrame];
	if((_w.styleMask & NSResizableWindowMask) != 0 && ((autoEnlarge && ![self isKindOfClass:[NSPanel class]]) || [self interfaceStyle] >= NSPDAInterfaceStyle))
		{
#if 1
		NSLog(@"autoZoomResizableWindowsToScreen to full screen %@", self);
#endif
		return vf;	// resize to full screen for PDA styles
		}
	if(NSMaxX(rect) > NSMaxX(vf))
		rect.origin.x=NSMaxX(vf)-NSWidth(rect);	// goes beyond right edge - move left
	if(NSMinX(rect) < NSMinX(vf))
		rect.origin.x=NSMinX(vf);	// goes beyond left edge - move right
	if(NSMaxY(rect) > NSMaxY(vf))
		rect.origin.y=NSMaxY(vf)-NSHeight(rect);	// goes beyond top edge - move down
	if(NSMinY(rect) < NSMinY(vf))
		rect.origin.y=NSMinY(vf);	// goes beyond bottom edge - move up
#if 0
	NSLog(@"shifted frameRect %@", NSStringFromRect(rect));
#endif
	rect=NSIntersectionRect(vf, rect);	// too large - reduce to visible frame if still too large
#if 0
	NSLog(@"constrained frameRect %@", NSStringFromRect(rect));
#endif
	return rect;
}

- (NSRect) contentRectForFrameRect:(NSRect) frameRect
{
	frameRect=[NSWindow contentRectForFrameRect:frameRect styleMask:_w.styleMask];
	// FIXME: subtract toolbar height
	// scale by userspace factor
	return frameRect;
}

- (NSRect) frameRectForContentRect:(NSRect) cRect
{
#if 0
	NSLog(@"frameRectForContentRect:%@", NSStringFromRect(cRect));
#endif
	cRect=[NSWindow frameRectForContentRect:cRect styleMask:_w.styleMask];
#if 0
	NSLog(@"frameRectForContentRect -> %@", NSStringFromRect(cRect));
#endif
	// scale by userspace factor
	return cRect;
}

- (NSRect) frame								{ return _frame; }
- (NSSize) minSize								{ return _minSize; }
- (NSSize) maxSize								{ return _maxSize; }

- (void) setContentSize:(NSSize)aSize
{
	NSRect r={ _frame.origin, aSize };
#if 0
	NSLog(@"setContentSize ->%@", NSStringFromRect(r));
#endif
	// limit to be larger than minSize and smaller than maxSize!
	[self setFrame:[self frameRectForContentRect:r] display:_w.visible];
}

// FIXME: handle childWindows (in setFrame/setFrameOrigin?)

- (void) setFrameTopLeftPoint:(NSPoint)aPoint
{
	[self setFrameOrigin:NSMakePoint(aPoint.x, aPoint.y-[NSWindow _titleBarHeightForStyleMask:_w.styleMask]-_frame.size.height)];
}

- (void) setFrameOrigin:(NSPoint)aPoint
{
	// FIXME: apply screen limits here???
	if(!NSEqualPoints(aPoint, _frame.origin))
		{
		NSRect r={aPoint, _frame.size};
		[_context _setOrigin:r.origin];
		_frame.origin=aPoint;	// remember; no need to update theme frame
		}
}

- (void) setFrame:(NSRect)r display:(BOOL)flag
{
#if 0
	NSLog(@"setFrame:%@ display:%d", NSStringFromRect(r), flag);
#endif
	// FIXME: apply screen limits here???
	if(!NSEqualSizes(r.size, _frame.size))
		{ // resize (and move)
			[_context _setOriginAndSize:r];	// set origin since we must "move" in X11 coordinates even if we resize only
			[self _setFrame:r];	// update content view size etc.
			_w.isZoomed=NO;	// no longer remember old size
		}
	else if(!NSEqualPoints(r.origin, _frame.origin))
		{ // move only
			[_context _setOrigin:r.origin];
			[self _setFrame:r];	// update content view etc.
		}
	else if(!flag)
		return;	// NOOP request
	if(flag)
		[self display];	// if requested in addition
}

- (void) _setFrame:(NSRect) rect
{ // this is also used as a callback from window manager
#if 0
	NSLog(@"_setFrame:%@", NSStringFromRect(rect));
#endif
	if(NSEqualRects(rect, _frame))
		return;	// no change
	if(!NSEqualSizes(rect.size, _frame.size))
		{ // needs to resize content view
			_frame=rect;
			[(NSThemeFrame *) _themeFrame setFrameSize:rect.size];	// adjust theme frame subviews and content View
			[(NSThemeFrame *) _themeFrame layout];
		}
	else
		{
		_frame.origin=rect.origin;	// just moved
#if 0
		NSLog(@"window has no need to re-layout: %@", self);
#endif
		}
}

- (void) setFrame:(NSRect) rect display:(BOOL) flag animate:(BOOL) animate
{
	if(NSEqualRects(rect, _frame))
		return;	// no change
#if 0	// if window animation works
	if(animate)
		{ // smooth resize
			NSArray *animations=[NSArray arrayWithObject:
								 [NSDictionary dictionaryWithObjectsAndKeys:
								  //				[NSValue valueWithRect:_frame], NSViewAnimationStartFrameKey,	// current frame
								  [NSValue valueWithRect:rect], NSViewAnimationEndFrameKey,		// new frame
								  self, NSViewAnimationTargetKey,
								  nil]
								 ];
			NSViewAnimation *a=[[[NSViewAnimation alloc] initWithViewAnimations:animations] autorelease];
			[a startAnimation];	// start
			return;
		}
#endif
	[self setFrame:rect display:flag];	// just setFrame...
}

- (void) setMinSize:(NSSize)aSize				{ _minSize = aSize; }
- (void) setMaxSize:(NSSize)aSize				{ _maxSize = aSize; }
- (void) setResizeIncrements:(NSSize)aSize		{ _resizeIncrements = aSize; }

- (NSAffineTransform *) _base2screen;
{ // return matrix to transform base coordinates to screen coordinates
	NSAffineTransform *atm=[NSAffineTransform transform];
	// FIXME: handle userSpaceScaling here?
	[atm translateXBy:_frame.origin.x yBy:_frame.origin.y];
#if 0
	NSLog(@"_base2screen=%@", atm);
#endif
	return atm;
}

- (NSPoint) convertBaseToScreen:(NSPoint)base
{
	return [[self _base2screen] transformPoint:base];
}

- (NSPoint) convertScreenToBase:(NSPoint)screen
{
	NSAffineTransform *atm=[[self _base2screen] copy];
	[atm invert];
	[atm autorelease];
	return [atm transformPoint:screen];
}

- (void) display
{
	if(!_w.visible)
		[self orderFront:nil];	// will call -update when window becomes mapped
	else
		{
		NSAutoreleasePool *arp=[NSAutoreleasePool new];	// collect all drawing temporaries here
		_w.needsDisplay = NO;	// reset first - display may result in callbacks that will set this flag again
		[self disableFlushWindow];						// tmp disable of display
		[_themeFrame display];							// Draw the window view hierarchy (if changed)
		[self enableFlushWindow];						// Reenable displaying
		[self flushWindowIfNeeded];
		[arp release];
		}
}													

- (void) displayIfNeeded
{
	if(!_w.visible)
		[self orderFront:nil];	// will call -update when window becomes mapped
	else
		{
		NSAutoreleasePool *arp=[NSAutoreleasePool new];	// collect all drawing temporaries here
		_w.needsDisplay = NO;	// reset first - display may result in callbacks that will set this flag again
		[self disableFlushWindow];						// tmp disable of display
		[_themeFrame displayIfNeeded];					// Draw the window view hierarchy (if changed)
		[self enableFlushWindow];						// Reenable displaying
		[self flushWindowIfNeeded];
		[arp release];
		}
}

- (void) update
{
#if 0
	NSLog(@"%@ update %d %d", self, _w.autodisplay, _w.needsDisplay);
#endif
	if(_w.autodisplay && _w.needsDisplay && _w.visible)
		{ // if autodisplay is enabled and window needs display
#if 0
			NSLog(@"%@ update %@", self, [_themeFrame _descriptionWithSubviews]);
#endif
			[self displayIfNeeded];	// display subviews if needed
    	}
	[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidUpdateNotification object:self];
}

- (void) flushWindowIfNeeded
{
	if (!_w.disableFlushWindow && _w.needsFlush) 
		[self flushWindow];
}

- (void) disableFlushWindow					{ _w.disableFlushWindow = YES; }
- (void) flushWindow						{ [_context flushGraphics]; }						
- (void) enableFlushWindow					{ _w.disableFlushWindow = NO; }
- (BOOL) isAutodisplay						{ return _w.autodisplay; }
- (BOOL) isFlushWindowDisabled				{ return _w.disableFlushWindow; }
- (void) setAutodisplay:(BOOL)flag			{ _w.autodisplay = flag; }
- (void) setViewsNeedDisplay:(BOOL)flag		{ _w.needsDisplay = flag; }
- (BOOL) viewsNeedDisplay					{ return _w.needsDisplay; }
- (void) useOptimizedDrawing:(BOOL)flag		{ _w.optimizeDrawing = flag; }
- (BOOL) canStoreColor						{ return (_w.depthLimit > 1); }
- (NSWindowDepth) depthLimit				{ return _w.depthLimit; }
- (BOOL) hasDynamicDepthLimit				{ return _w.dynamicDepthLimit; }
- (NSScreen *) screen						{ return _screen; }
- (NSScreen *) deepestScreen				{ return _screen?_screen:[NSScreen deepestScreen]; }
- (void) setDepthLimit:(NSWindowDepth)limit	{ _w.depthLimit = limit; }
- (void) setDynamicDepthLimit:(BOOL)flag	{ _w.dynamicDepthLimit = flag; }
- (int) resizeFlags							{ return 0; }

- (void) setDocumentEdited:(BOOL)flag
{
	_w.isEdited=flag;	// keep a local copy if we have no close button for any reason
	[(_NSThemeCloseWidget*) [(NSThemeFrame *) _themeFrame standardWindowButton:NSWindowCloseButton] setDocumentEdited:flag];
	[NSApp updateWindowsItem:self];	// modify menu state
	// we could/should forward to the backend...
}

- (void) setReleasedWhenClosed:(BOOL)flag
{
#if 0
	NSLog(@"%@: setReleasedWhenClosed:%d", _windowTitle, flag);
#endif
	_w.releasedWhenClosed = flag; 
}

- (BOOL) acceptsMouseMovedEvents			{ return _w.acceptsMouseMoved; }
- (BOOL) isExcludedFromWindowsMenu			{ return _w.menuExclude; }
- (void) setAcceptsMouseMovedEvents:(BOOL)f	{ _w.acceptsMouseMoved = f;}

- (void) setExcludedFromWindowsMenu:(BOOL)f
{
	if(_w.menuExclude == f)
		return;	// no change
	if((_w.menuExclude = f))
		[NSApp removeWindowsItem:self];	// became excluded
	else if(_w.visible)	// became included
		[NSApp addWindowsItem:self title:_windowTitle filename:NO];	// add
}

- (NSEvent *) currentEvent					{ return [NSApp currentEvent]; }
- (id) delegate								{ return _delegate; }

- (void) setDelegate:(id)anObject
{
	NSNotificationCenter *n;
	
	if(_delegate == anObject)
		return;
	
#define IGNORE_(notif_name) [n removeObserver:_delegate \
name:NSWindow##notif_name##Notification \
object:self]
	
	n = [NSNotificationCenter defaultCenter];
	if (_delegate)
		{
		IGNORE_(DidBecomeKey);
		IGNORE_(DidBecomeMain);
		IGNORE_(DidChangeScreen);
		IGNORE_(DidDeminiaturize);
		IGNORE_(DidExpose);
		IGNORE_(DidMiniaturize);
		IGNORE_(DidMove);
		IGNORE_(DidResignKey);
		IGNORE_(DidResignMain);
		IGNORE_(DidResize);
		IGNORE_(DidUpdate);
		IGNORE_(WillClose);
		IGNORE_(WillMiniaturize);
		}
	
	ASSIGN(_delegate, anObject);
	if(!anObject)
		return;
	
#define OBSERVE_(notif_name) \
if ([_delegate respondsToSelector:@selector(window##notif_name:)]) \
[n addObserver:_delegate \
selector:@selector(window##notif_name:) \
name:NSWindow##notif_name##Notification \
object:self]
	
	OBSERVE_(DidBecomeKey);
	OBSERVE_(DidBecomeMain);
	OBSERVE_(DidChangeScreen);
	OBSERVE_(DidDeminiaturize);
	OBSERVE_(DidExpose);
	OBSERVE_(DidMiniaturize);
	OBSERVE_(DidMove);
	OBSERVE_(DidResignKey);
	OBSERVE_(DidResignMain);
	OBSERVE_(DidResize);
	OBSERVE_(DidUpdate);
	OBSERVE_(WillClose);
	OBSERVE_(WillMiniaturize);
	OBSERVE_(WillMove);
}

- (void) discardCursorRects
{
	[_cursorRects removeAllObjects];
}

- (void) invalidateCursorRectsForView:(NSView *)aView
{
	if(aView)
		{
		if(_w.isKey)
			{
			[aView discardCursorRects];
			[aView resetCursorRects];
			}
		else
			_w.cursorRectsValid = NO;
		}
}

- (void) resetCursorRects
{
	[self discardCursorRects];
	[_themeFrame resetCursorRects];
	_w.cursorRectsValid = YES;
}

- (void) disableCursorRects					{ _w.cursorRectsEnabled = NO; }
- (void) enableCursorRects					{ _w.cursorRectsEnabled = YES; }
- (BOOL) areCursorRectsEnabled				{ return _w.cursorRectsEnabled; }
- (BOOL) isDocumentEdited					{ return _w.isEdited; }
- (BOOL) isReleasedWhenClosed				{ return _w.releasedWhenClosed; }
- (BOOL) isZoomed							{ return _w.isZoomed; }

- (void) miniaturize:(id)sender
{
	if(_w.miniaturized)
		return;
	[[NSNotificationCenter defaultCenter] postNotificationName: NOTE(WillMiniaturize) object:self];
	_w.miniaturized = YES; 
	[_context _miniaturize];
	[[NSNotificationCenter defaultCenter] postNotificationName: NOTE(DidMiniaturize) object:self];
}

- (void) deminiaturize:(id)sender
{
	if(!_w.miniaturized)
		return;
	_w.miniaturized = NO;
	[_context _deminiaturize];
	[[NSNotificationCenter defaultCenter] postNotificationName: NOTE(DidDeminiaturize) object:self];
}

- (void) zoom:(id)sender
{
#if 1
	NSLog(@"Zoom %d", _w.isZoomed);
#endif
	if(!(_w.styleMask&NSResizableWindowMask))
		return;	// can't zoom
	if(!_w.isZoomed)
		{ // not yet zoomed
			NSRect defaultFrame=[_screen visibleFrame];
			NSRect proposedFrame=_delegate?[_delegate windowWillUseStandardFrame:self defaultFrame:defaultFrame]:defaultFrame;	// allow delegate to modify
#if 1
			NSLog(@"default frame %@", NSStringFromRect(defaultFrame));
			NSLog(@"delegate's frame %@", NSStringFromRect(proposedFrame));
#endif
			proposedFrame=NSIntersectionRect(proposedFrame, defaultFrame);	// limit to screen
#if 1
			NSLog(@"proposed frame %@", NSStringFromRect(proposedFrame));
#endif
			if(_delegate && ![_delegate windowShouldZoom:self toFrame:proposedFrame])
				return;	// delegate did veto
			_oldFrame=[self frame];	// remember current frame
#if 1
			NSLog(@"old frame %@", NSStringFromRect(_oldFrame));
#endif
			[self setFrame:proposedFrame display:YES animate:YES];
			_w.isZoomed=YES;	// setFrame did reset
		}
	else
		[self setFrame:_oldFrame display:YES animate:YES];	// this will also reset _w.isZoomed flag
}

- (void) close
{
#if 1
	NSLog(@"close %@", self);
	NSLog(@"retain count %d", [self retainCount]);
	if(_w.releasedWhenClosed)
		NSLog(@"close %@: releasedWhenClosed", _windowTitle);
#endif
	// Notify window's delegate
	[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillCloseNotification object:self];
	[self orderOut:self];	// might dealloc graphics context
	[NSApp removeWindowsItem:self];
	if(_w.releasedWhenClosed)	// do so. Default is YES for windows and NO for panels
		{
#if 1
		NSLog(@"close %@: releasedWhenClosed", _windowTitle);
		NSLog(@"our retain count %d", [self retainCount]);
#endif
		[self autorelease]; 
		}
}

- (void) _close:(id)sender									
{
#if 1
	NSLog(@"_close");
#endif
	if(!(_w.styleMask & NSClosableWindowMask))
		{											// self must have a close
			NSBeep();									// button in order to be
			return;										// closed
		}
	if([_delegate respondsToSelector:@selector(windowShouldClose:)])
		{											// if delegate responds to
			if(![_delegate windowShouldClose:self])		// windowShouldClose query
				{										// it to see if it's ok to
					NSBeep();								// close the window
					return;									
				}
		}
	else
		{
		if([self respondsToSelector:@selector(windowShouldClose:)])
			{										// else if self (i.e. a subclass of NSWindow) responds to
				if(![self windowShouldClose:self])		// windowShouldClose query
					{									// self to see if it's ok
						NSBeep();							// to close self
						return;								
					}
			}
		} 
	[self close];									// it's ok to close self								
}

- (void) performClose:(id)sender									
{
#if 1
	NSLog(@"%@ %@", NSStringFromSelector(_cmd), [self standardWindowButton:NSWindowCloseButton]);
#endif
	[[self standardWindowButton:NSWindowCloseButton] performClick:sender];
}

- (void) performMiniaturize:(id)sender									
{
#if 1
	NSLog(@"%@ %@", NSStringFromSelector(_cmd), [self standardWindowButton:NSWindowMiniaturizeButton]);
#endif
	[[self standardWindowButton:NSWindowMiniaturizeButton] performClick:sender];
}

- (void) performZoom:(id)sender									
{
#if 1
	NSLog(@"%@ %@", NSStringFromSelector(_cmd), [self standardWindowButton:NSWindowZoomButton]);
#endif
	[[self standardWindowButton:NSWindowZoomButton] performClick:sender];
}

- (void) discardEventsMatchingMask:(unsigned int)mask
					   beforeEvent:(NSEvent *)lastEvent
{
	[NSApp discardEventsMatchingMask:mask beforeEvent:lastEvent];
}

- (void) doCommandBySelector:(SEL) sel;
{
	if([self respondsToSelector:sel])
		[self performSelector:sel withObject:nil];
	else if(_nextResponder)
		[_nextResponder doCommandBySelector:sel];	// pass down
	else if(_delegate && [self respondsToSelector:_cmd])
		[_delegate doCommandBySelector:sel];		// pass down
	else
		[self noResponderFor:sel];	// Beep
}

- (NSResponder *) firstResponder			{ return _firstResponder; }
- (BOOL) acceptsFirstResponder				{ return YES; }

- (BOOL) makeFirstResponder:(NSResponder *)aResponder
{
#if 1
	NSLog(@"makeFirstResponder: %@", aResponder);
#endif
	if (_firstResponder == aResponder)				// if responder is already
		return YES;									// first responder return Y
	
	if(!aResponder)
		aResponder=self;	// nil makes us the first responder (e.g. if no initialFirstResponder is defined)
	if (![aResponder isKindOfClass: __responderClass])
		{
#if 1
		NSLog(@"not responder class");
#endif
		return NO;									// not a responder return N
		}
	if (![aResponder acceptsFirstResponder])		
		{
#if 1
		NSLog(@"does not accept status");
		return NO;									// does not accept status
		}
#endif
	if (_firstResponder)
		{ // resign first responder status
			NSResponder *first = _firstResponder;
			
			_firstResponder = nil;
			if (![first resignFirstResponder])			// the first responder must
				{ // agree to resign
					_firstResponder = first;	// did not!
#if 1
					NSLog(@"previous did not resign");
#endif
					return NO;
				}
		}
	
	if (__cursorHidden)
		[NSCursor unhide];
	__cursorHidden = NO;
	
	if (_firstResponder == aResponder)				// in case resignFirstResponder already set
		return YES;									// a new first responder
	
	if([(_firstResponder = aResponder) becomeFirstResponder])
		return YES;									// Notify responder of it's	
	// new status, make window
	_firstResponder = self;							// first if it refuses
#if 1
	NSLog(@"did finally refuse");
#endif	
	return NO;
}

- (NSEvent *) nextEventMatchingMask:(unsigned int)mask
{
	return [NSApp nextEventMatchingMask:mask 
							  untilDate:[NSDate distantFuture]
								 inMode:NSEventTrackingRunLoopMode 
								dequeue:YES];
}

- (NSEvent *) nextEventMatchingMask:(unsigned int)mask
						  untilDate:(NSDate *)expiration
							 inMode:(NSString *)mode
							dequeue:(BOOL)deqFlag
{
	return [NSApp nextEventMatchingMask:mask 
							  untilDate:expiration
								 inMode:mode 
								dequeue:deqFlag];
}

- (void) postEvent:(NSEvent *)event atStart:(BOOL)flag
{
	[NSApp postEvent:event atStart:flag];
}

- (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent;
{ // permit ink-anywhere
	return [[_themeFrame hitTest:[theEvent locationInWindow]] shouldBeTreatedAsInkEvent:theEvent];	// pass to view under pen (subview of theme frame)
}

- (void) sendEvent:(NSEvent *)event
{
	NSView *hit;
	if (!_w.cursorRectsValid)
		[self resetCursorRects];
	
	switch ([event type]) {
		case NSAppKitDefined: {
#if 1
			NSLog(@"Event %@", event);
#endif
			switch([event subtype]) {
				case NSWindowExposedEventType: {
					NSRect rect={[event locationInWindow], {[event data1], [event data2] }};
					NSDictionary *uinfo=[NSDictionary dictionaryWithObject:[NSValue valueWithRect:rect] forKey:@"NSExposedRect"];
#if 1
					NSLog(@"NSWindowExposedEventType %@", NSStringFromRect(rect));
#endif
					[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidExposeNotification
																		object:self
																	  userInfo:uinfo];
					rect=[_themeFrame convertRect:rect fromView:nil];	// from window to theme frame (which uses flipped coordinates!)
					[_themeFrame setNeedsDisplayInRect:rect];	// we know that we own the top-level view...
					if(!_w.needsDisplay)
						NSLog(@"window did expose but does not need to display? %@", self);
					break;
				}
					// should this event ever arrive at a NSWindow???
				case NSApplicationActivatedEventType: {
					[NSApp activateIgnoringOtherApps:YES];	// user has clicked: bring our application windows and menus to front
					if (!_w.isKey)
						[self makeKeyAndOrderFront:self];
					break;
				}
				case NSApplicationDeactivatedEventType: {
					break;
				}
				case NSWindowMovedEventType: {
#if 0
					NSLog(@"Window moved to %@", NSStringFromPoint([event locationInWindow]));
#endif
					// update frame origin (so that location based events are synchronous)
					break;
				}
				case NSScreenChangedEventType: {
					// check window geometry
				}
			}
			break;
		}
			
		case NSLeftMouseDown:								// Left mouse down
			if(!_w.visible || _w.ignoresMouseEvents)
				break;			// we check if we are still visible (user may have clicked while we were ordering out)
			if (__cursorHidden)
				{ 
					[NSCursor unhide]; 
					__cursorHidden = NO; 
				}
			hit = [_themeFrame hitTest:[event locationInWindow]];	// this assumes that we have already called shouldBeTreatedAsInkEvent!
			NSDebugLog([hit description]);
#if 0
			NSLog(@"NSLeftMouseDown: %@", event);
			NSLog(@"  locationInWindow=%@", NSStringFromPoint([event locationInWindow]));
			NSLog(@"  _themeFrame=%@", _themeFrame);
			NSLog(@"  hit=%@", hit);
#endif
			// FIXME: we should check for window movement and resize here so that we can honor [hit mouseDownCanMoveWindow]
			
			if((NSResponder *) hit != _firstResponder && [(NSResponder *) hit acceptsFirstResponder])
				[self makeFirstResponder:hit];		// make hit view first responder if not already and if it accepts
			if(_w.isKey)
				[hit mouseDown:event];
			else
				{ // first click makes it the key window unless the view asks for a delay
					if(![hit shouldDelayWindowOrderingForEvent:event])
						{
#if 1
						NSLog(@"first click results in makeKeyAndOrderFront: %@", hit);
#endif
						[self makeKeyAndOrderFront:self];	// bring clicked window to front
						}
					else
						[NSApp _setPendingWindow:self];		// register for delayed ordering
					if([hit acceptsFirstMouse:event])
						[hit mouseDown:event];
					else
						NSLog(@"rejects first mouse: %@", hit);
				}
			break;
			
		case NSLeftMouseUp:									// Left mouse up
			if(_w.ignoresMouseEvents)
				break;
#if 0
			NSLog(@"NSLeftMouseUp %@", hit);
#endif
			if (__cursorHidden)
				{ 
					[NSCursor unhide]; 
					__cursorHidden = NO;
				}
			hit = [_themeFrame hitTest:[event locationInWindow]];	// this assumes that we have already called shouldBeTreatedAsInkEvent!
			[hit mouseUp:event];
			break;
			
		case NSRightMouseDown:								// Right mouse down
			if(_w.ignoresMouseEvents)
				break;
			if (__cursorHidden)
				{ [NSCursor unhide]; __cursorHidden = NO; }
			hit = [_themeFrame hitTest:[event locationInWindow]];
			[hit rightMouseDown:event];
			break;
			
		case NSRightMouseUp:								// Right mouse up
			if(_w.ignoresMouseEvents)
				break;
			if (__cursorHidden)
				{ [NSCursor unhide]; __cursorHidden = NO; }
			hit = [_themeFrame hitTest:[event locationInWindow]];
			[hit rightMouseUp:event];
			break;
			
		case NSMouseMoved:									// Mouse moved
			if(_w.ignoresMouseEvents)
				break;
			if (__cursorHidden)
				{ [NSCursor unhide]; __cursorHidden = NO; }
			if(_w.acceptsMouseMoved)
				{
				NSView *v = [_themeFrame hitTest:[event locationInWindow]];
				[v mouseMoved:event];				// hit view passes event up
				}									// responder chain to self
			// if we accept mouse moved
			if(_w.cursorRectsEnabled)
				[self mouseMoved:event];	// handle cursor
			break;
			
		case NSLeftMouseDragged:									// Mouse moved
			if(_w.ignoresMouseEvents)
				break;
#if 0
			NSLog(@"NSLeftMouseDragged %@", hit);
#endif
			hit = [_themeFrame hitTest:[event locationInWindow]];
			[hit mouseDragged:event];
			break;
			
		case NSRightMouseDragged:									// Mouse moved
			hit = [_themeFrame hitTest:[event locationInWindow]];
			[hit mouseDragged:event];
			break;
			
		case NSKeyDown: {
			__lastKeyDown = _firstResponder;	// save the first responder so that the key up goes to it and not a possible new first responder
			if(!__cursorHidden)
				{
				if([_firstResponder respondsToSelector:@selector(isEditable)] &&
				   [(NSText *) _firstResponder isEditable] &&
				   (__cursorHidden = [NSCursor isHiddenUntilMouseMoves]))
					[NSCursor hide];
				}
#if 1
			NSLog(@"first Responder %@ keyDown %@", _firstResponder, event);
#endif
			[_firstResponder keyDown:event];
			break;
		}
			
		case NSKeyUp:
			if (__lastKeyDown)
				[__lastKeyDown keyUp:event];		// send Key Up to object that got the key down
			__lastKeyDown = nil;
			break;
			
		case NSScrollWheel:
			if(_w.ignoresMouseEvents)
				break;
			[[_themeFrame hitTest:[event locationInWindow]] scrollWheel:event];
			break;
			
		case NSCursorUpdate:
			if([event trackingNumber])						// a mouse entered
				[(id)[event userData] push];				// push the cursor
			else
				[NSCursor pop];								// a mouse exited
			// pop the cursor
		default:
			break;
	}
}

- (BOOL) performKeyEquivalent:(NSEvent*)event
{
#if 0
	BOOL r=[_themeFrame performKeyEquivalent:event];
	NSLog(@"%@ performKeyEquivalent -> %@", self, r?@"YES":@"NO");
	return r;
#else
	return [_themeFrame performKeyEquivalent:event];
#endif
}

- (BOOL) tryToPerform:(SEL)anAction with:anObject
{
	return [super tryToPerform:anAction with:anObject];
}

- (BOOL) worksWhenModal
{
	return NO;
}

- (void) dragImage:(NSImage *)anImage						// Drag and Drop
				at:(NSPoint)baseLocation
			offset:(NSSize)initialOffset
			 event:(NSEvent *)event
		pasteboard:(NSPasteboard *)pboard
			source:sourceObject
		 slideBack:(BOOL)slideFlag		{ BACKEND }

- (void) registerForDraggedTypes:(NSArray *)newTypes
{
	[_themeFrame registerForDraggedTypes:newTypes];
}

- (void) unregisterDraggedTypes		
{ 
	[_themeFrame unregisterDraggedTypes];
}

- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{
	if(_delegate)
		if ([_delegate respondsToSelector:@selector(concludeDragOperation:)])
			[_delegate concludeDragOperation:sender];
}

- (unsigned int) draggingEntered:(id <NSDraggingInfo>)sender
{
	if(_delegate && [_delegate respondsToSelector:@selector(draggingEntered:)])
		return [_delegate draggingEntered:sender];
	
	return NSDragOperationNone;
}

- (void) draggingExited:(id <NSDraggingInfo>)sender
{
	if (_delegate && [_delegate respondsToSelector:@selector(draggingExited:)])
		[_delegate draggingExited:sender];
}

- (unsigned int) draggingUpdated:(id <NSDraggingInfo>)sender
{
	if(_delegate && [_delegate respondsToSelector:@selector(draggingUpdated:)])
		return [_delegate draggingUpdated:sender];
	
	return NSDragOperationNone;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
	if(_delegate)
		if ([_delegate respondsToSelector:@selector(performDragOperation:)])
			return [_delegate performDragOperation:sender];
	
	return NO;
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	if(_delegate)
		if ([_delegate respondsToSelector:@selector(prepareForDragOperation:)])
			return [_delegate prepareForDragOperation:sender];
	
	return NO;
}

- (id) validRequestorForSendType:(NSString *)sendType		// Services menu
					  returnType:(NSString *)returnType
{
	id result = nil;
	
	if (_delegate && [_delegate respondsToSelector: _cmd])
		result = [_delegate validRequestorForSendType: sendType
										   returnType: returnType];
	
	if (result == nil)
		result = [NSApp validRequestorForSendType: sendType 
									   returnType: returnType];
	return result;
}

+ (void) removeFrameUsingName:(NSString *)name			// Save / restore frame	
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *key = [NSString stringWithFormat:@"NSWindow Frame %@",name];
	
	[defaults removeObjectForKey:key];
	[defaults synchronize];
	[__frameNames removeObjectForKey:name];
}

- (BOOL) setFrameAutosaveName:(NSString *)name
{
	if(!__frameNames)
		__frameNames = [NSMutableDictionary new];
	
	if([__frameNames objectForKey:name])
		return NO;
	
	ASSIGN(_frameSaveName, name);
	[__frameNames setObject:self forKey:name];
	
	return YES;
}

- (NSString *) frameAutosaveName			{ return _frameSaveName; }

- (void) saveFrameUsingName:(NSString *)name
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *key = [NSString stringWithFormat:@"NSWindow Frame %@",name];
	
	NSDebugLog(@"saveFrameUsingName %@\n",[NSValue valueWithRect:frame]);
	
	[defaults setObject:[NSValue valueWithRect:_frame] forKey:key];
	[defaults synchronize];
}

- (BOOL) setFrameUsingName:(NSString *)name	
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *key = [NSString stringWithFormat:@"NSWindow Frame %@",name];
	NSString *value = [defaults stringForKey:key];
	
	if(!value)
		return NO;
	
	NSDebugLog(@"setFrameUsingName %@\n", value);
	[self setFrameFromString: value];
	
	return YES;
}

- (void) setFrameFromString:(NSString *)string
{
	NSDictionary *d = [string propertyList];
	NSRect r;
#if 0
	NSLog(@"NSWindow setFrameFromString %@\n", string);
#endif
	r.origin.x = [[d objectForKey:@"x"] floatValue];
	r.origin.y = [[d objectForKey:@"y"] floatValue];
	r.size.width = [[d objectForKey:@"width"] floatValue];
	r.size.height = [[d objectForKey:@"height"] floatValue];
	r.size.width = MIN(MAX(r.size.width, _minSize.width), _maxSize.width);
	r.size.height = MIN(MAX(r.size.height, _minSize.height), _maxSize.height);
	
	if(_delegate)
		{
		if ([_delegate respondsToSelector:@selector(windowWillResize:toSize:)])
			r.size = [_delegate windowWillResize:self toSize:r.size];
		}
	[self setFrame:r display:NO];
}

- (NSString *) stringWithSavedFrame				
{ 
	return [[NSValue valueWithRect:_frame] description]; 
}

- (void) print:(id) sender
{
	NSPrintOperation *po=[NSPrintOperation printOperationWithView:[(NSThemeFrame *) _themeFrame contentView]];
	[po runOperationModalForWindow:self delegate:nil didRunSelector:NULL contextInfo:NULL];
}

- (NSString *) description;
{
#if 0
	NSLog(@"NSWindow description");
	NSLog(@" class %@", NSStringFromClass(isa));
	NSLog(@" win num %d", [_context _windowNumber]);
	NSLog(@" title %@", [self title]);
	NSLog(@" frame %@", NSStringFromRect(frame));
#endif
	return [NSString stringWithFormat:@"%@ [%lu]: title=%@ frame=%@",
			NSStringFromClass(isa),
			[_context _windowNumber],
			[self title],
			NSStringFromRect(_frame)];
}

- (NSView *) initialFirstResponder			{ return _initialFirstResponder; }

- (void) setInitialFirstResponder:(NSView *)aView
{
	_initialFirstResponder = aView;
}

- (void) selectNextKeyView:(id)sender
{
	id next;
	
	if(_firstResponder && _firstResponder != self)
		next = [(NSView *)_firstResponder nextValidKeyView];
	else
		if((next = _initialFirstResponder) && ![next acceptsFirstResponder])
			next = [(NSView *)_initialFirstResponder nextValidKeyView];
	
	if(next && [self makeFirstResponder:next])
		{
		if([next respondsToSelector:@selector(selectText:)])
			[(NSTextField *)next selectText:self];
		}
	else
		NSBeep();
}

- (void) selectPreviousKeyView:(id)sender
{
	id prev;
	
	if(_firstResponder && _firstResponder != self)
		prev = [(NSView *)_firstResponder previousValidKeyView];
	else
		if((prev = _initialFirstResponder) && ![prev acceptsFirstResponder])
			prev = [(NSView *)_initialFirstResponder previousValidKeyView];
	
	if(prev && [self makeFirstResponder:prev])
		{
		if([prev respondsToSelector:@selector(selectText:)])
			[(NSTextField *)prev selectText:self];
		}
	else
		NSBeep();
}

- (void) selectKeyViewFollowingView:(NSView *)aView
{
	if((aView = [aView nextValidKeyView]) && [self makeFirstResponder:aView] && [aView respondsToSelector:@selector(selectText:)])
		[(NSTextField *)aView selectText:self];
}

- (void) selectKeyViewPrecedingView:(NSView *)aView
{
	if((aView = [aView previousValidKeyView]) && [self makeFirstResponder:aView] && [aView respondsToSelector:@selector(selectText:)])
		[(NSTextField *)aView selectText:self];
}

- (void) encodeWithCoder:(NSCoder *)aCoder				// NSCoding protocol
{
	int _windowNum=[self windowNumber];
	[super encodeWithCoder:aCoder];
	
	NSDebugLog(@"NSWindow: start encoding\n");
	[aCoder encodeRect:_frame];
	[aCoder encodeObject:_themeFrame];
	[aCoder encodeObject:_initialFirstResponder];
	//  [aCoder encodeObjectReference: _delegate withName:NULL];
	[aCoder encodeValueOfObjCType:"i" at:&_windowNum];
	//	[aCoder encodeObject:_backgroundColor];
	[aCoder encodeObject:_representedFilename];
	[aCoder encodeObject:_miniWindowTitle];
	[aCoder encodeObject:_windowTitle];
	[aCoder encodeSize:_minSize];
	[aCoder encodeSize:_maxSize];
	[aCoder encodeObject:_miniWindowImage];
	[aCoder encodeValueOfObjCType:@encode(int) at: &_level];
	[aCoder encodeValueOfObjCType:@encode(unsigned int) at: &_w];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{ // we can only decode a NSWindowTemplate from NIBs and doc says that this call should create an error message!
	return NIMP;
}

- (void) setWindowController:(NSWindowController *)windowController; { ASSIGN(_windowController, windowController); }
- (id) windowController; { return _windowController; }

// FIXME: buttons should be returned with (0,0) origin!
// must call [button setFrameOrigin] to place it in its superview

+ (NSButton *) standardWindowButton:(NSWindowButton) type forStyleMask:(unsigned int) aStyle;
{ // caller is responsible for setting the target
	NSButton *b=nil;
	static NSSize smallImage={ 15.0, 15.0 };
	float button=[self _titleBarHeightForStyleMask:aStyle];	// adjust size
	// set style dependent windget cell, i.e. brushed metal
	switch(type) {
		case NSWindowCloseButton:
			// CHECKME: do we already position the buttons here or have they all an NSZeroPoint origin?
			b=[[_NSThemeCloseWidget alloc] initWithFrame:NSMakeRect(4.0, 0.0, button, button) forStyleMask:aStyle];
			[b setAction:@selector(_close:)];
			[b setEnabled:(aStyle&NSClosableWindowMask) != 0];
			[b setImage:[NSImage imageNamed:@"NSWindowCloseButton"]];
			//				[b setTitle:@"x"];
			[b setTitle:@""];
			[b setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
			break;
		case NSWindowMiniaturizeButton:
			b=[[_NSThemeWidget alloc] initWithFrame:NSMakeRect(3.0+button, 0.0, button, button) forStyleMask:aStyle];
			[b setAction:@selector(miniaturize:)];
			[b setEnabled:(aStyle&NSMiniaturizableWindowMask) != 0];
			[b setImage:[NSImage imageNamed:@"NSWindowMiniaturizeButton"]];
			//				[b setTitle:@"-"];
			[b setTitle:@""];
			[b setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
			break;
		case NSWindowZoomButton:
			b=[[_NSThemeWidget alloc] initWithFrame:NSMakeRect(2.0+2.0*button, 0.0, button, button) forStyleMask:aStyle];
			[b setAction:@selector(zoom:)];
			[b setEnabled:(aStyle&NSResizableWindowMask) != 0];
			[b setImage:[NSImage imageNamed:@"NSWindowZoomButton"]];
			//				[b setTitle:@"+"];
			[b setTitle:@""];
			[b setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
			break;
		case NSWindowToolbarButton:
			b=[[_NSThemeWidget alloc] initWithFrame:NSMakeRect(0.0, 0.125*button, 1.25*button, 0.75*button) forStyleMask:aStyle];	// we must adjust the origin when using this button!
			[b setAction:@selector(toggleToolbarShown:)];
			[b setEnabled:YES];
			[b setBordered:YES];	// with bezel
			[b setBezelStyle:NSRoundedBezelStyle];
			//				[b setImage:[NSImage imageNamed:@"NSWindowToolbarButton"]];
			//				[b setTitle:@"t"];
			[b setTitle:@""];
			[b setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
			break;
		case NSWindowDocumentIconButton:
			b=[[NSThemeDocumentButton alloc] initWithFrame:NSMakeRect(2.0+3.0*button, 0.0, 100.0, button) forStyleMask:aStyle];	// we must adjust the width when using this button!
			[b setEnabled:NO];
			// somehow include us in handling move by clicking into the title bar except for D&D on the icon
			[b setImagePosition:NSImageLeft];
			[[b cell] setImageDimsWhenDisabled:NO];
			//				[b setImage:[NSImage imageNamed:@"NSWindowZoomButton"]];	// FIXME: image alignment and text alignment do not work correctly for NSButtonCells
			[b setTitle:@""];
			// [b setTitle:@"notitle"];
			[b setAlignment:NSCenterTextAlignment];
			[[b cell] setLineBreakMode:NSLineBreakByTruncatingTail];
			[b setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];
			break;
	}
	if(aStyle & NSUtilityWindowMask)
		{
		NSImage *i=[[b image] copy];
		if(i)
			{
			// [b setFrameSize:small];
			[i setSize:smallImage];	// scale copy of button image
			[i setScalesWhenResized:YES];
			[b setImage:i];	// store a copy
			[i release];
			[b setNeedsDisplay:YES];
			}
		}
	return [b autorelease];
}

- (float) userSpaceScaleFactor;
{ // value defined in NSScreen profile
	return [_screen userSpaceScaleFactor];
}

- (void) setShowsResizeIndicator:(BOOL) flag;
{
	[(NSThemeFrame *) _themeFrame setShowsResizeIndicator:flag];
}

- (void) setShowsToolbarButton:(BOOL) flag;
{
	[(NSThemeFrame *) _themeFrame setShowsToolbarButton:flag];
}

- (BOOL) showsResizeIndicator;
{
	return [(NSThemeFrame *) _themeFrame showsResizeIndicator];
}

- (BOOL) showsToolbarButton;
{
	return [(NSThemeFrame *) _themeFrame showsToolbarButton];
}

- (NSButton *) standardWindowButton:(NSWindowButton) button;
{
	return [(NSThemeFrame *) _themeFrame standardWindowButton:button];
}

- (void) enableKeyEquivalentForDefaultButtonCell
{
	[_defaultButtonCell setKeyEquivalent:@"\r"];
}

- (void) disableKeyEquivalentForDefaultButtonCell
{
	[_defaultButtonCell setKeyEquivalent:@""];
}

- (void) setDefaultButtonCell:(NSButtonCell *) cell
{
	_defaultButtonCell=cell;
	[self enableKeyEquivalentForDefaultButtonCell];
}

- (NSButtonCell *) defaultButtonCell; { return _defaultButtonCell; }

- (NSPoint) mouseLocationOutsideOfEventStream
{ // ask backend for relative mouse position (might be outside of the Window!)
	NSPoint pnt=[NSEvent mouseLocation];
	pnt.y-=1.0;
	return [self convertScreenToBase:pnt];
}

+ (void) menuChanged:(NSMenu *)aMenu; { return; } // does nothing for backward compatibility

- (void) invalidateShadow;
{
	[_shadow release];
	_shadow=nil;
}

- (BOOL) hasShadow { return _w.hasShadow; }

- (void) setHasShadow:(BOOL) flag
{
	if(flag != _w.hasShadow)
		{
		_w.hasShadow=flag;
		[self invalidateShadow];
		}
}

- (BOOL) ignoresMouseEvents { return _w.ignoresMouseEvents; }

- (void) setIgnoresMouseEvents:(BOOL) flag
{
	_w.ignoresMouseEvents=flag;
	// we must notify the backend (?)...
}

- (void) cacheImageInRect:(NSRect) rect;
{
	[self discardCachedImage];
	_cachedRep=[[NSCachedImageRep alloc] initWithWindow:nil rect:rect];	// create a new caching window
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:(NSBitmapImageRep *)_cachedRep]];
	NSCopyBits(_gState, rect, NSZeroPoint);	// copy from our window to the cached window
	[NSGraphicsContext restoreGraphicsState];
}

- (void) discardCachedImage;
{
	[_cachedRep release];
	_cachedRep=nil;
}

- (void) restoreCachedImage;
{
	[_cachedRep draw];
}

- (void) setAlphaValue:(float) alpha;
{
	if(alpha != 1.0)
		_w.isOpaque=NO;
	//
}

- (float) alphaValue;
{
	return 1.0;
}

- (void) setOpaque:(BOOL) flag; { _w.isOpaque=flag; }
- (BOOL) isOpaque; { return _w.isOpaque; }

// horizontal menu within the window frame (above the toolbar)

- (void) setMenu:(NSMenu *) menu { [(NSThemeFrame *) _themeFrame setMenu:menu]; }
- (NSMenu *) menu; { return [(NSThemeFrame *) _themeFrame menu]; }

- (void) setToolbar:(NSToolbar *) toolbar;
{
	[(NSThemeFrame *) _themeFrame setToolbar:toolbar];
	[(NSThemeFrame *) _themeFrame setShowsToolbarButton:(toolbar != nil)];
}

- (NSToolbar *) toolbar; { return [(NSThemeFrame *) _themeFrame toolbar]; }

- (void) toggleToolbarShown:(id) sender
{
	NSToolbarView *tv=[(NSThemeFrame *) _themeFrame toolbarView];
	if([tv popUpMode])
		[tv popUpOverflowMenu:(id) sender];
	else
		{
		NSToolbar *tb=[tv toolbar];
		if(tb)
			[tb setVisible:![tb isVisible]];	// toggle visibility
		}
}

- (void) runToolbarCustomizationPalette:(id)sender
{
	[[(NSThemeFrame *) _themeFrame toolbar] runCustomizationPalette:sender];
}

- (void) _attachSheet:(NSWindow *) sheet
{
	_attachedSheet=sheet;
}

- (NSWindow *) attachedSheet;
{
	return _attachedSheet;
}

- (void) _becomeSheet;
{
	_w.isSheet=YES;
}

- (BOOL) isSheet;
{
	return _w.isSheet;
}

- (void) addChildWindow:(NSWindow *) child ordered:(NSWindowOrderingMode) place;
{
	if(!_childWindows)
		_childWindows=[[NSMutableArray alloc] initWithCapacity:3];
	// FIXME: do we need two separate lists?
	// ordering of windows should reorder the parent/child
	// movements will only move children
	[_childWindows addObject:child];
	[child setParentWindow:self];
}

- (NSArray *) childWindows;
{
	if(!_childWindows)
		return [NSArray array];
	return _childWindows;
}

- (void) removeChildWindow:(NSWindow *) child;
{
	[child setParentWindow:nil];
	[_childWindows removeObject:child];
}

- (NSWindow *) parentWindow;
{
	return _parentWindow;
}

- (void) setParentWindow:(NSWindow *) window;
{
	_parentWindow=window;
}

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{ // if there is no controller to handle that
	NSString *action=NSStringFromSelector([menuItem action]);
	if([action isEqualToString:@"runToolbarCustomizationPalette:"])
		return [[self toolbar] allowsUserCustomization];
	if([action isEqualToString:@"toggleToolbarShown:"])
		return [self toolbar] != nil;	// only if we have a toolbar
	if([action isEqualToString:@"performClose:"] || [action isEqualToString:@"close:"])
		return (_w.styleMask&NSClosableWindowMask) != 0;
	if([action isEqualToString:@"performMiniaturize:"] || [action isEqualToString:@"miniaturize:"])
		return (_w.styleMask&NSMiniaturizableWindowMask) != 0;
	if([action isEqualToString:@"performZoom:"] || [action isEqualToString:@"zoom:"])
		return (_w.styleMask&NSResizableWindowMask) != 0;
	return YES;	// default
}

@end /* NSWindow */

@implementation NSObject (NSWindowDelegate)

- (BOOL) window:(NSWindow *) sender shouldDragDocumentWithEvent:(NSEvent *) evt from:(NSPoint) pt withPasteboard:(NSPasteboard *) pboard; { return YES; }
- (BOOL) window:(NSWindow *) sender shouldPopUpDocumentPathMenu:(NSMenu *) menu; { return YES; }
- (NSRect) window:(NSWindow *) sender willPositionSheet:(NSWindow *) sheet usingRect:(NSRect) rect; { return rect; }
- (BOOL) windowShouldClose:(id) sender; { return YES; }
- (BOOL) windowShouldZoom:(NSWindow *) sender toFrame:(NSRect) frame; { return YES; }
- (NSSize) windowWillResize:(NSWindow *) sender toSize:(NSSize) size; { return size; }
- (id) windowWillReturnFieldEditor:(NSWindow *) sender toObject:(id) object; { return nil; }
- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow *) sender; { return nil; }
- (NSRect) windowWillUseStandardFrame:(NSWindow *) sender defaultFrame:(NSRect) frame; { return frame; }

@end
