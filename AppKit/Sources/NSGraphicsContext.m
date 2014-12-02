/** <title>NSGraphicsContext</title>

	<abstract>GNUstep drawing context class.</abstract>

	Copyright (C) 1998 Free Software Foundation, Inc.

	Written by: Adam Fedor <fedor@gnu.org>
	Date: Nov 1998
	Updated by: Richard Frith-Macdonald <richard@brainstorm.co.uk>
	Date: Feb 1999

	Reworked heavily by Dr. H. Nikolaus Schaller
	Date: Feb 2006

	This file is part of the mySTEP AppKit Library.

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Library General Public
	License as published by the Free Software Foundation; either
	version 2 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Library General Public License for more details.

	You should have received a copy of the GNU Library General Public
	License along with this library; if not, write to the Free
	Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/


#import <Foundation/NSGeometry.h> 
#import <Foundation/NSString.h> 
#import <Foundation/NSArray.h> 
#import <Foundation/NSValue.h> 
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSData.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSZone.h>
#import <Foundation/NSObjCRuntime.h>

#import "AppKit/NSGraphicsContext.h"
#import "AppKit/NSAffineTransform.h"
#import "AppKit/NSBezierPath.h"
#import "AppKit/NSWindow.h"
#import "AppKit/NSView.h"

#import "NSAppKitPrivate.h"
#import "NSBackendPrivate.h"

#include <sys/types.h>
#include <unistd.h>

@implementation NSObject (Backend)

// we should use the MacOS X version...
#ifndef object_is_instance
#define object_is_instance(A) YES
#endif

- (id) _backendResponsibility:(SEL)aSel
{
	[NSException raise:@"NSAppKit" format:@"*** %@[%@ %@]: should be implemented in Backend", object_is_instance(self)?@"-":@"+", NSStringFromClass([self class]), NSStringFromSelector(aSel)];
	return nil;
}
@end

static NSRecursiveLock  *contextLock = nil;	/* Lock for use when creating contexts */

static NSString	*NSGraphicsContextThreadKey = @"NSGraphicsContextThreadKey";
static NSString	*NSGraphicsContextStackKey = @"NSGraphicsContextStackKey";

NSString *NSGraphicsContextDestinationAttributeName=@"NSGraphicsContextDestinationAttributeName";
NSString *NSGraphicsContextRepresentationFormatAttributeName=@"NSGraphicsContextRepresentationFormatAttributeName";

NSString *NSGraphicsContextPDFFormat=@"pdf";
NSString *NSGraphicsContextPSFormat=@"ps";

static NSMapTable *_gState2struct;		// map unique ID to gStates

static NSUInteger disableCount;	// NSDisableScreenUpdates() - not implemented!

NSGraphicsContext *GSCurrentContext(void)
{ // Function for rapid access to current graphics context
#ifdef GNUSTEP_BASE_LIBRARY
	/*
	 *	gstep-base has a faster mechanism to get the current thread.
	 */
	NSThread *th = GSCurrentThread();
	
	return (NSGraphicsContext*) th->_gcontext;
#else
	NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
#if 0
	NSLog(@"GSCurrentContext = %@", [dict objectForKey:NSGraphicsContextThreadKey]);
#endif
	return (NSGraphicsContext *) [dict objectForKey:NSGraphicsContextThreadKey];
#endif
}


@implementation NSGraphicsContext 

+ (void) initialize
{
	contextLock = [NSRecursiveLock new];	// where should we use that?
	_gState2struct = NSCreateMapTable(NSIntMapKeyCallBacks,
								  NSNonOwnedPointerMapValueCallBacks, 20);
}

+ (void) setCurrentContext:(NSGraphicsContext *) context
{
#ifdef GNUSTEP_BASE_LIBRARY
	/*
	 *	gstep-base has a faster mechanism to get the current thread.
	 */
	NSThread *th = GSCurrentThread();
	ASSIGN(th->_gcontext, context);
#else
	NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
	if(!context)
		[dict removeObjectForKey:NSGraphicsContextThreadKey];
	else
		[dict setObject:context forKey:NSGraphicsContextThreadKey];
#endif
}

+ (NSGraphicsContext *) currentContext
{
	return GSCurrentContext();
}

+ (BOOL) currentContextDrawingToScreen
{
	return [GSCurrentContext() isDrawingToScreen];
}

+ (NSGraphicsContext *) graphicsContextWithAttributes:(NSDictionary *) attr;
{
	return [[[self alloc] _initWithAttributes:attr] autorelease];
}

+ (NSGraphicsContext *) graphicsContextWithBitmapImageRep:(NSBitmapImageRep *) bitmap;
{
	return [self graphicsContextWithAttributes:
		[NSDictionary dictionaryWithObject:bitmap forKey:NSGraphicsContextDestinationAttributeName]];
}

+ (NSGraphicsContext *) graphicsContextWithWindow:(NSWindow *) window
{
	return BACKEND;
}

+ (NSGraphicsContext *) graphicsContextWithGraphicsPort:(void *) port flipped:(BOOL) flipped;
{
	return BACKEND;
}

+ (void) restoreGraphicsState
{
	NSGraphicsContext *ctxt;
	NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
	NSMutableArray *stack = [dict objectForKey:NSGraphicsContextStackKey];
	if(stack == nil)
		[NSException raise: NSGenericException format: @"+restoreGraphicsState without previous save"];
	ctxt = [stack lastObject];	// might be nil, i.e. no current context
	[NSGraphicsContext setCurrentContext:ctxt];
	if(ctxt)
		{
		[stack removeLastObject];
		[ctxt restoreGraphicsState];
		}
}

+ (void) saveGraphicsState
{
	// FIXME: this is not consistent with the Apple doc which says that this method simply saves the state of the current context
	NSGraphicsContext *ctxt;
	NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
	NSMutableArray *stack = [dict objectForKey:NSGraphicsContextStackKey];
	if(stack == nil)
		{ // create stack
		stack=[NSMutableArray arrayWithCapacity:10];
		[dict setObject:stack forKey:NSGraphicsContextStackKey];
		}
	ctxt = GSCurrentContext();
	if(ctxt)
		{ // if we have a current context, save it
		[ctxt saveGraphicsState];
		[stack addObject:ctxt];
		}
}

+ (void) setGraphicsState:(int) graphicsState
{ // make context the current and reset graphics state
	_NSGraphicsState *state=NSMapGet(_gState2struct, (void *) graphicsState);
	if(!state)
		[NSException raise:NSGenericException format: @"setGraphicsState: invalid graphics state %d", graphicsState];
#if 0
	NSLog(@"setGraphicsState:%d", graphicsState);
#endif
	[self setCurrentContext:state->_context];	// select the associated context as current
}

- (void) dealloc
{
	while(_graphicsState)
		[self restoreGraphicsState];	// release graphics state stack
	[(NSMutableArray *) _focusStack release];
	[super dealloc];
}

- (id) init;
{
	if((self=[super init]))
		{
		_compositingOperation = NSCompositeCopy;
		}
	return self;
}


- (id) _initWithAttributes:(NSDictionary *) attributes;
{
	if((self=[super init]))
		{
		_compositingOperation = NSCompositeCopy;
		// ignore attributes
		}
	return self;
}

- (void) flushGraphics { BACKEND; }
- (BOOL) isDrawingToScreen { BACKEND; return YES; }	// default

- (void) restoreGraphicsState
{ // Backend may override - must call [super restoreGraphicsState] to include default operation
	_NSGraphicsState *tos=(_NSGraphicsState *) _graphicsState;	// current
#if 0
	NSLog(@"restoreGraphicsState: %d", [self _currentGState]); 
#endif
	if(!tos)
		[NSException raise: NSGenericException format: @"-restoreGraphicsState without previous -saveGraphicsState"];
	NSMapRemove(_gState2struct, (void *)(tos->_gState));		// remove from mapping
	_graphicsState=tos->_nextOnStack;	// pop from stack
	objc_free(tos);	// and release
}

- (void) saveGraphicsState
{ // Backend may override - but must call [super saveGraphicsState] for default operation
	static int gState;
	// might need to be locked
	_NSGraphicsState *new;
#if 0
	NSLog(@"saveGraphicsState: %d", gState+1); 
#endif
	new=[self _copyGraphicsState:(_NSGraphicsState *) _graphicsState];
	new->_gState=++gState;	// assign unique gState number
	NSMapInsert(_gState2struct, (void *)(new->_gState), new);	// allow for associative mapping
	new->_context=self;
	new->_nextOnStack=_graphicsState;	// push on stack
	_graphicsState=new;	// and make current
	// unlock
}

- (_NSGraphicsState *) _copyGraphicsState:(_NSGraphicsState *) state;
{ // Backend can override to provide extended data object
	return (_NSGraphicsState *) objc_calloc(1, sizeof(*state));	// we have no private data to copy
}

- (int) _currentGState;
{ // current top of stack gState
	if(_graphicsState)
		return ((_NSGraphicsState *) _graphicsState)->_gState;
	return -1;	// none
}

- (NSDictionary *) attributes { return nil; }
- (void *) focusStack { return _focusStack; }
- (void *) graphicsPort { return _graphicsPort; }

- (BOOL) isFlipped
{
	NSView *focusView=[(NSArray *) _focusStack lastObject];
	if(focusView)
		return [focusView isFlipped];	// ask view
	return _isFlipped;	// return default value
}

- (void) setFocusStack: (void *)stack { _focusStack=stack; }

// CHECKME: shouldn't that be fetched from current gState?
- (NSCompositingOperation) compositingOperation; { return _compositingOperation; }
- (NSImageInterpolation) imageInterpolation; { return _imageInterpolation; }
- (NSPoint) patternPhase; { return _patternPhase; }	// SUBCLASS may override
- (BOOL) shouldAntialias; { return _shouldAntialias; }

// should be changed by the backend
- (void) setCompositingOperation:(NSCompositingOperation) operation; { _compositingOperation=operation; }
- (void) setImageInterpolation:(NSImageInterpolation) inter; { _imageInterpolation=inter; }	// SUBCLASS may override
- (void) setPatternPhase:(NSPoint) phase; { _patternPhase=phase; }	// SUBCLASS may override
- (void) setShouldAntialias:(BOOL) flag; { _shouldAntialias=flag; }	// SUBCLASS may override

@end

#if 0	// already defined in Externs.m

NSString *NSCalibratedWhiteColorSpace;			// Colorspace Names
NSString *NSCalibratedBlackColorSpace;
NSString *NSCalibratedRGBColorSpace;
NSString *NSDeviceWhiteColorSpace;
NSString *NSDeviceBlackColorSpace;
NSString *NSDeviceRGBColorSpace;
NSString *NSDeviceCMYKColorSpace;
NSString *NSNamedColorSpace;
NSString *NSPatternImageColorSpace;
NSString *NSCustomColorSpace;

NSString *NSDeviceResolution;					// Device Dict Keys
NSString *NSDeviceColorSpaceName;
NSString *NSDeviceBitsPerSample;
NSString *NSDeviceIsScreen;
NSString *NSDeviceIsPrinter;
NSString *NSDeviceSize;

#endif

// Functions (alphabetically sorted)

void NSBeep(void)
{ // Play System Beep
	NSLog(@"beeeeep.....");
  // NIMP
	// could call [NSScreen _beep] -> XBell(_display, 100);
	// [GSCurrentServer() beep];
}

NSWindowDepth NSBestDepth(NSString *colorSpace, 
						  int bitsPerSample,
						  int bitsPerPixel, 
						  BOOL planar,
						  BOOL *exactMatch)
{
	// NIMP
	return 0;
}

NSInteger NSBitsPerPixelFromDepth(NSWindowDepth depth)
{
	return (depth&63);	// 0..63
}

NSInteger NSBitsPerSampleFromDepth(NSWindowDepth depth)
{
	return ((depth>>6)&15);	// 0..15
}

NSString *NSColorSpaceFromDepth(NSWindowDepth depth)
{
	NSColorSpace *csp=[[[NSColorSpace alloc] _initWithColorSpaceModel:(depth>>11)&15] autorelease];
	return [csp localizedName];
}

void NSCopyBits(NSInteger srcGstate, NSRect srcRect, NSPoint destPoint)
{
	_NSGraphicsState *state;
	NSGraphicsContext *ctxt=[NSGraphicsContext currentContext];
	if(!srcGstate)
		state=(_NSGraphicsState *) (ctxt->_graphicsState);	// current
	else
		{
		state=NSMapGet(_gState2struct, (void *) srcGstate);
		if(!state)
			[NSException raise:NSGenericException format:@"NSCopyBits: invalid source graphics state %d", srcGstate];
		}
	// FIXME: should we save/restore the compositing operation?
	[ctxt setCompositingOperation:NSCompositeCopy];
	[ctxt _copyBits:state fromRect:srcRect toPoint:destPoint];
}

void NSCountWindows(NSInteger *count)
{
	return NSCountWindowsForContext(0, count);
}

void NSCountWindowsForContext(NSInteger context, NSInteger *count)
{ // for a specific application
	*count=[NSScreen _systemWindowListForContext:context size:999999 list:NULL];
}

void NSDisableScreenUpdates(void)
{
	disableCount++;
}

void NSDrawBitmap(NSRect rect,							// Bitmap Images
                  NSInteger pixelsWide,
                  NSInteger pixelsHigh,
                  NSInteger bitsPerSample,
                  NSInteger samplesPerPixel,
                  NSInteger bitsPerPixel,
                  NSInteger bytesPerRow,
                  BOOL isPlanar,
                  BOOL hasAlpha, 
                  NSString *colorSpaceName, 
                  const unsigned char *const data[5])
{
	NSBitmapImageRep *bitmap=[[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:(unsigned char **)data
					  pixelsWide:pixelsWide
					  pixelsHigh:pixelsHigh
				   bitsPerSample:bitsPerSample
				 samplesPerPixel:samplesPerPixel
						hasAlpha:hasAlpha
						isPlanar:isPlanar
				  colorSpaceName:colorSpaceName
					 bytesPerRow:bytesPerRow
					bitsPerPixel:bitsPerPixel];	// create a temporary bitmap with given data
	[bitmap drawInRect:rect];
	[bitmap release];
}

void NSDrawButton(NSRect aRect, NSRect clipRect)
{
	CGFloat grays[] = { NSBlack, NSBlack, NSWhite, NSWhite, NSDarkGray, NSDarkGray };
	NSRect rect = NSDrawTiledRects(aRect, clipRect, BUTTON_EDGES_NORMAL, grays, 6);
	[[NSColor lightGrayColor] set];
	NSRectFill(rect);
}

NSRect NSDrawColorTiledRects( NSRect boundsRect,
							  NSRect clipRect,
							  const NSRectEdge *sides,
							  NSColor **colors,
							  NSInteger count)
{
	NSRect slice, remainder = boundsRect;
	NSRect rects[count];
	NSInteger i;
	if(!NSIntersectsRect(boundsRect, clipRect))
		return NSZeroRect;
	for(i = 0; i < count; i++)
		{
		NSDivideRect(remainder, &slice, &remainder, 1.0, sides[i]);
		rects[i] = NSIntersectionRect(slice, clipRect);
		}
	NSRectFillListWithColors(rects, colors, count);
	return remainder;
}

void NSDrawGrayBezel(NSRect aRect, NSRect clipRect)
{
	CGFloat grays[] = { NSWhite, NSWhite, NSDarkGray, NSDarkGray,
					  NSLightGray, NSLightGray, NSBlack, NSBlack };
	NSRect rect;
	rect = NSDrawTiledRects(aRect, clipRect, BEZEL_EDGES_NORMAL, grays, 8);
	[[NSColor darkGrayColor] set];
	NSRectFill(NSMakeRect(NSMinX(aRect) + 1., NSMinY(aRect) + 1., 1., 1.));
	[[NSColor lightGrayColor] set];
	NSRectFill(rect);
}

void NSDrawGroove(NSRect aRect, NSRect clipRect)
{
	NSRectEdge edges[] = { NSMinXEdge, NSMaxYEdge, NSMinXEdge, NSMaxYEdge, 
						   NSMaxXEdge, NSMinYEdge, NSMaxXEdge, NSMinYEdge };
	CGFloat grays[] = { NSDarkGray, NSDarkGray, NSWhite, NSWhite,
					  NSWhite, NSWhite, NSDarkGray, NSDarkGray };
	NSRect rect = NSDrawTiledRects(aRect, clipRect, edges, grays, 8);
	[[NSColor lightGrayColor] set];
	NSRectFill(rect);
}

NSRect
NSDrawTiledRects( NSRect boundsRect,
				  NSRect clipRect,
				  const NSRectEdge *sides,
				  const CGFloat *grays,
				  NSInteger count)
{
	NSRect slice, remainder = boundsRect;
	NSRect rects[count];	// FIXME - stack overflow!!!
	NSInteger i;
	if (!NSIntersectsRect(boundsRect, clipRect))
		return NSZeroRect;
	for (i = 0; i < count; i++)
		{
		NSDivideRect(remainder, &slice, &remainder, 1.0, sides[i]);
		rects[i] = NSIntersectionRect(slice, clipRect);
		}
	NSRectFillListWithGrays(rects, grays, count);	
	return remainder;
}

void NSDrawWhiteBezel(NSRect aRect, NSRect clipRect)
{
	CGFloat grays[] = { NSWhite, NSWhite, NSDarkGray, NSDarkGray,
					  NSLightGray, NSLightGray, NSDarkGray, NSDarkGray };
	NSRect rect = NSDrawTiledRects(aRect, clipRect, BEZEL_EDGES_NORMAL, grays, 8);
	[[NSColor whiteColor] set];
	NSRectFill(rect);
}

void NSDrawWindowBackground(NSRect rect)
{
	[[NSColor windowBackgroundColor] set];	// can be a pattern color...
	NSRectFill(rect);
}

void NSEnableScreenUpdates(void)
{
	if(disableCount > 0)
		disableCount--;
}

void NSEraseRect(NSRect aRect)
{
	NSGraphicsContext *ctx=[NSGraphicsContext currentContext];
	[ctx saveGraphicsState];
	[[NSColor whiteColor] set];
	NSRectFill(aRect);
	[ctx restoreGraphicsState];
}

void NSFrameRect(NSRect aRect)
{
	NSFrameRectWithWidth(aRect, 1.0);
}

void NSFrameRectWithWidth(NSRect aRect, CGFloat frameWidth)
{
	NSRectEdge sides[] = { NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge };
	NSRect remainder = aRect;
	NSRect rects[4];
	int i;
	for(i = 0; i < 4; i++)
		NSDivideRect(remainder, &rects[i], &remainder, frameWidth, sides[i]);	// chop off rects from all sides
	NSRectFillList(rects, 4);
}

void NSFrameRectWithWidthUsingOperation(NSRect r,
										CGFloat w,
										NSCompositingOperation op)
{
	NSGraphicsContext *ctx=[NSGraphicsContext currentContext];
	[ctx saveGraphicsState];
	[ctx setCompositingOperation:op];
	NSFrameRectWithWidth(r, w);
	[ctx restoreGraphicsState];
}

NSInteger NSGetWindowServerMemory(NSInteger context,
							NSInteger *virtualMemory,
							NSInteger *windowBackingMemory,
							NSString **windowDumpStream)
{
	if(!context)
		context=getpid();	// why do we pass integers for contexts?
	// NIMP
	return -1;
}

void NSHighlightRect(NSRect aRect)       
{
	NSRectFillUsingOperation(aRect, NSCompositeHighlight);
}

NSInteger NSNumberOfColorComponents(NSString *colorSpaceName)
{
	return [[NSColorSpace _colorSpaceWithName:colorSpaceName] numberOfColorComponents];
}

BOOL NSPlanarFromDepth(NSWindowDepth depth)
{
	return ((depth>>10)&1) != 0;
}

NSColor *NSReadPixel(NSPoint location)
{ // Read pixel color from current drawable
	return [[NSGraphicsContext currentContext] _readPixel:location];
}

void NSRectClip(NSRect aRect)
{ // intersect with rect
	[NSBezierPath clipRect:aRect];
}

void NSRectClipList(const NSRect *rects, NSInteger count)
{ // intersect with all rects
	NSInteger i;
    for (i = 0; i < count; i++)
		NSRectClip(rects[i]);
}

void NSRectFill(NSRect aRect)
{ // fill rect
	if(NSIsEmptyRect(aRect))
		return;
	[NSBezierPath fillRect:aRect];
}

void NSRectFillList(const NSRect *rects, NSInteger count)
{ // Fill an array of rects with the current color.
	NSInteger i;
    for(i = 0; i < count; i++)
		NSRectFill(rects[i]);
}

void NSRectFillListUsingOperation(const NSRect *rects,
							 NSInteger count,
							 NSCompositingOperation op)
{
	NSInteger i;
	for (i = 0; i < count; i++)
		NSRectFillUsingOperation(rects[i], op);
}

void NSRectFillListWithColorsUsingOperation(const NSRect *rects,
									   NSColor **colors,
									   NSInteger num,
									   NSCompositingOperation op)
{
	NSInteger i;
	for (i = 0; i < num; i++)
		{
		[colors[i] set];
		NSRectFillUsingOperation(rects[i], op);
		}
}

void NSRectFillListWithGrays(const NSRect *rects, const CGFloat *grays, NSInteger count)
{
	NSInteger i;
	for (i = 0; i < count; i++)					// Fills each rectangle in the 
		{										// array rects[] with the gray 
		[[NSColor colorWithCalibratedWhite:grays[i] alpha:1.0] set];
		NSRectFill(rects[i]);					// array grays[].
		}
}

void
NSRectFillListWithColors(const NSRect *rects, NSColor **colors, NSInteger count)
{
	NSInteger i;
	for (i = 0; i < count; i++)
		{
		[colors[i] set];
		NSRectFill(rects[i]);
		}
}

void NSRectFillUsingOperation(NSRect aRect, NSCompositingOperation op)
{
	NSGraphicsContext *ctx=[NSGraphicsContext currentContext];
	NSCompositingOperation co=[ctx compositingOperation];	// save
	[ctx setCompositingOperation:op];
	[NSBezierPath fillRect:aRect];
	[ctx setCompositingOperation:co];	// restore
}

void NSSetFocusRingStyle(NSFocusRingPlacement placement)
{ // callee must save the current context if it sould not be changed permanently
	// FIXME: NIMP
	NSLog(@"*** NSSetFocusRingStyle not implemented ***");
	// what should it do?
	// according to http://lists.apple.com/archives/cocoa-de...t/msg01602.html
	// it should draw the focus ring around the current clipping rect
	// or does it only set the colors and patterns
	// and change the clippingRect so that one can draw around?
	// yes, we can remove clipping if we use [NSBezierPath clipRect:NSMakeRect(0.0, 0.0, 16000.0, 16000.0)];
	// but does it really draw or just set the style?
	// how can it modify 'below/above' ==> [nsaffinetransform concat];
	// can also set fill&stroke colors
	switch(placement)
		{
			case NSFocusRingOnly:
			case NSFocusRingBelow:
			case NSFocusRingAbove:
				break;
		}
}

void NSShowAnimationEffect(NSAnimationEffect animationEffect,
						   NSPoint centerLocation,
						   NSSize size,
						   id animationDelegate,
						   SEL didEndSelector,
						   void *contextInfo)
{
	// FIXME: run animation
	if(animationDelegate)
		[animationDelegate performSelector:didEndSelector withObject:(id)contextInfo];	// notify completion
}

const NSWindowDepth *NSAvailableWindowDepths(void)
{
	return [[NSScreen deepestScreen] supportedWindowDepths];
}

void NSWindowList(NSInteger size, NSInteger list[])
{
	NSWindowListForContext(0, size, list);
}

void NSWindowListForContext(NSInteger context, NSInteger size, NSInteger list[])
{ // for a specific context (application id) - ask BACKEND
	[NSScreen _systemWindowListForContext:context size:size list:list];
}

// EOF