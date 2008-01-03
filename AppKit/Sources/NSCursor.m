/* 
   NSCursor.m

   mySTEP Cursor class

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSImage.h>

#import "NSAppKitPrivate.h"
#import "NSBackendPrivate.h"

// Class variables

static NSMutableArray *__cursorStack = nil;
static BOOL __cursorIsHiddenUntilMouseMoved = YES;

static NSCursor *__blankCursor, *__hiddenCursor, *__currentCursor;

#define CURSOR(name) \
{ \
	static NSCursor *c; \
	if(!c) \
		NSLog(@"load cursor %@", name); \
		c=[[NSCursor alloc] initWithImage:[NSImage imageNamed:name] \
								  hotSpot:(NSPoint){8,8}]; \
	return c; \
}


@implementation NSCursor

+ (void) initialize
{
	__cursorStack = [[NSMutableArray alloc] initWithCapacity: 2];
}

+ (void) setHiddenUntilMouseMoves:(BOOL)flag
{
	__cursorIsHiddenUntilMouseMoved = flag;
}

+ (void) pop
{
	int cursorStackCount = [__cursorStack count];
													// stack is now empty so
	if(cursorStackCount == 1)						// cursor remains unchanged
		[[__cursorStack lastObject] set];
	else if (cursorStackCount > 1)					// If stack isn't empty get
		{										// a new current cursor
		[__cursorStack removeLastObject];
		[[__cursorStack lastObject] set];				
		}
}													
													// blank cursor must exist
+ (void) unhide										// and be current cursor in
{													// order to unhide
	if(!__blankCursor || __currentCursor != __blankCursor)								
		return;
	[__hiddenCursor set];							// Revert to current cursor
}

+ (void) hide
{
	if(__currentCursor == __blankCursor)			// If the cursor is already hidden then do nothing 
		return;
	__hiddenCursor = __currentCursor;				// Save the current cursor
	if(!__blankCursor)
		__blankCursor=[[self alloc] initWithImage:nil hotSpot:NSZeroPoint];	// will create a "None" cursor
	[__blankCursor set];							// and set the blank cursor
	__currentCursor = __blankCursor;
}

+ (NSCursor *) arrowCursor; { CURSOR(@"GSArrowCursor"); }	
+ (NSCursor *) closedHandCursor; { CURSOR(@"GSClosedHandCursor"); }	
+ (NSCursor *) crosshairCursor; { CURSOR(@"GSCrosshairCursor"); }	
+ (NSCursor *) disappearingItemCursor; { CURSOR(@"GSDisappearingItemCursor"); }	
+ (NSCursor *) IBeamCursor; { CURSOR(@"iBeamCursor"); }				// Create standard I beam
+ (NSCursor *) openHandCursor; { CURSOR(@"GSOpenHandCursor"); }	
+ (NSCursor *) pointingHandCursor; { CURSOR(@"GSPointingHandCursor"); }	
+ (NSCursor *) resizeDownCursor; { CURSOR(@"GSResizeDownCursor"); }	
+ (NSCursor *) resizeLeftCursor; { CURSOR(@"GSResizeLeftCursor"); }	
+ (NSCursor *) resizeLeftRightCursor; { CURSOR(@"GSResizeCursor"); }
+ (NSCursor *) resizeRightCursor; { CURSOR(@"GSResizeRightCursor"); }	
+ (NSCursor *) resizeUpCursor; { CURSOR(@"GSResizeUpCursor"); }	
+ (NSCursor *) resizeUpDownCursor; { CURSOR(@"GSResizeUpDownCursor"); }

+ (NSCursor *) _copyCursor; { CURSOR(@"GSCopyCursor"); }				// mySTEP extension
+ (NSCursor *) _linkCursor; { CURSOR(@"GSLinkCursor"); }				// mySTEP extension

+ (NSCursor *) currentCursor		{ return __currentCursor; }
+ (BOOL) isHiddenUntilMouseMoves	{ return __cursorIsHiddenUntilMouseMoved; }

- (id) initWithImage:(NSImage *) image
 foregroundColorHint:(NSColor *) fg
 backgroundColorHint:(NSColor *) bg
			 hotSpot:(NSPoint) spot;
{
	NSAssert(image, @"image for NSCursor");
	if((self=[super init]))
		{
		_image=[image retain];	// nil image will create a "None" cursor
		_hotSpot=spot;
		}
	return self;
}

- (id) initWithImage:(NSImage *) image
			 hotSpot:(NSPoint) spot;
{
	return [self initWithImage:image foregroundColorHint:nil backgroundColorHint:nil hotSpot:spot];
}

- (void) dealloc;
{
	[_image release];
	[super dealloc];
}

- (void) mouseEntered:(NSEvent *)event
{
	if (_isSetOnMouseEntered)
		[self set];
}

- (void) mouseExited:(NSEvent *)event
{
	if (_isSetOnMouseExited)
		[self set];
}

- (void) push
{
	[__cursorStack addObject: self];
	[self set];
}

- (NSImage *) image							{ return _image; }
- (NSPoint) hotSpot							{ return _hotSpot; }
- (void) setOnMouseEntered:(BOOL)flag		{ _isSetOnMouseEntered = flag;}
- (void) setOnMouseExited:(BOOL)flag		{ _isSetOnMouseExited = flag; }
- (void) pop								{ [isa pop]; }
- (void) set								{ BACKEND; }
- (BOOL) isSetOnMouseEntered				{ return _isSetOnMouseEntered;}
- (BOOL) isSetOnMouseExited					{ return _isSetOnMouseExited; }

- (void) encodeWithCoder:(id)aCoder						// NSCoding protocol
{
	NIMP;
}

- (id) initWithCoder:(id)aDecoder
{
	int type = [aDecoder decodeIntForKey:@"NSCursorType"];
	NSCursor *c=nil;
#if 0
	NSLog(@"%@ initWithCoder:%@ type=%d", NSStringFromClass([self class]), aDecoder, type);
#endif
	switch(type)
		{
		default:
		case 1:	c=[isa arrowCursor]; break;
		case 2:	c=[isa IBeamCursor]; break;
		case 3:	c=[isa crosshairCursor]; break;
		case 4:	c=[isa closedHandCursor]; break;
		case 5:	c=[isa openHandCursor]; break;
		case 6:	c=[isa pointingHandCursor]; break;
		case 7: c=[isa resizeLeftCursor]; break;
		case 8: c=[isa resizeRightCursor]; break;
		case 9: c=[isa resizeLeftRightCursor]; break;
		case 10: c=[isa resizeUpCursor]; break;
		case 11: c=[isa resizeDownCursor]; break;
		case 12: c=[isa resizeUpDownCursor]; break;
		case 13: c=[isa disappearingItemCursor]; break;
		}
	if(!c)
		{
		NSLog(@"unknown cursor type %d", type);
		c=[isa IBeamCursor];
		}
	[c retain];
	[self autorelease];
	c->_hotSpot=[aDecoder decodePointForKey:@"NSHotSpot"];
	return c;
}

@end /* NSCursor */