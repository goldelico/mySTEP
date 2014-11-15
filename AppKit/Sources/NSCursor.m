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
		[(NSCursor *)[__cursorStack lastObject] set];
	else if (cursorStackCount > 1)					// If stack isn't empty get
		{										// a new current cursor
		[__cursorStack removeLastObject];
		[(NSCursor *)[__cursorStack lastObject] set];
		}
}													
													// blank cursor must exist
#define CURSOR(name, x, y) \
{ \
static NSCursor *c; \
if(!c) \
c=[[NSCursor alloc] initWithImage:[NSImage imageNamed:name] hotSpot:(NSPoint){x, y}]; \
return c; \
}

+ (NSCursor *) arrowCursor; { CURSOR(@"GSArrowCursor", 3, -2); }	
+ (NSCursor *) closedHandCursor; { CURSOR(@"GSClosedHandCursor", 8, -8); }	
+ (NSCursor *) crosshairCursor; { CURSOR(@"GSCrosshairCursor", 8, -8); }	
+ (NSCursor *) disappearingItemCursor; { CURSOR(@"GSDisappearingItemCursor", 8, -8); }	
+ (NSCursor *) IBeamCursor; { CURSOR(@"GSIBeamCursor", 8, -8); }				// Create standard I beam
+ (NSCursor *) openHandCursor; { CURSOR(@"GSOpenHandCursor", 8, -8); }	
+ (NSCursor *) pointingHandCursor; { CURSOR(@"GSPointingHandCursor", 8, -8); }	
+ (NSCursor *) resizeDownCursor; { CURSOR(@"GSResizeDownCursor", 8, -8); }	
+ (NSCursor *) resizeLeftCursor; { CURSOR(@"GSResizeLeftCursor", 8, -8); }	
+ (NSCursor *) resizeLeftRightCursor; { CURSOR(@"GSResizeCursor", 8, -8); }
+ (NSCursor *) resizeRightCursor; { CURSOR(@"GSResizeRightCursor", 8, -8); }	
+ (NSCursor *) resizeUpCursor; { CURSOR(@"GSResizeUpCursor", 8, -8); }	
+ (NSCursor *) resizeUpDownCursor; { CURSOR(@"GSResizeUpDownCursor", 8, -8); }

+ (NSCursor *) _copyCursor; { CURSOR(@"GSCopyCursor", 8, -8); }				// mySTEP extension
+ (NSCursor *) _linkCursor; { CURSOR(@"GSLinkCursor", 8, -8); }				// mySTEP extension
+ (NSCursor *) _hiddenCursor; { CURSOR(@"GSHiddenCursor", 8, -8); }		// mySTEP extension

+ (NSCursor *) currentCursor		{ return __currentCursor; }
+ (BOOL) isHiddenUntilMouseMoves	{ return __cursorIsHiddenUntilMouseMoved; }

+ (void) hide
{
	if(__currentCursor == __blankCursor)			// If the cursor is already hidden then do nothing 
		return;
	__hiddenCursor = __currentCursor;				// Save the current cursor
	if(!__blankCursor)
		__blankCursor=[self _hiddenCursor];
	[__blankCursor set];							// and set the blank cursor
	__currentCursor = __blankCursor;
}

+ (void) unhide										// and be current cursor in
{													// order to unhide
	if(!__blankCursor || __currentCursor != __blankCursor)								
		return;
	[__hiddenCursor set];							// Revert to current cursor
}

- (id) initWithImage:(NSImage *) image
 foregroundColorHint:(NSColor *) fg
 backgroundColorHint:(NSColor *) bg
			 hotSpot:(NSPoint) spot;	// y axis is negative
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

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@: %@ - %@", NSStringFromClass([self class]), _image, NSStringFromPoint(_hotSpot)];
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
- (void) pop								{ [[self class] pop]; }
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
#if 1
	NSLog(@"%@ initWithCoder:%@ type=%d", NSStringFromClass([self class]), aDecoder, type);
#endif
	switch(type)
		{
				// FIXME: can we check the list of cursor types?
				// it appears from analyzing NIBs that cursor #13 should be the pointingHandCursor
		default:
		case 1:	c=[[self class] arrowCursor]; break;
		case 2:	c=[[self class] IBeamCursor]; break;
		case 3:	c=[[self class] crosshairCursor]; break;
		case 4:	c=[[self class] closedHandCursor]; break;
		case 5:	c=[[self class] openHandCursor]; break;
		case 6:	c=[[self class] pointingHandCursor]; break;
		case 7: c=[[self class] resizeLeftCursor]; break;
		case 8: c=[[self class] resizeRightCursor]; break;
		case 9: c=[[self class] resizeLeftRightCursor]; break;
		case 10: c=[[self class] resizeUpCursor]; break;
		case 11: c=[[self class] resizeDownCursor]; break;
		case 12: c=[[self class] resizeUpDownCursor]; break;
		case 13: c=[[self class] disappearingItemCursor]; break;
		}
	if(!c)
		{
		NSLog(@"unknown cursor type %d", type);
		c=[[self class] IBeamCursor];
		}
	[c retain];	// should copy or we overwrite the original NSHotSpot of the cached cursor singleton!
	[self autorelease];
#if 1
	NSLog(@"cursor = %@", c);
	NSLog(@"hotSpot from NIB: %@", [aDecoder decodeObjectForKey:@"NSHotSpot"]);
#endif
//	c->_hotSpot=[aDecoder decodePointForKey:@"NSHotSpot"];	// don't read from NIB unless we create a copy
	return c;
}

@end /* NSCursor */
