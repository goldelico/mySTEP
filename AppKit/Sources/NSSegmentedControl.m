/* 
 NSSegmentedControl.m
 
 Text field control and cell classes
 
 Author:  Nikolaus Schaller <hns@computer.org>
 Date:    April 2006
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>

#import <AppKit/NSSegmentedCell.h>
#import <AppKit/NSSegmentedControl.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSBezierPath.h>

#import "NSAppKitPrivate.h"

// internal class

@interface NSSegmentItem : NSObject
{
	NSString *_label;
	NSString *_tooltip;
	NSImage *_image;
	NSMenu *_menu;
	float _width;
	int _tag;
	BOOL _enabled;
	BOOL _highlighted;
	BOOL _selected;
}
- (NSString *) label;
- (NSString *) tooltip;
- (NSImage *) image;
- (NSMenu *) menu;
- (float) width;
- (float) autoWidth;
- (int) tag;
- (BOOL) enabled;
- (BOOL) highlighted;
- (BOOL) selected;
- (void) setLabel:(NSString *) label;
- (void) setTooltip:(NSString *) tooltip;
- (void) setImage:(NSImage *) image;
- (void) setMenu:(NSMenu *) menu;
- (void) setWidth:(float) width;		// 0.0 = autosize
- (void) setTag:(int) tag;
- (void) setEnabled:(BOOL) enabled;
- (void) setHighlighted:(BOOL) selected;
- (void) setSelected:(BOOL) selected;
@end

@implementation NSSegmentItem

- (id) init;
{
	if((self=[super init]))
		{
		_enabled=YES;	// default
		}
	return self;
}

- (void) dealloc;
{
	[_label release];
	[_tooltip release];
	[_image release];
	[_menu release];
	[super dealloc];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"NSSegmentItem:%@ tag=%d image=%@ menu=%@ tooltip=%@ enabled=%d highlighted=%d selected=%d",
		_label,
		_tag,
		_image,
		_menu,
		_tooltip,
		_enabled,
		_highlighted,
		_selected];
}

- (NSString *) label; { return _label; }
- (NSString *) tooltip; { return _tooltip; }
- (NSImage *) image; { return _image; }
- (NSMenu *) menu; { return _menu; }
- (float) width; { return _width; }
- (int) tag; { return _tag; }
- (BOOL) enabled; { return _enabled; }
- (BOOL) highlighted; { return _highlighted; }
- (BOOL) selected; { return _selected; }

- (float) autoWidth;
{
	if(_width == 0.0 && _label)
		return [_label sizeWithAttributes:nil].width+4.0;
	return _width;
}

- (void) setLabel:(NSString *) label; { ASSIGN(_label, label); }
- (void) setTooltip:(NSString *) tooltip; { ASSIGN(_tooltip, tooltip); }
- (void) setImage:(NSImage *) image; { ASSIGN(_image, image); }
- (void) setMenu:(NSMenu *) menu; { ASSIGN(_menu, menu); }
- (void) setWidth:(float) width; { _width=width; }
- (void) setTag:(int) tag; { _tag=tag; }
- (void) setEnabled:(BOOL) enabled; { _enabled=enabled; }
- (void) setHighlighted:(BOOL) flag; { _highlighted=flag; }
- (void) setSelected:(BOOL) selected; { _selected=selected; }

- (void) encodeWithCoder:(NSCoder *) aCoder
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	if(![aDecoder allowsKeyedCoding])
		{ [self release]; return nil; }
	_label = [[aDecoder decodeObjectForKey:@"NSSegmentItemLabel"] retain];
	_image = [[aDecoder decodeObjectForKey:@"NSSegmentItemImage"] retain];
	_menu = [[aDecoder decodeObjectForKey:@"NSSegmentItemMenu"] retain];
	// NSSegmentItemImageScaling
	if([aDecoder containsValueForKey:@"NSSegmentItemEnabled"])
		_enabled = [aDecoder decodeBoolForKey:@"NSSegmentItemEnabled"];
	else
		_enabled=YES;	// default
	if([aDecoder decodeBoolForKey:@"NSSegmentItemDisabled"])
		_enabled=NO;	// override
	_selected = [aDecoder decodeBoolForKey:@"NSSegmentItemSelected"];
	_width = [aDecoder decodeFloatForKey:@"NSSegmentItemWidth"];
	_tag = [aDecoder decodeIntForKey:@"NSSegmentItemTag"];
	// etc.
#if 0
	NSLog(@"initWithCoder: %@", self);
#endif
	return self;
}

@end

@implementation NSSegmentedCell

- (id) initTextCell:(NSString *)aString
{
	if((self=[super initTextCell:aString]))
		{
			[self setAlignment:NSCenterTextAlignment];
			_segments=[[NSMutableArray alloc] initWithCapacity:10];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSSegmentedCell *c = [super copyWithZone:zone];
	if(c)
		{
		c->_mode=_mode;
//	c->_count=_count;
//	c->_capacity=_capacity;
		// copy entries?
		}
	return c;
}

- (void) dealloc;
{
	[_segments release];
	[super dealloc];
}

- (NSSize) cellSize;
{
	// sum up all widths and use default height for controlSize
	NIMP; return NSZeroSize;
}

- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView*) controlView
{
	unsigned int i=0, count=[_segments count];
	NSRect frame=cellFrame;
	// should we set any clipping?
	while(i < count && frame.origin.x < cellFrame.size.width)
		{ // there is still room for a segment
		frame.size.width=[[_segments objectAtIndex:i] autoWidth];
		[self drawSegment:i inFrame:frame withView:controlView];
		frame.origin.x+=frame.size.width;
		i++;
		}
}

- (void) drawInteriorWithFrame:(NSRect)frame inView:(NSView*)controlView
{ // we can't use this method since we can't distingush between interior and exterior
}

- (void) drawSegment:(int) i inFrame:(NSRect) frame withView:(NSView *) controlView;
{
	NSSegmentItem *s=[_segments objectAtIndex:i];
	int border=(i==0?1:0)+(i==[_segments count]-1?2:0);
	NSImage *img;
	_c.enabled=[s enabled];	// copy status of current cell
	[NSBezierPath _drawRoundedBezel:border inFrame:frame enabled:(_c.enabled && [(NSSegmentedControl *) controlView isEnabled]) selected:[s selected] highlighted:(_c.highlighted && [s highlighted]) radius:5.0];
	if((img=[s image]))
		{ // composite segment image
		[img drawAtPoint:frame.origin fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
		}
	_contents=[s label];
	[super drawInteriorWithFrame:frame inView:controlView];	// use NSCell's drawing method for this segment
}

- (BOOL) trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{ // check to which subcell we have to forward tracking
	NSPoint loc=[event locationInWindow];
	NSRect frame=cellFrame;
	unsigned int count=[_segments count];
	loc = [controlView convertPoint:loc fromView:nil];
#if 1
	NSLog(@"NSSegmentedCell trackMouse:%@ inRect:%@", NSStringFromPoint(loc), NSStringFromRect(cellFrame));
#endif
	if(_trackedSegment < [_segments count])
		{
		[[_segments objectAtIndex:_trackedSegment] setHighlighted:NO];	// remove highlighting
		[controlView setNeedsDisplayInRect:cellFrame];		// could be restriced to highlighting position
		}
	_trackedSegment=0;
	while(_trackedSegment < count && frame.origin.x < cellFrame.size.width)
		{ // there is still room for a segment
		frame.size.width=[[_segments objectAtIndex:_trackedSegment] autoWidth];
		if(NSMouseInRect(loc, frame, NO))
			{
#if 1
			NSLog(@"mouse is in segment %d", _trackedSegment);
#endif
			[[_segments objectAtIndex:_trackedSegment] setHighlighted:YES];	// set highlighting
			[controlView setNeedsDisplayInRect:cellFrame];		// could be restriced to highlighting position
			break;
			}
		frame.origin.x+=frame.size.width;
		_trackedSegment++;
		}
 	return [super trackMouse:event inRect:frame ofView:controlView untilMouseUp:untilMouseUp];	// track while in this segment
}

- (void) stopTracking:(NSPoint) lastPoint at:(NSPoint) stopPoint inView:(NSView *) controlView mouseIsUp:(BOOL) flag
{
	if(_trackedSegment < [_segments count])
		[[_segments objectAtIndex:_trackedSegment] setHighlighted:NO];	// remove highlighting
	if(flag && [self isEnabledForSegment:_trackedSegment])
		{ // make the segment where the mouse did go up the selected segment
		[self setSelectedSegment:_trackedSegment];
		}
}

- (NSImage *) imageForSegment:(int) segment; { return [[_segments objectAtIndex:segment] image]; }
- (BOOL) isEnabledForSegment:(int) segment; { return [[_segments objectAtIndex:segment] enabled]; }
- (BOOL) isSelectedForSegment:(int) segment; { return [[_segments objectAtIndex:segment] selected]; }
- (NSString *) labelForSegment:(int) segment; { return [[_segments objectAtIndex:segment] label]; }

- (void) makeNextSegmentKey;
{
	NIMP;
}

- (void) makePreviousSegmentKey;
{
	NIMP;
}

- (NSMenu *) menuForSegment:(int) segment; { return [[_segments objectAtIndex:segment] menu]; }
- (int) segmentCount; { return [_segments count]; }
- (int) selectedSegment;
{
	unsigned int i, count=[_segments count];
	for(i=0; i<count; i++)
		if([self isSelectedForSegment:i])
			return i;
	return -1;
}

- (BOOL) selectSegmentWithTag:(int) t;
{
	unsigned int i, count=[_segments count];
	for(i=0; i<count; i++)
		{
		if([[_segments objectAtIndex:i] tag] == t)
			{ // found
			[self setSelectedSegment:i];
			return YES;
			}
		}
	return NO;
}

- (void) setEnabled:(BOOL) flag forSegment:(int) segment; { [[_segments objectAtIndex:segment] setEnabled:flag]; }
- (void) setImage:(NSImage *) image forSegment:(int) segment; { [[_segments objectAtIndex:segment] setImage:image]; }
- (void) setLabel:(NSString *) label forSegment:(int) segment; { [[_segments objectAtIndex:segment] setLabel:label]; }
- (void) setMenu:(NSMenu *) menu forSegment:(int) segment; { [[_segments objectAtIndex:segment] setMenu:menu]; }

- (void) setSegmentCount:(int) count;
{ // limited to 2049?
	if(count < [_segments count])
		[_segments removeObjectsInRange:NSMakeRange(count, [_segments count]-count)];
	while(count > [_segments count])
		{
		NSSegmentItem *s=[NSSegmentItem new];	// create empty item
		[_segments addObject:s];
		[s release];
		}
}

- (void) setSelected:(BOOL) flag forSegment:(int) segment;
{
	[[_segments objectAtIndex:segment] setSelected:flag];
}

- (void) setSelectedSegment:(int) segment;
{
	int lastSelected=[self selectedSegment];
	if(segment == lastSelected)
		return;	// unchanged
	if(_mode != NSSegmentSwitchTrackingSelectAny && lastSelected >= 0)
		[self setSelected:NO forSegment:lastSelected];
	if(segment >= 0 && segment < [self segmentCount])
		[self setSelected:YES forSegment:segment];
}

- (void) setTag:(int) t forSegment:(int) segment; { [[_segments objectAtIndex:segment] setTag:t]; }
- (void) setToolTip:(NSString *) tooltip forSegment:(int) segment; { [[_segments objectAtIndex:segment] setTooltip:tooltip]; }
- (void) setTrackingMode:(NSSegmentSwitchTracking) mode; { _mode=mode; }
- (void) setWidth:(float) width forSegment:(int) segment; { [[_segments objectAtIndex:segment] setWidth:width]; }
- (int) tagForSegment:(int) segment; { return [[_segments objectAtIndex:segment] tag]; }
- (NSString *) toolTipForSegment:(int) segment; { return [[_segments objectAtIndex:segment] tooltip]; }
- (NSSegmentSwitchTracking) trackingMode; { return _mode; }
- (float) widthForSegment:(int) segment; { return [[_segments objectAtIndex:segment] width]; }

- (void) encodeWithCoder:(NSCoder *) aCoder
{
	[super encodeWithCoder:aCoder];
	NIMP;
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	unsigned int count;
	self=[super initWithCoder:aDecoder];
	if(![aDecoder allowsKeyedCoding])
		{ [self release]; return nil; }
	_c.enabled=YES;
	[self setAlignment:NSCenterTextAlignment];
	_segments = [[aDecoder decodeObjectForKey:@"NSSegmentImages"] retain];	// array of segments
	count=[_segments count];
	return self;
}

@end

@implementation NSSegmentedControl

- (NSImage *) imageForSegment:(int) segment; { return [_cell imageForSegment:segment]; }
- (BOOL) isEnabledForSegment:(int) segment; { return [_cell isEnabledForSegment:segment]; }
- (BOOL) isSelectedForSegment:(int) segment; { return [_cell isSelectedForSegment:segment]; }
- (NSString *) labelForSegment:(int) segment; { return [_cell labelForSegment:segment]; }
- (NSMenu *) menuForSegment:(int) segment; { return [_cell menuForSegment:segment]; }
- (int) segmentCount; { return [_cell segmentCount]; }
- (int) selectedSegment; { return [_cell selectedSegment]; }
- (BOOL) selectSegmentWithTag:(int) tag; { return [_cell selectSegmentWithTag:tag]; }
- (void) setEnabled:(BOOL) flag forSegment:(int) segment; { return [_cell setEnabled:flag forSegment:segment]; }
- (void) setImage:(NSImage *) image forSegment:(int) segment; { return [_cell setImage:image forSegment:segment]; }
- (void) setLabel:(NSString *) label forSegment:(int) segment; { return [_cell setLabel:label forSegment:segment]; }
- (void) setMenu:(NSMenu *) menu forSegment:(int) segment; { return [_cell setMenu:menu forSegment:segment]; }
- (void) setSegmentCount:(int) count; { return [_cell setSegmentCount:count]; }
- (void) setSelected:(BOOL) flag forSegment:(int) segment; { return [_cell setSelected:flag forSegment:segment]; }
- (void) setSelectedSegment:(int) selectedSegment; { return [_cell setSelectedSegment:selectedSegment]; }
- (void) setWidth:(float) width forSegment:(int) segment; { return [_cell setWidth:width forSegment:segment]; }
- (float) widthForSegment:(int) segment; { return [_cell widthForSegment:segment]; }

- (void) encodeWithCoder:(NSCoder *) aCoder
{
	[super encodeWithCoder:aCoder];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	return [super initWithCoder:aDecoder];	// NSControl
}

@end

