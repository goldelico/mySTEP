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
		_d.imageScaling=NSScaleNone;	// (historical) default is no scaling
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
	[_mixedImage release];
	[_normalImage release];
	[_keyEquivalent release];
	[_keyEquivalentFont release];
	
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSButtonCell *c = [super copyWithZone:zone];

	c->_title = [_title retain];
	c->_alternateTitle = [_alternateTitle copyWithZone:zone];
	if(_alternateImage)
		c->_alternateImage = [_alternateImage retain];
	if(_normalImage)
		c->_normalImage = [_normalImage retain];
	if(_mixedImage)
		c->_mixedImage = [_mixedImage retain];
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
			@"title=%@\n"
			@"stateMask=%02lx\n"
			@"highlightMask=%02lx\n" 
			@"buttonType=%d\n" 
			@"bezelStyle=%d\n"
			@"transparent=%d\n"
			@"dimsWhenDisabled=%d\n" 
			@"bgcolor=%@\n", 
			[super description], _title, (unsigned long)_stateMask, (unsigned long)_highlightMask, _buttonType, _bezelStyle, _transparent, _dimsWhenDisabled, _backgroundColor
			];
}

- (NSColor *) backgroundColor				{ return _backgroundColor; }
- (void) setBackgroundColor:(NSColor *)col	{ ASSIGN(_backgroundColor,col); }
- (NSString *) alternateTitle				{ return _alternateTitle; }
- (void) setAlternateTitle:(NSString *)aStr	{ ASSIGN(_alternateTitle,aStr); }
- (void) setFont:(NSFont *)fontObject		{ [super setFont:fontObject]; }
- (NSCellImagePosition) imagePosition		{ return _c.imagePosition; }
- (NSImageScaling) imageScaling				{ return _d.imageScaling; }
- (NSImage *) alternateImage				{ return _alternateImage; }
- (NSImage *) image							{ return _normalImage; }
- (NSImage *) _mixedImage					{ return _mixedImage; }
- (void) setAlternateImage:(NSImage*)aImage	{ ASSIGN(_alternateImage,aImage); }
- (void) setImage:(NSImage *)anImage		{ ASSIGN(_normalImage, anImage); }
- (void) _setMixedImage:(NSImage *)anImage	{ ASSIGN(_mixedImage, anImage); }
- (NSAttributedString *) attributedTitle	{ return [_title isKindOfClass:[NSAttributedString class]]?(NSAttributedString *) _title:[[[NSAttributedString alloc] initWithString:_title] autorelease]; }
- (NSString *) title						{ return [_title isKindOfClass:[NSAttributedString class]]?[(NSAttributedString *) _title string]:_title; }
- (void) setTitle:(NSString *)title			{ ASSIGN(_title, title); }
- (void) setTitleWithMnemonic:(NSString *)aString; { [self setTitle:aString]; }
- (void) setAttributedTitle:(NSAttributedString *)aStr	{ ASSIGN(_title, aStr); }

- (void) setImagePosition:(NSCellImagePosition)aPosition
{
	_c.imagePosition = (unsigned int) aPosition;
}

- (void) setImageScaling:(NSImageScaling)scaling
{
#if 0
	NSLog(@"setImageScaling");
#endif
	_d.imageScaling = (unsigned int) scaling;
//	[_normalImage setScalesWhenResized: (_d.imageScaling != NSImageScaleNone)];
//	[_alternateImage setScalesWhenResized: (_d.imageScaling != NSImageScaleNone)];
//	[_mixedImage setScalesWhenResized: (_d.imageScaling != NSImageScaleNone)];
#if 0
	NSLog(@"setImageScaling done");
#endif
}

- (NSSize) cellSize
{
	// FIXME - base on width of title and alternateTitle! Not on contents
	NSSize m;
	if(_c.imagePosition != NSImageOnly)
			{ // get title width
				id savedContents=_contents;	// may be some retained object
				_contents=_title;
				m=[super cellSize];	// get title size
				_contents=savedContents;
				if(_c.bordered)	// undo frame calculation
					m=(NSSize){m.width-10, m.height-10};
				else if(_c.bezeled)
					m=(NSSize){m.width-12, m.height-12};
				else
					m=(NSSize){m.width-8, m.height-8};					// neither
			}
	else
		m=NSZeroSize;
#if 0
	NSLog(@"super size %@", NSStringFromSize(m));
	NSLog(@"control size %d", _d.controlSize);
#endif
	if(_normalImage != nil)
			{
				NSSize isz;
				switch(_d.controlSize)
					{
						default:
						case NSRegularControlSize:
							isz=NSMakeSize(24.0, 24.0);
							break;
						case NSSmallControlSize:
							isz=NSMakeSize(16.0, 16.0);
							break;
						case NSMiniControlSize:
							isz=NSMakeSize(14.0, 14.0);
							break;
					}
#if 0
				NSLog(@"isz %@", NSStringFromSize(isz));
				NSLog(@"image pos %d", _c.imagePosition);
#endif
				switch (_c.imagePosition) 
					{
						default:
					case NSImageOnly:
						m = isz;
						break;
					case NSNoImage:
						break;
					case NSImageLeft:
					case NSImageRight:
							m.width += isz.width + 8;
							m.height = MAX(isz.height + 4, m.height);
						break;
					case NSImageBelow:
					case NSImageAbove:
							m.height += isz.height + 4;
							m.width = MAX(isz.width + 4, m.width);
						break;
					case NSImageOverlaps:
						{
							m.width = MAX(isz.width + 4, m.width);
							m.height = MAX(isz.height + 4, m.height);
							break;
						}
				}
			}
	// add border
	if(_c.bordered)
		m=(NSSize){m.width+4, m.height+4};
	else if(_c.bezeled)
			{ // make depend on bezel style
				m=(NSSize){m.width+12, m.height+12};
			}
	else
		m=(NSSize){m.width+2, m.height+2};					// neither
#if 0
	NSLog(@"cell size %@", NSStringFromSize(m));
#endif
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
	if(delay > 60.0) delay=60.0;
	if(interval > 60.0) interval=60.0;
	_periodicDelay = delay;
	_periodicInterval = interval;						// Set Repeat Interval
}

- (void) performClick: (id)sender
{
	[super performClick:sender];
}
															// Key Equivalent 
- (NSFont*) keyEquivalentFont			{ return _keyEquivalentFont; }

- (NSUInteger) keyEquivalentModifierMask
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

- (void) setKeyEquivalentModifierMask:(NSUInteger)mask
{
	_keyEquivalentModifierMask = mask;
}

- (void) setKeyEquivalentFont:(NSFont*)fontObj
{
	ASSIGN(_keyEquivalentFont, fontObj);
}

- (void) setKeyEquivalentFont:(NSString*)fontName size: (CGFloat)fontSize
{
	ASSIGN(_keyEquivalentFont, [NSFont fontWithName:fontName size:fontSize]);
}

- (void) setButtonType:(NSButtonType)buttonType			// Graphic Attributes
{
	[self setImageDimsWhenDisabled:YES];	// default
	switch(_buttonType=buttonType)
		{
		case NSMomentaryLightButton:
			[self setHighlightsBy:NSChangeGrayCellMask | NSChangeBackgroundCellMask];
			[self setShowsStateBy:NSNoCellMask];
			break;
		case NSMomentaryPushInButton:
			[self setHighlightsBy:NSPushInCellMask | NSChangeGrayCellMask | NSChangeBackgroundCellMask];
			[self setShowsStateBy:NSNoCellMask];
			break;
		case NSMomentaryChangeButton:
			[self setHighlightsBy:NSContentsCellMask];
			[self setShowsStateBy:NSNoCellMask];
			break;
		case NSPushOnPushOffButton:
			[self setHighlightsBy:NSPushInCellMask | NSChangeGrayCellMask | NSChangeBackgroundCellMask];
			[self setShowsStateBy:NSChangeGrayCellMask | NSChangeBackgroundCellMask];
			break;
		case NSOnOffButton:
			[self setHighlightsBy:NSChangeGrayCellMask | NSChangeBackgroundCellMask];
			[self setShowsStateBy:NSChangeGrayCellMask | NSChangeBackgroundCellMask];
			break;
		case NSToggleButton:
			[self setHighlightsBy:NSPushInCellMask | NSContentsCellMask];
			[self setShowsStateBy:NSContentsCellMask];
			break;
		case NSSwitchButton:
			[self setHighlightsBy:NSContentsCellMask];
			[self setShowsStateBy:NSContentsCellMask];
			[self setImage:(NSImage *) [[NSButtonImageSource alloc] initWithName:@"NSSwitch"]];
			[self setImagePosition:NSImageLeft];
			[self setBordered:NO];
				[self setImageDimsWhenDisabled:NO];
				[self setImageScaling:NSImageScaleProportionallyDown];
			break;
		case NSRadioButton:
			[self setHighlightsBy:NSContentsCellMask];
			[self setShowsStateBy:NSContentsCellMask];
			[self setImage:(NSImage *) [[NSButtonImageSource alloc] initWithName:@"NSRadioButton"]];
			[self setImagePosition:NSImageLeft];
			[self setBordered:NO];
				[self setImageDimsWhenDisabled:NO];
				[self setImageScaling:NSImageScaleProportionallyDown];
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

- (NSInteger) highlightsBy					{ return _highlightMask; }
- (NSInteger) showsStateBy					{ return _stateMask; }
- (NSBezelStyle) bezelStyle;			{ return _bezelStyle; }
- (BOOL) imageDimsWhenDisabled;			{ return _dimsWhenDisabled; }
- (void) setTransparent:(BOOL)flag		{ _transparent = flag; }
- (void) setImageDimsWhenDisabled:(BOOL)flag;	{ _dimsWhenDisabled = flag; }
- (void) setHighlightsBy:(NSInteger)mask		{ _highlightMask = mask; }
- (void) setShowsStateBy:(NSInteger)mask		{ _stateMask = mask; }
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

- (void) stopTracking:(NSPoint) lastPoint
				   at:(NSPoint)stopPoint
			   inView:(NSView*)controlView
			mouseIsUp:(BOOL)flag;
{
#if 0
	NSLog(@"clicked on %@ bezelStyle=%d", _title, _bezelStyle);
#endif
	if(flag)
		{
		if(_buttonType == NSRadioButton)
			[self setState:NSOnState];	// don't cycle through states
		else
			[self setNextState];	// cycle
		}
}

// does never use _c.state to allow for subclasses to override -state

- (NSInteger) intValue					{ return [self state]; }
- (float) floatValue					{ return [self state]; }
- (double) doubleValue					{ return [self state]; }
- (id) objectValue		{ return [NSNumber numberWithInteger:[self state]]; }

// FIXME:
// visual appearance (colors, shapes, icons) depends on:
// _bezelStyle
// stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask)
// _c.highlighted (should dim the button a little)
// _c.bordered
// _state (shows icon, toggles background etc.)

- (NSRect) drawingRectForBounds:(NSRect) cellFrame
{
	if(!_c.bordered)
		return cellFrame;	// borderless
	switch(_bezelStyle & 15)	// only lower 4 bits are relevant
		{
		case _NSTraditionalBezelStyle:
			break;
		case NSRoundedBezelStyle:
			cellFrame=NSInsetRect(cellFrame, 4, floorf(cellFrame.size.height*0.1875));	// make smaller than enclosing frame
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
			cellFrame=NSInsetRect(cellFrame, 4, floorf(cellFrame.size.height*0.1875));	// make smaller than enclosing frame
			break;
		case NSRecessedBezelStyle:
			cellFrame=NSInsetRect(cellFrame, 4, floorf(cellFrame.size.height*0.1875));	// make smaller than enclosing frame
			break;
		case NSRoundedDisclosureBezelStyle:
			break;
		case 15:
			break;
		}
	return cellFrame;
}

- (NSRect) imageRectForBounds:(NSRect)theRect
{
	theRect=[self drawingRectForBounds:theRect];
	// handle image position
	return theRect;
}

- (NSRect) titleRectForBounds:(NSRect)theRect
{
	theRect=[self drawingRectForBounds:theRect];
	switch(_bezelStyle & 15) {
		case _NSTraditionalBezelStyle:
			break;
		case NSRoundedBezelStyle:
			theRect=NSInsetRect(theRect, 5.0, 0.0);
			break;
		case NSRegularSquareBezelStyle:		// Square 2 pixels border
			theRect=NSInsetRect(theRect, 2.0, 0.0);
			break;
		case NSThickSquareBezelStyle:		// 3 px
			theRect=NSInsetRect(theRect, 3.0, 0.0);
			break;
		case NSThickerSquareBezelStyle:		// 4 px
			theRect=NSInsetRect(theRect, 4.0, 0.0);
			break;
			// FIXME:
		default:
			break;
	}
	return theRect;
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
#if 0
	if([_title isEqualToString:@"Toolbar"])
		NSLog(@"drawing %@", _title);
#endif
	if(stateOrHighlight(NSChangeGrayCellMask | NSChangeBackgroundCellMask))
		backgroundColor = [NSColor whiteColor];		// FIXME: make background white or light grey dependent on highlight
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
				if(_c.highlighted != ([_keyEquivalent isEqualToString:@"\r"] || [_keyEquivalent isEqualToString:@"\n"]) && [[controlView window] isKeyWindow])
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
				NSRect round=NSInsetRect(cellFrame, 1, 1);	// make smaller so that it does not touch frame
				ctxt=[NSGraphicsContext currentContext];
				round.origin.x=0.5*(round.size.width-round.size.height);
				round.size.width=round.size.height;
				bezel=[NSBezierPath bezierPathWithOvalInRect:round];	// make a centered circle
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
			//	NSSize size;
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
			NSLog(@"NSButtonCell (%@) unknown bezelStyle:%lu", _title, (unsigned long)_bezelStyle);
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
		op = NSCompositeSourceOver;	// NSCompositeHighlight;	// change background
	else
		op = NSCompositeSourceOver;	// default composition
	if([img isKindOfClass:[NSButtonImageSource class]])
		img=[(NSButtonImageSource *) img buttonImageForCell:self];	// substitute
	// all this should be moved to -imageRectForBounds
	imageSize = [img size];
	if(_d.imageScaling != NSImageScaleNone)
			{
				NSSize isz;
				switch(_d.controlSize)
					{
						default:
						case NSRegularControlSize:
							isz=NSMakeSize(18.0, 18.0);
							break;
						case NSSmallControlSize:
							isz=NSMakeSize(13.0, 13.0);
							break;
						case NSMiniControlSize:
							isz=NSMakeSize(10.0, 10.0);
							break;
					}
				if(_d.imageScaling == NSImageScaleAxesIndependently)
					imageSize=isz;
				else
						{ // proportionally
							float factor=MIN(isz.width/imageSize.width, isz.height/imageSize.height);
							if(_d.imageScaling != NSImageScaleProportionallyDown || factor < 1.0)
									{ // scale image
										imageSize.width*=factor;
										imageSize.height*=factor;
									}
						}
//				[img setScalesWhenResized:YES];
//				[img setSize:imageSize];	// rescale
			}
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
			case NSImageAbove:						 		// draw image above the title
				if(![controlView isFlipped])
						{
							cellFrame.origin.x += (NSWidth(cellFrame) - imageSize.width)/2;
							cellFrame.origin.y += (NSHeight(cellFrame) - imageSize.height) - 4;
						}
				else
						{
							cellFrame.origin.x += (NSWidth(cellFrame) - imageSize.width)/2;
							cellFrame.origin.y += 4;
						}
				break;
			case NSImageBelow:								// draw image below the title
				if(![controlView isFlipped])
						{
							cellFrame.origin.x += (NSWidth(cellFrame) - imageSize.width)/2;
							cellFrame.origin.y += 4;
						}
				else
						{
							cellFrame.origin.x += (NSWidth(cellFrame) - imageSize.width)/2;
							cellFrame.origin.y += (NSHeight(cellFrame) - imageSize.height) - 4;
						}
				break;
		}
	if(stateOrHighlight(NSPushInCellMask))
		{ // makes button appear pushed in by moving the image by one pixel
		cellFrame.origin.x += 1;
		cellFrame.origin.y += 1;
		}
//	if([controlView isFlipped])
//		cellFrame.origin.y += imageSize.height;
#if 0
	NSLog(@"drawImage: %@ at %@", img, NSStringFromPoint(cellFrame.origin));
#endif
	[img drawInRect:(NSRect){ cellFrame.origin, imageSize } fromRect:NSZeroRect operation:op fraction:(_c.highlighted?0.6:(!_dimsWhenDisabled || _c.enabled?1.0:0.5))];
//	[img compositeToPoint:cellFrame.origin operation:op fraction:(_c.highlighted?0.6:(!_dimsWhenDisabled || _c.enabled?1.0:0.5))];	
}

- (void) drawTitle:(NSAttributedString *) title withFrame:(NSRect) cellFrame inView:(NSView *) controlView;
{ // this is an inofficial method! And, the title can also be an NSString
	NSColor *titleColor = [NSColor controlTextColor];	// default
	NSRect textFrame;
	id savedContents;
#if 0
	if([title isEqualToString:@"mini"])
		NSLog(@"mini");
#endif
	if(!title || _c.imagePosition == NSImageOnly)
		return;	// don't draw title
	if(stateOrHighlight(NSChangeGrayCellMask)) 
		{ // change text color when highlighting
		titleColor=[NSColor selectedControlTextColor];
		}
	if(stateOrHighlight(NSPushInCellMask))
		{ // make button appear pushed in (move text down one pixel?)
		  // might have to depend on bezel style
		}
	cellFrame=[self titleRectForBounds:cellFrame];
	_d.verticallyCentered=YES;	// default is vertically centered within its box
	textFrame=cellFrame;
	if(_image && !(_c.imagePosition == NSNoImage || _c.imagePosition == NSImageOverlaps))
		{ // adjust text field position for image
			// FIXME: determine text size and position independently of image size!
			// and draw title either at bottom or top or left or right border
			// needed for properly drawing Toolbar buttons
		NSSize imageSize;
		if([_image isKindOfClass:[NSButtonImageSource class]])
			_image=[(NSButtonImageSource *) _image buttonImageForCell:self];	// substitute
		imageSize=[_image size];
		switch(_c.imagePosition) 
			{												
			case NSImageLeft:					 			// draw title to the right of image
				textFrame.origin.x+=imageSize.width+8;
				textFrame.size.width-=imageSize.width+8;
				break;
			case NSImageRight:					 			// draw title to the left of the image
				textFrame.origin.x+=4;
				textFrame.size.width-=imageSize.width+8;
				break;
			case NSImageAbove:						 		// draw title below the image
					[self setAlignment:NSCenterTextAlignment];
					_d.verticallyCentered=NO;
					if(![controlView isFlipped])
							{
								textFrame.origin.y += 4;
								textFrame.size.height-=imageSize.height+8;
							}
					else
							{
								textFrame.origin.y += imageSize.height+4;
								textFrame.size.height-=imageSize.height+8;
							}
				break;
			case NSImageBelow:								// draw title above the image
					[self setAlignment:NSCenterTextAlignment];
				_d.verticallyCentered=NO;
					if(![controlView isFlipped])
							{
								textFrame.origin.y += imageSize.height+4;
								textFrame.size.height-=imageSize.height+8;
							}
					else
							{
								textFrame.origin.y += 4;
								textFrame.size.height-=imageSize.height+8;
							}
				break;
			default:
				break;
			}
		}
	savedContents=_contents;	// FIXME: do we really need to save? We don't use it otherwise
	[_attribs setObject:titleColor forKey:NSForegroundColorAttributeName];	// change color as needed
	/* NOTE:
		this code will also work if title is a NSString or an NSAttributedString or if a NSFormatter is attached
		i.e. we can easily implement attributedTitle, attributedAlternateTitle etc.
		*/
	if((_bezelStyle&15) == NSHelpButtonBezelStyle)
		{
		_contents=@"?";	// could be an NSAttributedString
#if 0
		NSLog(@"button alignment %d", [self alignment]);
#endif
		}
	else
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
#if 0
	NSLog(@"normimage=%@", _normalImage);
	NSLog(@"altimage=%@", _alternateImage);
#endif
	if(_c.state == NSMixedState && _mixedImage)
		_image=_mixedImage;
	else if(_alternateImage && stateOrHighlight(NSContentsCellMask))	// alternate content
		_image=_alternateImage;
	else
		_image=_normalImage;	// default image
#if 0
	NSLog(@"draw image %@", _image);
#endif
	[self drawImage:_image withFrame:cellFrame inView:controlView];
	if(_c.imagePosition == NSImageOnly)
		return;
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
		NSUInteger buttonflags=[aDecoder decodeIntForKey:@"NSButtonFlags"];
		NSUInteger buttonflags2=[aDecoder decodeIntForKey:@"NSButtonFlags2"];
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

#define KEYEQUIVALENTMASK ((buttonflags2>>8)&0x00ff)
		_keyEquivalentModifierMask = KEYEQUIVALENTMASK;	// if encoded by flags
#define BORDERWHILEMOUSEINSIDE ((buttonflags2&0x00000010)!=0)
#define BEZELSTYLE (((buttonflags2&(7<<0))>>0)+((buttonflags2&(8<<2))>>2))
		_bezelStyle=BEZELSTYLE;
		
		ASSIGN(_alternateTitle, [aDecoder decodeObjectForKey:@"NSAlternateContents"]);
		ASSIGN(_normalImage, [aDecoder decodeObjectForKey:@"NSNormalImage"]);
		ASSIGN(_alternateImage, [aDecoder decodeObjectForKey:@"NSAlternateImage"]);
		if([_alternateImage isKindOfClass:[NSFont class]])
			{ // bug (or feature?) in IB archiver
			[self setFont:(NSFont *)_alternateImage];
#if 0
			NSLog(@"strange NSAlternateImage %@", _alternateImage);
#endif
			[_alternateImage release], _alternateImage=nil;
			}
		if([_normalImage isKindOfClass:[NSFont class]])
			{
			[self setFont:(NSFont *)_alternateImage];
#if 0
			NSLog(@"strange NSNormalImage %@", _normalImage);
#endif
			[_normalImage release], _normalImage=nil;
			}
		if([_alternateImage isKindOfClass:[NSButtonImageSource class]] || (!_normalImage && _alternateImage))
			{ // no (relevant) normal image but alternate
#if 0
			NSLog(@"no NSNormalImage %@ substituting alternate %@", _normalImage, _alternateImage);
#endif
			ASSIGN(_normalImage, _alternateImage), [_alternateImage release], _alternateImage=nil;
			}
		if(_normalImage)
			{ // try to deduce the button type from the image name
				NSString *name;
#if 0
				NSLog(@"normalImage=%@", _normalImage);
#endif
				name=[_normalImage name];
				if([name isEqualToString:@"NSRadioButton"])
					_buttonType=NSRadioButton, _d.imageScaling=NSImageScaleProportionallyDown;
				else if([name isEqualToString:@"NSSwitch"])
					_buttonType=NSSwitchButton, _d.imageScaling=NSImageScaleProportionallyDown;
			}
		ASSIGN(_keyEquivalent, [aDecoder decodeObjectForKey:@"NSKeyEquivalent"]);
		if([aDecoder containsValueForKey:@"NSKeyEquiv"])
			ASSIGN(_keyEquivalent, [aDecoder decodeObjectForKey:@"NSKeyEquiv"]);
		if([aDecoder containsValueForKey:@"NSKeyEquivModMask"])
			_keyEquivalentModifierMask = [aDecoder decodeIntForKey:@"NSKeyEquivModMask"];
		if([aDecoder containsValueForKey:@"NSAttributedTitle"])
			[self setAttributedTitle:[aDecoder decodeObjectForKey:@"NSAttributedTitle"]];	// overwrite
		_periodicDelay = 0.001*[aDecoder decodeIntForKey:@"NSPeriodicDelay"];
		_periodicInterval = 0.001*[aDecoder decodeIntForKey:@"NSPeriodicInterval"];
#if 0
		NSLog(@"initWithCoder final: %@", self);
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
	else
		{
		_alternateTitle = [[aDecoder decodeObject] retain];
		_alternateImage = [[aDecoder decodeObject] retain];
		_normalImage = [[aDecoder decodeObject] retain];
		[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_transparent];
		}
	
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

- (void) setState:(NSInteger)value			{ [_cell setState:value]; [self setNeedsDisplay:YES]; }
- (void) setNextState					{ [_cell setNextState]; [self setNeedsDisplay:YES]; }
- (void) setIntValue:(int)anInt			{ [_cell setIntValue:anInt]; }
- (void) setFloatValue:(float)aFloat	{ [_cell setFloatValue:aFloat]; }
- (void) setDoubleValue:(double)aDouble	{ [_cell setDoubleValue:aDouble]; }
- (void) setObjectValue:(id <NSCopying>)val	{ [_cell setObjectValue:val]; }
- (NSInteger) state							{ return [_cell state]; }
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
	[self setNeedsDisplay:YES];
}

- (void) setBordered:(BOOL)flag
{
	[_cell setBordered:flag];	// has a different interpretation in button cells than in NSCell
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
	[_cell highlight:flag withFrame:_bounds inView:self];
}

- (void) setKeyEquivalent:(NSString*)aKeyEquivalent			// Key Equivalent
{
	[_cell setKeyEquivalent: aKeyEquivalent];
}

- (NSUInteger) keyEquivalentModifierMask
{
	return [_cell keyEquivalentModifierMask];
}

- (void) setKeyEquivalentModifierMask:(NSUInteger)mask
{
	[_cell setKeyEquivalentModifierMask: mask];
}

- (BOOL) acceptsFirstResponder
{														
	return [super acceptsFirstResponder] || ([self keyEquivalent] != nil);				
}														

- (void) keyDown:(NSEvent*)event
{
	// CHECKME - is this reasonable behaviour?
	if(([self isEnabled] && [event keyCode] == ' '))	// Space
		[self performClick: self];
	else
		[super keyDown: event];
}

// NOTE: already defined in NSControl...
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
		NSUInteger modifiers=[anEvent modifierFlags] & (NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask | NSShiftKeyMask);

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
- (id) initWithCoder:(NSCoder *) aDecoder		{ return [super initWithCoder:aDecoder]; }

@end /* NSButton */
