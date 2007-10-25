/* 
   NSButton.m

   Button control and associated button cell class

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>

#import <AppKit/NSButton.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSBezierPath.h>

#import "NSAppKitPrivate.h"

// class variables
id __buttonCellClass = nil;

//*****************************************************************************
//
// 		NSButtonCell 
//
//*****************************************************************************

@implementation NSButtonCell

- (id) init	{ return [self initTextCell:@"Button"]; }

// override

- (id) initTextCell:(NSString *)aString
{
#if 0
	NSLog(@"%@ (NSButtonCell)initTextCell:%@", self, aString);
#endif
	if((self=[super initTextCell:@"0"]))	// aString is not printed but used as the state!
		{
		[self setBordered:YES];		// draw bezel
		[self setShowsFirstResponder:YES];	//default
		[self setTitle:aString];	// replace title default (@"Button")
		_bezelStyle=NSRoundedBezelStyle;	// default style
		[self setButtonType:NSMomentaryPushInButton];
		_backgroundColor=[[NSColor controlColor] retain];	// default color
		_c.drawsBackground=NO;	// but don't draw background (CHECKME)
		_periodicDelay = 0.4;
		_periodicInterval = 0.075;
		}
#if 0
	NSLog(@"%@ initTextCell done", self);
#endif
	return self;
}

- (id) initImageCell:(NSImage *)anImage
{
	if((self=[self initTextCell:nil]))
		{ // no title
		_c.imagePosition = NSImageOnly;
		_normalImage = [anImage retain];
		_mixedImage = [[NSImage imageNamed:@"NSMultiStateSwitch"] retain];
		}
	return self;
}

- (void) dealloc
{
	[_alternateTitle release];
	[_alternateImage release];
	[_normalImage release];
	[_keyEquivalent release];
	[_keyEquivalentFont release];
	
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSButtonCell *c = [super copyWithZone:zone];

	c->_alternateTitle = [_alternateTitle copyWithZone:zone];
	if(_alternateImage)
		c->_alternateImage = [_alternateImage retain];
	if(_normalImage)
		c->_normalImage = [_normalImage retain];
	if(_keyEquivalent)
		{
		c->_keyEquivalent = [_keyEquivalent copyWithZone:zone];
		if(_keyEquivalentFont)
			c->_keyEquivalentFont = [_keyEquivalentFont retain];
		c->_keyEquivalentModifierMask = _keyEquivalentModifierMask;
		}
	c->_highlightMask = _highlightMask;
	c->_stateMask = _stateMask;
	c->_periodicDelay = _periodicDelay;
	c->_periodicInterval = _periodicInterval;
	c->_buttonType = _buttonType;
	c->_bezelStyle = _bezelStyle;
	c->_dimsWhenDisabled = _dimsWhenDisabled;
	c->_transparent = _transparent;
	
	return c;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@\n"
		@"stateMask=%02x\n"
		@"highlightMask=%02x\n" 
		@"buttonType=%d\n" 
		@"bezelStyle=%d\n"
		@"transparent=%d\n"
		@"dimsWhenDisabled=%d\n" 
		@"bgcolor=%@\n", 
		[super description], _stateMask, _highlightMask, _buttonType, _bezelStyle, _transparent, _dimsWhenDisabled, _backgroundColor
		];
}

- (NSColor *) backgroundColor				{ return _backgroundColor; }
- (void) setBackgroundColor:(NSColor *)col	{ ASSIGN(_backgroundColor,col); }
- (NSString *) alternateTitle				{ return _alternateTitle; }
- (void) setAlternateTitle:(NSString *)aStr	{ ASSIGN(_alternateTitle,aStr); }
- (void) setFont:(NSFont *)fontObject		{ [super setFont:fontObject]; }
- (NSCellImagePosition) imagePosition		{ return _c.imagePosition; }
- (NSImage *) alternateImage				{ return _alternateImage; }
- (NSImage *) image							{ return _normalImage; }
- (NSImage *) _mixedImage					{ return _mixedImage; }
- (void) setAlternateImage:(NSImage*)aImage	{ ASSIGN(_alternateImage,aImage); }
- (void) setImage:(NSImage *)anImage		{ ASSIGN(_normalImage, anImage); }
- (void) _setMixedImage:(NSImage *)anImage	{ ASSIGN(_mixedImage, anImage); }
- (NSAttributedString *) attributedTitle	{ return [_title isKindOfClass:[NSAttributedString class]]?(NSAttributedString *) _title:[[[NSAttributedString alloc] initWithString:_title] autorelease]; }
- (NSString *) title						{ return [_title isKindOfClass:[NSAttributedString class]]?[(NSAttributedString *) _title string]:_title; }
- (void) setAttributedTitle:(NSAttributedString *)aStr	{ ASSIGN(_title, aStr); }

- (void) setImagePosition:(NSCellImagePosition)aPosition
{
	_c.imagePosition = aPosition;
}

- (NSSize) cellSize
{
	NSSize m=[super cellSize];	// get text size

	if(_normalImage != nil)
		{
		switch (_c.imagePosition) 
			{												
			case NSImageOnly:
				m = [_normalImage size];
			case NSNoImage:
				break;
			case NSImageLeft:
			case NSImageRight:
				m.width += [_normalImage size].width + 8;
				break;
			case NSImageBelow:
			case NSImageAbove:
				m.height += [_normalImage size].height + 4;
				break;
			case NSImageOverlaps:
				{
				NSSize img = [_normalImage size];

				m.width = MAX(img.width + 4, m.width);
				m.height = MAX(img.height + 4, m.height);
				break;
		}	}	}

	return m;
}

- (void) getPeriodicDelay:(float *)delay interval:(float *)interval
{
	if(delay)
		*delay = _periodicDelay;
	if(interval)
		*interval = _periodicInterval;
}

- (void) setPeriodicDelay:(float)delay interval:(float)interval
{
	_periodicDelay = delay;
	_periodicInterval = interval;						// Set Repeat Interval
}

- (void) performClick: (id)sender
{
	[super performClick:sender];
}
															// Key Equivalent 
- (NSFont*) keyEquivalentFont			{ return _keyEquivalentFont; }

- (unsigned int) keyEquivalentModifierMask 	
{ 
	return _keyEquivalentModifierMask;
}

// override default implementation of NSCell
- (NSString*) keyEquivalent				{ return _keyEquivalent; }

- (void) setKeyEquivalent:(NSString*)key	
{ 
	if (_keyEquivalent != key)
		ASSIGN(_keyEquivalent, [[key copy] autorelease]);
}

- (void) setKeyEquivalentModifierMask:(unsigned int)mask
{
	_keyEquivalentModifierMask = mask;
}

- (void) setKeyEquivalentFont:(NSFont*)fontObj
{
	ASSIGN(_keyEquivalentFont, fontObj);
}

- (void) setKeyEquivalentFont:(NSString*)fontName size: (float)fontSize
{
	ASSIGN(_keyEquivalentFont, [NSFont fontWithName:fontName size:fontSize]);
}

- (void) setButtonType:(NSButtonType)buttonType			// Graphic Attributes
{
	switch(_buttonType=buttonType)
		{
		case NSMomentaryLightButton:
			_highlightMask = NSChangeGrayCellMask | NSChangeBackgroundCellMask;
			_stateMask = NSNoCellMask;
			break;
		case NSMomentaryPushInButton:
			_highlightMask = NSPushInCellMask | NSChangeGrayCellMask | NSChangeBackgroundCellMask;
			_stateMask = NSNoCellMask;
			break;
		case NSMomentaryChangeButton:
			_highlightMask = NSContentsCellMask;
			_stateMask = NSNoCellMask;
			break;
		case NSPushOnPushOffButton:
			_highlightMask = NSPushInCellMask | NSChangeGrayCellMask | NSChangeBackgroundCellMask;
			_stateMask = NSChangeGrayCellMask | NSChangeBackgroundCellMask;
			break;
		case NSOnOffButton:
			_stateMask = _highlightMask = NSChangeGrayCellMask | NSChangeBackgroundCellMask;
			break;
		case NSToggleButton:
			_highlightMask = NSPushInCellMask | NSContentsCellMask;
			_stateMask = NSContentsCellMask;
			break;
		case NSSwitchButton:
			_stateMask = _highlightMask = NSContentsCellMask;
//			[_alternateImage release];
//			_alternateImage=(NSImage *) [[NSButtonImageSource alloc] initWithName:@"NSSwitch"];
			[self setImagePosition:NSImageLeft];
			_c.bordered=NO;	// no Bezel
			break;
		case NSRadioButton:
			_stateMask = _highlightMask = NSContentsCellMask;
//			[_alternateImage release];
//			_alternateImage=(NSImage *) [[NSButtonImageSource alloc] initWithName:@"NSRadioButton"];
			[self setImagePosition:NSImageLeft];
			_c.bordered=NO;	// no Bezel
			break;
		}
	[self setState:[self state]];		// update our state (to a valid value)
}

#define stateOrHighlight(mask) ((_c.state != 0 && (_stateMask & (mask))) || (_c.highlighted && (_highlightMask & (mask))))

- (BOOL) isTransparent					{ return ![self isOpaque]; }

- (BOOL) isOpaque
	{ 
	return _backgroundColor && (
		!_transparent || _c.bordered || _c.drawsBackground || 
		(_stateMask & NSChangeBackgroundCellMask) || 
		stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask));
	}

- (int) highlightsBy					{ return _highlightMask; }
- (int) showsStateBy					{ return _stateMask; }
- (NSBezelStyle) bezelStyle;			{ return _bezelStyle; }
- (BOOL) imageDimsWhenDisabled;			{ return _dimsWhenDisabled; }
- (void) setTransparent:(BOOL)flag		{ _transparent = flag; }
- (void) setImageDimsWhenDisabled:(BOOL)flag;	{ _dimsWhenDisabled = flag; }
- (void) setHighlightsBy:(int)mask		{ _highlightMask = mask; }
- (void) setShowsStateBy:(int)mask		{ _stateMask = mask; }
- (void) setBezelStyle:(NSBezelStyle) bezelStyle; { _bezelStyle=bezelStyle; }
- (void) setIntValue:(int)anInt			{ [self setState:(anInt != 0)]; }
- (void) setFloatValue:(float)aFloat	{ [self setState:(aFloat != 0)]; }
- (void) setDoubleValue:(double)aDouble	{ [self setState:(aDouble != 0)]; }

- (void) setObjectValue:(id <NSCopying>)anObject
{
	if([(id <NSObject>) anObject respondsToSelector:@selector(intValue)])
		[self setState:[(id) anObject intValue]];
	else
		[self setState:(anObject != nil)];
}

- (void) stopTracking:(NSPoint)lastPoint
									 at:(NSPoint)stopPoint
						   inView:(NSView*)controlView
						mouseIsUp:(BOOL)flag;
{
#if 1
	NSLog(@"clicked on %@ bezelStyle=%d", _title, _bezelStyle);
#endif
	if(flag)
		[self setNextState];	// cycle
}

// does not use _c.state to allow for subclasses to override -state

- (int) intValue						{ return [self state]; }
- (float) floatValue					{ return [self state]; }
- (double) doubleValue					{ return [self state]; }
- (id) objectValue		{ return [NSNumber numberWithInt:[self state]]; }

// FIXME:
// visual appearance (colors, shapes, icons) depends on:
// _bezelStyle
// stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask)
// _c.bordered
// _state

- (NSRect) drawingRectForBounds:(NSRect) cellFrame
{
	switch(_bezelStyle & 15)	// only lower 4 bits are relevant
		{
		case _NSTraditionalBezelStyle:
			break;
		case NSRoundedBezelStyle:
			cellFrame=NSInsetRect(cellFrame, 4, floor(cellFrame.size.height*0.1875));	// make smaller than enclosing frame
			break;
		case NSRegularSquareBezelStyle:		// Square 2 pixels border
		case NSThickSquareBezelStyle:		// 3 px
		case NSThickerSquareBezelStyle:		// 4 px
			break;
		case NSDisclosureBezelStyle:
			cellFrame.origin.x=(cellFrame.size.width-cellFrame.size.height)/2.0;
			cellFrame.size.width=cellFrame.size.height;	// make square in the middle
			break;
		case NSShadowlessSquareBezelStyle:
			break;
		case NSCircularBezelStyle:
			cellFrame.origin.x=(cellFrame.size.width-cellFrame.size.height)/2.0;
			cellFrame.size.width=cellFrame.size.height;	// make square in the middle
			break;
		case NSTexturedSquareBezelStyle:
			break;
		case NSHelpButtonBezelStyle:
			cellFrame.origin.x=(cellFrame.size.width-cellFrame.size.height)/2.0;
			cellFrame.size.width=cellFrame.size.height;	// make square in the middle
			break;
		case NSSmallSquareBezelStyle:
			break;
		case NSTexturedRoundBezelStyle:
			break;
		case NSRoundRectBezelStyle:
			cellFrame=NSInsetRect(cellFrame, 4, floor(cellFrame.size.height*0.1875));	// make smaller than enclosing frame
			break;
		case NSRecessedBezelStyle:
			cellFrame=NSInsetRect(cellFrame, 4, floor(cellFrame.size.height*0.1875));	// make smaller than enclosing frame
			break;
		case NSRoundedDisclosureBezelStyle:
			break;
		case 15:
			break;
		}
	return cellFrame;
}

- (void) drawBezelWithFrame:(NSRect) cellFrame inView:(NSView *) controlView;
{
	NSColor *backgroundColor;
	NSGraphicsContext *ctxt;
	NSBezierPath *bezel;
#if 0
	NSLog(@"drawBezelWithFrame %@", self);
#endif
#if 0
	if([_title isEqualToString:@"Round Textured"])
		NSLog(@"drawing %@", _title);
#endif
	if(stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask))
		backgroundColor = [NSColor whiteColor];		// make background white dependent on state/highlight
	else if(_c.drawsBackground) // not bordered - e.g. Radio Button and Checkbox
		backgroundColor=_backgroundColor;
	else 
		backgroundColor = nil;	// default: transparent
	if(!_c.bordered)
		{ // special case for non-bordered buttons
		if(!backgroundColor && (_stateMask & NSChangeBackgroundCellMask))
			backgroundColor = [NSColor windowBackgroundColor];	// show control background even if not bordered (On/Off and Push On/Push Off buttons)
		if(backgroundColor)
			{
			[backgroundColor setFill];
			NSRectFill(cellFrame);
			}
		return;
		}	
	cellFrame=[self drawingRectForBounds:cellFrame];
#if 0
	NSLog(@"bgcolor=%@", backgroundColor);
#endif
	switch(_bezelStyle & 15)	// only lower 4 bits are relevant
		{
		case _NSTraditionalBezelStyle:
			{ // traditional Bezel
				if(stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask))
					NSDrawWhiteBezel(cellFrame, cellFrame);
				else
					NSDrawGrayBezel(cellFrame, cellFrame);
				break;
			}
		case NSRoundedBezelStyle:
			{ // standard Push Button (half-circle at both ends)
				ctxt=[NSGraphicsContext currentContext];
				if(_c.highlighted != ([_keyEquivalent isEqualToString:@"\r"] || [_keyEquivalent isEqualToString:@"\n"]))
					backgroundColor=[NSColor selectedControlColor];	// selected or default button
				else if(!backgroundColor)
					backgroundColor=[NSColor controlColor];	// never transparent
				bezel=[NSBezierPath _bezierPathWithRoundedBezelInRect:cellFrame vertical:NO];	// box with halfcircular rounded ends
				[ctxt saveGraphicsState];
				[bezel addClip];	// clip to contour
				[backgroundColor setFill];
				[bezel fill];		// fill with background color
				[ctxt restoreGraphicsState];
				[[NSColor blackColor] setStroke];
				[bezel stroke];		// and stroke rounded button
				break;
			}
		case NSRegularSquareBezelStyle:		// Square 2 pixels border
		case NSThickSquareBezelStyle:		// 3 px
		case NSThickerSquareBezelStyle:		// 4 px
			{
				[NSBezierPath _drawRoundedBezel:3 inFrame:cellFrame enabled:YES selected:NO highlighted:stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask) radius:5.0];	// draw segment
#if 0
				float radius=3.0;
				ctxt=[NSGraphicsContext currentContext];
				bezel=[NSBezierPath new];
				[bezel appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(cellFrame)+radius, NSMinY(cellFrame)+radius)
												  radius:radius
											  startAngle:270.0
												endAngle:180.0
											   clockwise:YES];
				[bezel appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(cellFrame)+radius, NSMaxY(cellFrame)-radius)
												  radius:radius
											  startAngle:180.0
												endAngle:90.0
											   clockwise:YES];
				[bezel appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(cellFrame)-radius, NSMaxY(cellFrame)-radius)
												  radius:radius
											  startAngle:90.0
												endAngle:0.0
											   clockwise:YES];
				[bezel appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(cellFrame)-radius, NSMinY(cellFrame)+radius)
												  radius:radius
											  startAngle:0.0
												endAngle:270.0
											   clockwise:YES];
				[bezel closePath];
				[ctxt saveGraphicsState];
				[bezel addClip];	// clip to contour
				if(stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask))
					backgroundColor = [NSColor whiteColor];		// make background white dependent on state/highlight
				if(!backgroundColor)
					[[NSColor controlHighlightColor] setFill]; // bordered cell never has transparent background
				else
					[backgroundColor setFill];
				[bezel fill];		// fill with background color
				[[NSColor controlShadowColor] setStroke];	// border shadow
				[ctxt restoreGraphicsState];
				[[NSColor blackColor] setStroke];
				[bezel stroke];		// and stroke rounded button
				[bezel release];
#endif
				break;
			}
		case NSDisclosureBezelStyle:
			{
				NSImage *img=_image;
				// img=[[NSButtonImageSource alloc] initWithName:@"NSDisclose"];	// assign as default image source
				// if([img isKindOfClass:[NSButtonImageSource class]])
				//	img=[_image buttonImageForCell:self];
				[img drawInRect:cellFrame fromRect:NSZeroRect operation:0 fraction:1.0];
				break;
			}
		case NSShadowlessSquareBezelStyle:
			{
				if(stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask))
					[[NSColor controlHighlightColor] setFill];
				else if(!backgroundColor)
					[[NSColor controlColor] setFill];
				else
					[backgroundColor setFill];
				NSRectFill(cellFrame);
				[[NSColor controlDarkShadowColor] setFill];	// border
				NSFrameRectWithWidth(cellFrame, 1);
				break;
			}
		case NSCircularBezelStyle:
			{ // Round
			  // FIXME: we should get an NSImage
				ctxt=[NSGraphicsContext currentContext];
				bezel=[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(cellFrame, 1, 1)];	// make smaller so that it does not touch frame
				if(!backgroundColor) backgroundColor=[NSColor controlColor];
				[ctxt saveGraphicsState];
				[bezel addClip];
				[backgroundColor set];
				[bezel fill];		// fill oval with background color
				[ctxt restoreGraphicsState];
				[_c.highlighted?[NSColor selectedControlColor]:[NSColor blackColor] set];	// make ring color dependent on highlight state?
				[bezel stroke];
				break;
			}
		case NSTexturedSquareBezelStyle:
			{
				if(stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask))
					[[NSColor controlShadowColor] setFill];
				else if(!backgroundColor)
					[[NSColor controlHighlightColor] setFill]; // bordered cell never has transparent background
				else
					[backgroundColor setFill];
				NSRectFill(cellFrame);
				[[NSColor controlDarkShadowColor] setFill];	// border
				NSFrameRectWithWidth(cellFrame, 1);
				break;
			}
		case NSHelpButtonBezelStyle:
			{
				NSSize size;
				// FIXME: we should draw a HelpButton NSImage
				ctxt=[NSGraphicsContext currentContext];
				bezel=[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(cellFrame, 2, 2)];	// make smaller so that it does not touch frame
				if(!backgroundColor)
					backgroundColor=[NSColor controlColor];
				[ctxt saveGraphicsState];
				[bezel addClip];
				[_c.highlighted?[NSColor selectedControlColor]:backgroundColor set];	// fill interior
				[bezel fill];		// fill oval with background color
				[ctxt restoreGraphicsState];
				[[NSColor blackColor] set];	// black ring
				[bezel stroke];
				size=[@"?" sizeWithAttributes:nil];
				cellFrame.origin.x+=(cellFrame.size.width-size.width)/2.0;
				cellFrame.origin.y+=(cellFrame.size.height-size.height)/2.0;
				[@"?" drawAtPoint:cellFrame.origin withAttributes:nil];	// default attribs
				break;
			}
		case NSSmallSquareBezelStyle:
			{
				if(stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask))
					[[NSColor controlHighlightColor] setFill];
				else if(!backgroundColor)
					[[NSColor controlColor] setFill];
				else
					[backgroundColor setFill];
				NSRectFill(cellFrame);
				[[NSColor controlDarkShadowColor] setFill];	// border
				NSFrameRectWithWidth(cellFrame, 1);
				break;
			}
		case NSTexturedRoundBezelStyle:
			{
				if(stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask))
					[[NSColor controlShadowColor] setFill];
				else if(!backgroundColor)
					[[NSColor controlHighlightColor] setFill]; // bordered cell never has transparent background
				else
					[backgroundColor set];
				NSRectFill(cellFrame);
				[[NSColor controlDarkShadowColor] setFill];	// border
				NSFrameRectWithWidth(cellFrame, 1);
				break;
			}
		case NSRoundRectBezelStyle:
			{
				ctxt=[NSGraphicsContext currentContext];
				if(!backgroundColor)
					backgroundColor=[NSColor controlColor];
				bezel=[NSBezierPath _bezierPathWithRoundedBezelInRect:cellFrame vertical:NO];	// box with halfcircular rounded ends
				[ctxt saveGraphicsState];
				[bezel addClip];	// clip to contour
				[backgroundColor setFill];
				[bezel fill];		// fill with background color
				[ctxt restoreGraphicsState];
				[[NSColor lightGrayColor] setStroke];
				[bezel stroke];		// and stroke rounded button
				break;
			}
		case NSRecessedBezelStyle:
			{ // has no border
				ctxt=[NSGraphicsContext currentContext];
				if(!backgroundColor)
					backgroundColor=[NSColor controlColor];
				bezel=[NSBezierPath _bezierPathWithRoundedBezelInRect:cellFrame vertical:NO];	// box with halfcircular rounded ends
				[ctxt saveGraphicsState];
				[bezel addClip];	// clip to contour
				[backgroundColor setFill];
				[bezel fill];		// fill with background color
				[ctxt restoreGraphicsState];
				break;
			}
		case NSRoundedDisclosureBezelStyle:
			{ // blue regular square with small centered down-pointing arrow
				[NSBezierPath _drawRoundedBezel:3 inFrame:cellFrame enabled:YES selected:YES highlighted:stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask) radius:5.0];	// draw segment
				// draw centered [NSImage imageNamed:@"GSArrowDown"]
			}
		case 15:
			NSLog(@"NSButtonCell (%@) unknown bezelStyle:%d", _title, _bezelStyle);
			break;
		}
}

- (void) drawImage:(NSImage *) img withFrame:(NSRect) cellFrame inView:(NSView *) controlView;
{
	NSSize imageSize;
	NSCompositingOperation op;
	if(!img || _transparent || _c.imagePosition == NSNoImage)
		return;	// don't draw any image
	if(stateOrHighlight(NSChangeBackgroundCellMask))
		op = NSCompositeHighlight;	// change background
	else
		op = NSCompositeSourceOver;	// default composition
	// shouldn't we use imageRectForBounds?
	imageSize = [img size];
	switch(_c.imagePosition) 
		{
		case NSImageOnly:			// draw image only - centered
		case NSImageOverlaps: 		// draw title over the centered image
			cellFrame.origin.x += (NSWidth(cellFrame) - imageSize.width)/2;
			cellFrame.origin.y += (NSHeight(cellFrame) - imageSize.height)/2;
			break;
		case NSImageLeft:					 			// draw image to the left of title
			cellFrame.origin.x += 4;
			cellFrame.origin.y += (NSHeight(cellFrame) - imageSize.height)/2;
			break;
		case NSImageRight:					 			// draw image to the right of the title
			cellFrame.origin.x += (NSWidth(cellFrame) - imageSize.width) - 4;
			cellFrame.origin.y += (NSHeight(cellFrame) - imageSize.height)/2;
			break;
		case NSImageBelow:								// draw image below the title
			cellFrame.origin.x += (NSWidth(cellFrame) - imageSize.width)/2;
			cellFrame.origin.y += 4;
			break;
		case NSImageAbove:						 		// draw image above the title
			cellFrame.origin.x += (NSWidth(cellFrame) - imageSize.width)/2;
			cellFrame.origin.y += (NSHeight(cellFrame) - imageSize.height) - 4;
			break;
		}
	if(stateOrHighlight(NSPushInCellMask))
		{ // makes button appear pushed in
		cellFrame.origin.x += 1;
		cellFrame.origin.y += 1;
		}
//	if([controlView isFlipped])
//		cellFrame.origin.y += imageSize.height;
#if 0
	NSLog(@"image %@ at %@", image, NSStringFromPoint(cellFrame.origin));
#endif
	// FIXME: handle imageDimsWhenDisabled
	// shouldn't we drawInRect: to scale properly?
	[_image compositeToPoint:cellFrame.origin operation:op];	
}

- (void) drawTitle:(NSAttributedString *) title withFrame:(NSRect) cellFrame inView:(NSView *) controlView;
{ // this is an inofficial method!
	NSColor *titleColor = [NSColor controlTextColor];	// default
	NSRect textFrame;
	id savedContents;
	
	if(!title || _transparent || _c.imagePosition == NSImageOnly)
		return;	// don't draw title
	if(stateOrHighlight(NSChangeGrayCellMask)) 
		{ // change text color when highlighting
		titleColor=[NSColor selectedControlTextColor];
		}
	if(stateOrHighlight(NSPushInCellMask))
		{ // make button appear pushed in (move text down one pixel?)
		  // might have to depend on bezel style
		}
	if(_c.bordered)
		{ // handle special Bezels
		switch(_bezelStyle)
			{ // special
			case NSRoundRectBezelStyle:
			case NSTexturedRoundBezelStyle:
			case NSRoundedBezelStyle:
				cellFrame=NSInsetRect(cellFrame, 10.0, 2.0+floor(cellFrame.size.height*0.1875));	// make text area smaller than enclosing frame
				break;
			default:
				break;
			}
		}

	// FIXME: do we really need to calculate this here?
	// or should we override imageRectForBounds, drawingRectForBounds, titleRectForBounds here and in NSCell?
	
	_d.verticallyCentered=YES;	// within its box
	textFrame=cellFrame;
	if(_image && !(_c.imagePosition == NSNoImage || _c.imagePosition == NSImageOverlaps))
		{ // adjust text field position for image
		NSSize imageSize=[_image size];
		switch(_c.imagePosition) 
			{												
			case NSImageLeft:					 			// draw image to the left of title
				textFrame.origin.x+=imageSize.width+8;
				textFrame.size.width-=imageSize.width+8;
				break;
			case NSImageRight:					 			// draw image to the right of the title
				textFrame.origin.x+=4;
				textFrame.size.width-=imageSize.width+8;
				break;
			case NSImageBelow:								// draw image below the title
				_c.alignment=NSCenterTextAlignment;
				textFrame.origin.y += imageSize.height+4;
				textFrame.size.height-=imageSize.height+8;
				break;
			case NSImageAbove:						 		// draw image above the title
				_c.alignment=NSCenterTextAlignment;
				_d.verticallyCentered=NO;
				textFrame.origin.y += 4;
				textFrame.size.height-=imageSize.height+8;
				break;
			default:
				break;
			}
		}
	savedContents=_contents;	// FIXME: do we really need to save? We don't use it otherwise
	ASSIGN(_textColor, titleColor);	// change color as needed
	/* NOTE:
		this code will also work if title is an AttributedString or if a NSFormatter is attached
		i.e. we can easily implement attributedTitle, attributedAlternateTitle etc.
		*/
	_contents=title;	// draw title by superclass
#if 0	// test to find out why NSEnabled is not working properly
	if(!_c.enabled)
		NSLog(@"button not enabled: %@", self);
#endif
#if 0
	NSLog(@"ButtonCell draw: %@ textFrame: %@", _contents, NSStringFromRect(textFrame));
#endif
	[super drawInteriorWithFrame:textFrame inView:controlView];
	_contents=savedContents;
}

- (void) drawWithFrame:(NSRect)cellFrame				// Draw cell's frame
				inView:(NSView*)controlView
{
	NSDebugLog(@"NSButtonCell drawWithFrame \n");	
	if(_transparent)
		return;	// don't draw
	_controlView = controlView;						// Save as last view we have drawn to	
	if(NSWidth(cellFrame) <= 0.0 || NSHeight(cellFrame) <= 0.0)	// do nothing if cell's frame rect is zero
		return;	
	if(_d.focusRingType != NSFocusRingTypeNone && [self showsFirstResponder])
		{ // button is first responder cell - draw focus ring
		BOOL isFlipped = [controlView isFlipped];
		NSColor *y = [NSColor selectedControlColor];
		NSColor *c[] = {y, y, y, y};
		NSRect cellRing=NSInsetRect(cellFrame, -1, -1);
		NSDrawColorTiledRects(cellRing, cellRing, isFlipped ? BEZEL_EDGES_FLIPPED : BEZEL_EDGES_NORMAL, c, 4);
		}
	[self drawBezelWithFrame:cellFrame inView:controlView];	
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void) drawInteriorWithFrame:(NSRect) cellFrame inView:(NSView*) controlView
{
	NSAttributedString *title;
	if([_normalImage isKindOfClass:[NSButtonImageSource class]])
		_image=[(NSButtonImageSource *) _normalImage buttonImageForCell:self];	// substitute
	else
		_image=_normalImage;	// default image
	if(_c.state == NSMixedState && _mixedImage)
		_image=_mixedImage;
	else if(_alternateImage && stateOrHighlight(NSContentsCellMask))	// alternate content
		_image=_alternateImage;
#if 0
	NSLog(@"draw image %@", _image);
#endif
	[self drawImage:_image withFrame:cellFrame inView:controlView];
	// FIXME: here, we are not clean for data types!!!
	// and: when should we use title and when attributedTitle
	title=(NSAttributedString *) _title;
	if([title length] == 0 || stateOrHighlight(NSContentsCellMask))		// standard content
		{ // change to alternate text/image (if defined)
		if([_alternateTitle length] != 0)
			title = (NSAttributedString *) _alternateTitle;
		}
#if 0
	NSLog(@"draw title %@", title);
#endif
	[self drawTitle:title withFrame:cellFrame inView:controlView];
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject: _alternateTitle];
	[aCoder encodeObject: _alternateImage];
	[aCoder encodeObject: _normalImage];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &_transparent];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	self=[super initWithCoder:aDecoder];	// NSCell
	if([aDecoder allowsKeyedCoding])
		{
		unsigned int buttonflags=[aDecoder decodeIntForKey:@"NSButtonFlags"];
		unsigned int buttonflags2=[aDecoder decodeIntForKey:@"NSButtonFlags2"];
		_buttonType=-1;	// we don't know
#if 0
		NSLog(@"%@ controlSize=%d", self, [self controlSize]);
#endif
		// the encoding is quite weird
		// stateby mapping
		//		bit 0 <-> bit 30
		//		bit 1 <- always 0
		//		bit 2,3 <-> bit 28,29
#define STATEBY (((buttonflags&(1<<30))>>(30-0))+((buttonflags&(3<<28))>>(28-2)))
		_stateMask=STATEBY;
		// highlightsby mapping
		//		bit 0 <-> bit 27
		//		bit 1 <-> bit 31
		//		bit 2,3 <-> bit 25,26
#define HIGHLIGHTSBY (((buttonflags&(1<<27))>>(27-0))+((buttonflags&(1<<31))>>(31-1))+((buttonflags&(3<<25))>>(25-2)))
		_highlightMask=HIGHLIGHTSBY;
#define DRAWING ((buttonflags&(1<<24))!=0)
		// ignored
#define BORDERED ((buttonflags&(1<<23))!=0)
		_c.bordered |= BORDERED;	// combine with cell border (meaning isBezeled...)
#define OVERLAPS ((buttonflags&0x00400000)!=0)
#define IMAGEPOSITION (NSImageAbove-((buttonflags&0x00300000)>>20))
#define IMAGEANDTEXT ((buttonflags&0x00080000)!=0)
#define IMAGESIZEDIFF ((buttonflags&0x00040000)!=0)
#define KEYEQUIVNOIMAGE ((buttonflags&0x00020000)!=0)

		if(OVERLAPS)
			_c.imagePosition=IMAGEANDTEXT?NSImageOverlaps:NSImageOnly;
		else if(IMAGEANDTEXT)
			_c.imagePosition=IMAGEPOSITION;
		else
			_c.imagePosition=NSNoImage;

#define TRANSPARENT ((buttonflags&0x00008000)!=0)
		_transparent=TRANSPARENT;
#define INSET ((buttonflags&0x00006000)>>13)
#define DIMSWHENDISABLED ((buttonflags&0x00001000)==0)
		_dimsWhenDisabled=DIMSWHENDISABLED;
#define GRADIENTTYPE ((buttonflags&(7<<9))>>9)
#define ALTERNATEMNEMONICLOC ((buttonflags&0x000000ff)>>0)	// 0xff=none

#define KEYEQUIVALENTMASK ((buttonflags2&0xffffff00)>>8)
		_keyEquivalentModifierMask = KEYEQUIVALENTMASK;	// if encoded by flags
#define BORDERWHILEMOUSEINSIDE ((buttonflags2&0x00000010)!=0)
#define BEZELSTYLE (((buttonflags2&(7<<0))>>0)+((buttonflags2&(8<<2))>>2))
		_bezelStyle=BEZELSTYLE;
		
		ASSIGN(_alternateTitle, [aDecoder decodeObjectForKey:@"NSAlternateContents"]);
		ASSIGN(_alternateImage, [aDecoder decodeObjectForKey:@"NSNormalImage"]);	// appears to be mixed up in IB archive
		ASSIGN(_normalImage, [aDecoder decodeObjectForKey:@"NSAlternateImage"]);
		if(_normalImage==nil || [_normalImage isKindOfClass:[NSFont class]])
			ASSIGN(_normalImage, _alternateImage), [_alternateImage release], _alternateImage=nil;	// bug in IB archiver
		ASSIGN(_title, [aDecoder decodeObjectForKey:@"NSContents"]);		// define as title string and not really _contents
		if([aDecoder containsValueForKey:@"NSAttributedTitle"])
			ASSIGN(_title, [aDecoder decodeObjectForKey:@"NSAttributedTitle"]);	// overwrite
		ASSIGN(_keyEquivalent, [aDecoder decodeObjectForKey:@"NSKeyEquivalent"]);
		if([aDecoder containsValueForKey:@"NSKeyEquiv"])
			ASSIGN(_keyEquivalent, [aDecoder decodeObjectForKey:@"NSKeyEquiv"]);
		if([aDecoder containsValueForKey:@"NSKeyEquivModMask"])
			_keyEquivalentModifierMask = [aDecoder decodeIntForKey:@"NSKeyEquivModMask"];
		_periodicDelay = 0.001*[aDecoder decodeIntForKey:@"NSPeriodicDelay"];
		_periodicInterval = 0.001*[aDecoder decodeIntForKey:@"NSPeriodicInterval"];
#if 0
		NSLog(@"initWithCoder: %@", self);
		NSLog(@"  title=%@", _title);
		NSLog(@"  normalImage=%@", _normalImage);
		NSLog(@"  alternateImage=%@", _alternateImage);
		NSLog(@"  NSMnemonicLoc=%d", [aDecoder decodeIntForKey:@"NSMnemonicLoc"]);
		NSLog(@"  NSButtonFlags=%08x", [aDecoder decodeIntForKey:@"NSButtonFlags"]);	// encodes the button type&style
		NSLog(@"  NSButtonFlags2=%08x", [aDecoder decodeIntForKey:@"NSButtonFlags2"]);
		NSLog(@"  bezelstyle=%d", _bezelStyle);
		NSLog(@"  buttontype=%d", _buttonType);
		NSLog(@"  transparent=%d", _transparent);
		NSLog(@"  stateMask=%d", _stateMask);
		NSLog(@"  highlightMask=%d", _highlightMask);
		NSLog(@"  dimsWhenDisabled=%d", _dimsWhenDisabled);
#endif
		return self;
		}
	_alternateTitle = [[aDecoder decodeObject] retain];
	_alternateImage = [[aDecoder decodeObject] retain];
	_normalImage = [[aDecoder decodeObject] retain];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_transparent];
	
	return self;
}

@end

//*****************************************************************************
//
// 		NSButton 
//
//*****************************************************************************

@implementation NSButton

+ (void) initialize
{
	if (self == [NSButton class]) 
   		__buttonCellClass = [NSButtonCell class];
}

+ (Class) cellClass						{ return __buttonCellClass; }
+ (void) setCellClass:(Class)aClass		{ __buttonCellClass = aClass; }

- (id) initWithFrame:(NSRect)frameRect
{
	if((self=[super initWithFrame:frameRect]))	// installs a default cell
		{
		_v.autoresizingMask = (NSViewMaxXMargin | NSViewMaxYMargin);
		}
	return self;
}

- (void) getPeriodicDelay:(float*)delay interval:(float*)interval
{
	[_cell getPeriodicDelay:delay interval:interval];
}

- (void) setPeriodicDelay:(float)delay interval:(float)interval
{
	[_cell setPeriodicDelay:delay interval:interval];
}

- (void) setButtonType:(NSButtonType)aType
{
	[_cell setButtonType:aType];
	[self setNeedsDisplay:YES];
}

- (void) setState:(int)value			{ [_cell setState:value]; [self setNeedsDisplay:YES]; }
- (void) setNextState					{ [_cell setNextState]; [self setNeedsDisplay:YES]; }
- (void) setIntValue:(int)anInt			{ [_cell setIntValue:anInt]; }
- (void) setFloatValue:(float)aFloat	{ [_cell setFloatValue:aFloat]; }
- (void) setDoubleValue:(double)aDouble	{ [_cell setDoubleValue:aDouble]; }
- (void) setObjectValue:(id <NSCopying>)val	{ [_cell setObjectValue:val]; }
- (int) state							{ return [_cell state]; }
- (NSString*) alternateTitle			{ return [_cell alternateTitle]; }
- (NSAttributedString*) attributedAlternateTitle	{ return [_cell attributedAlternateTitle]; }
- (NSAttributedString*) attributedTitle				{ return [_cell attributedTitle]; }
- (NSString*) title						{ return [_cell title]; }
- (NSString*) keyEquivalent				{ return [_cell keyEquivalent]; }
- (NSImage*) image						{ return [_cell image]; }
- (NSImage*) alternateImage				{ return [_cell alternateImage]; }
- (NSCellImagePosition) imagePosition	{ return [_cell imagePosition]; }
- (BOOL) allowsMixedState				{ return [_cell allowsMixedState]; }
- (BOOL) isBordered						{ return [_cell isBordered]; }
- (BOOL) isTransparent					{ return [_cell isTransparent]; }
- (BOOL) isOpaque						{ return [_cell isOpaque]; }
- (BOOL) isFlipped						{ return YES; }
- (BOOL) showsBorderOnlyWhileMouseInside	{ return [_cell showsBorderOnlyWhileMouseInside]; }
- (NSBezelStyle) bezelStyle;			{ return [_cell bezelStyle]; }

- (void) setAlternateTitle:(NSString *)aString
{
	[_cell setAlternateTitle:aString];
	[self setNeedsDisplay:YES];
}

- (void) setAttributedAlternateTitle:(NSAttributedString *)aString
{
	[_cell setAttributedAlternateTitle:aString];
	[self setNeedsDisplay:YES];
}

- (void) setAttributedTitle:(NSAttributedString *)aString
{
	[_cell setAttributedTitle:aString];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *)aString
{
	[_cell setTitle:aString];
	[self setNeedsDisplay:YES];
}

- (void) setTitleWithMnemonic:(NSString *)aString
{
	[_cell setTitleWithMnemonic:aString];
	[self setNeedsDisplay:YES];
}

- (void) setAlternateImage:(NSImage *)anImage
{
	[_cell setAlternateImage:anImage];
	[self setNeedsDisplay:YES];
}

- (void) setImage:(NSImage *)anImage
{
	[_cell setImage:anImage];
	[self setNeedsDisplay:YES];
}

- (void) setImagePosition:(NSCellImagePosition)aPosition
{
	[_cell setImagePosition:aPosition];
	[self setNeedsDisplay:YES];
}

- (void) setShowsBorderOnlyWhileMouseInside:(BOOL)flag { [_cell setShowsBorderOnlyWhileMouseInside:flag]; }

- (void) setAllowsMixedState:(BOOL)flag
{
	[_cell setAllowsMixedState:flag];
	[self setNeedsDisplay:YES];
}

- (void) setBezelStyle:(NSBezelStyle) style;
{
	[_cell setBezelStyle:style];
	[_cell setBezeled:YES];
	[self setNeedsDisplay:YES];
}

- (void) setBordered:(BOOL)flag
{
	[_cell setBordered:flag];	// has a different interpretation
	[self setNeedsDisplay:YES];
}

- (void) setTransparent:(BOOL)flag
{
	[_cell setTransparent:flag];
	[self setNeedsDisplay:YES];
}

- (void) setSound:(NSSound *) sound	{ [_cell setSound:sound]; }
- (NSSound *) sound; { return [_cell sound]; }

- (void) highlight:(BOOL)flag
{
	[_cell highlight:flag withFrame:bounds inView:self];
}

- (void) setKeyEquivalent:(NSString*)aKeyEquivalent			// Key Equivalent
{
	[_cell setKeyEquivalent: aKeyEquivalent];
}

- (unsigned int) keyEquivalentModifierMask
{
	return [_cell keyEquivalentModifierMask];
}

- (void) setKeyEquivalentModifierMask:(unsigned int)mask
{
	[_cell setKeyEquivalentModifierMask: mask];
}

- (BOOL) acceptsFirstResponder
{														
	return [_cell acceptsFirstResponder] || ([self keyEquivalent] != nil);				
}														

- (BOOL) resignFirstResponder						// NSResponder overrides
{	
	if(_nextKeyView && [_cell showsFirstResponder])
		{
		[_cell setShowsFirstResponder:NO];
		[self setNeedsDisplay:YES];
		}
	return YES;
}

- (BOOL) becomeFirstResponder
{
	if(_nextKeyView && ![_cell showsFirstResponder])
		{
		[_cell setShowsFirstResponder:YES];
		[self setNeedsDisplay:YES];
		}
	return YES;
}

- (void) keyDown:(NSEvent*)event
{
	// CHECKME - is this reasonable behaviour?
	if(([self isEnabled] && [event keyCode] == ' '))	// Space
		[self performClick: self];
	else
		[super keyDown: event];
}

- (void) performClick:(id)sender							// Handle Events
{
#if 0
	NSLog(@"performClick %@", self);
#endif
	[_cell performClick: sender];
}

- (BOOL) performKeyEquivalent:(NSEvent *)anEvent
{
	if([self isEnabled])
		{
		NSString *key = [self keyEquivalent];
		unsigned int modifiers=[anEvent modifierFlags] & (NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask | NSShiftKeyMask);

		if([anEvent modifierFlags] == modifiers && [key isEqualToString: [anEvent charactersIgnoringModifiers]])
			{
#if 0
			NSLog(@"%@ performKeyEquivalent -> YES", self);
#endif	
			[self performClick:self];
			return YES;
			}
		}
#if 0
	NSLog(@"%@ performKeyEquivalent -> NO", self);
#endif	
	return NO;
}

- (void) encodeWithCoder:(NSCoder *) aCoder		{ [super encodeWithCoder:aCoder]; }
- (id) initWithCoder:(NSCoder *) aDecdr			{ return [super initWithCoder:aDecdr]; }

@end /* NSButton */
