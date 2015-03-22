//
//  NSTextTable.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import "AppKit/AppKit.h"

@implementation NSTextBlock

- (void) dealloc; 
{
	int i;
	[_backgroundColor release];
	for(i=0; i<=NSMaxYEdge; i++)
		[_borderColorForEdge[i] release];
	[super dealloc];
}

/* this function is optimized so that the compiler can highly optimize if layer and edge are constants */
 
static inline CGFloat getWidth(NSTextBlock *self, NSTextBlockLayer layer, NSRectEdge edge, NSSize size)
{
	if(self->_widthType[layer-NSTextBlockPadding][edge] == NSTextBlockPercentageValueType)
		{ // relative to size
		if(edge == NSMinXEdge || edge == NSMaxXEdge)
			return self->_width[layer-NSTextBlockPadding][edge]*size.width;
		else
			return self->_width[layer-NSTextBlockPadding][edge]*size.height;
		}
	return self->_width[layer-NSTextBlockPadding][edge];	// absolute
}

- (NSColor *) backgroundColor; { return _backgroundColor; }
- (NSColor *) borderColorForEdge:(NSRectEdge) edge; { NSAssert(edge <= NSMaxYEdge, @"invalid edge"); return _borderColorForEdge[edge]; }

- (NSRect) boundsRectForContentRect:(NSRect) cont	/* content rectangle returned by rectForLayoutAtPoint: */
							 inRect:(NSRect) rect	/* text container rectangle */
					  textContainer:(NSTextContainer *) container
					 characterRange:(NSRange) range;
{ // called once per layout action (after rectForLayoutAtPoint:) by -[NSTypeSetter layoutCharactersInRange:forLayoutManager:maximumNumberOfLineFragments:]
	CGFloat d;	// delta
	d	= getWidth(self, NSTextBlockPadding, NSMinXEdge, rect.size)		// defines space between border and content
		+ getWidth(self, NSTextBlockBorder, NSMinXEdge, rect.size)	// defines border width
		+ getWidth(self, NSTextBlockMargin, NSMinXEdge, rect.size);	// inset where border starts
	cont.origin.x -= d;
	cont.size.width += d
		+ getWidth(self, NSTextBlockPadding, NSMaxXEdge, rect.size)
		+ getWidth(self, NSTextBlockBorder, NSMaxXEdge, rect.size)
		+ getWidth(self, NSTextBlockMargin, NSMaxXEdge, rect.size);
	d	= getWidth(self, NSTextBlockPadding, NSMinYEdge, rect.size)		// defines space between border and content
		+ getWidth(self, NSTextBlockBorder, NSMinYEdge, rect.size)	// defines border width
		+ getWidth(self, NSTextBlockMargin, NSMinYEdge, rect.size);	// inset where border starts
	cont.origin.y -= d;
	cont.size.height += d
		+ getWidth(self, NSTextBlockPadding, NSMaxYEdge, rect.size)
		+ getWidth(self, NSTextBlockBorder, NSMaxYEdge, rect.size)
		+ getWidth(self, NSTextBlockMargin, NSMaxYEdge, rect.size);
	return cont;
}

- (CGFloat) contentWidth; { return _contentWidth; }
- (NSTextBlockValueType) contentWidthValueType; { return _contentWidthValueType; }

- (void) drawBackgroundWithFrame:(NSRect) rect
						  inView:(NSView *) view
				  characterRange:(NSRange) range
				   layoutManager:(NSLayoutManager *) lm;
{ // called from -[NSLayoutManager drawBackgroundForGlyphRange:atPoint:]
	NSBezierPath *p;
	NSColor *color;
	CGFloat width;
	NSRect outer, inner;	// outer box and inner box of border
	outer=rect;
	width=getWidth(self, NSTextBlockPadding, NSMinXEdge, rect.size);
	outer.origin.x+=width;
	outer.size.width-=width + getWidth(self, NSTextBlockPadding, NSMaxXEdge, rect.size);
	width=getWidth(self, NSTextBlockPadding, NSMinYEdge, rect.size);
	outer.origin.y+=width;
	outer.size.height-=width + getWidth(self, NSTextBlockPadding, NSMaxYEdge, rect.size);
	inner=outer;
	width=getWidth(self, NSTextBlockBorder, NSMinXEdge, rect.size);
	inner.origin.x+=width;
	inner.size.width-=width + getWidth(self, NSTextBlockBorder, NSMaxXEdge, rect.size);
	width=getWidth(self, NSTextBlockBorder, NSMinYEdge, rect.size);
	inner.origin.y+=width;
	inner.size.height-=width + getWidth(self, NSTextBlockBorder, NSMaxYEdge, rect.size);
	color=[self borderColorForEdge:NSMinXEdge];
	if(color)
		{ // left
		p=[NSBezierPath new];
		[p moveToPoint:(NSPoint) { NSMinX(outer), NSMinY(outer) }];
		[p lineToPoint:(NSPoint) { NSMinX(inner), NSMinY(inner) }];
		[p lineToPoint:(NSPoint) { NSMinX(inner), NSMaxY(inner) }];
		[p lineToPoint:(NSPoint) { NSMinX(outer), NSMaxY(outer) }];
		[p closePath];
		[color set];
		[p fill];	// fill left border trapezoid
		[p release];		
		}
	[[self borderColorForEdge:NSMaxXEdge] set];	// right
	color=[self borderColorForEdge:NSMaxXEdge];
	width=getWidth(self, NSTextBlockBorder, NSMaxXEdge, rect.size);	// border width
	if(color && width > 0)
		{ // right
		p=[NSBezierPath new];
			[p moveToPoint:(NSPoint) { NSMaxX(outer), NSMinY(outer) }];
			[p lineToPoint:(NSPoint) { NSMaxX(inner), NSMinY(inner) }];
			[p lineToPoint:(NSPoint) { NSMaxX(inner), NSMaxY(inner) }];
			[p lineToPoint:(NSPoint) { NSMaxX(outer), NSMaxY(outer) }];
			[p closePath];
		[color set];
		[p fill];	// fill right border trapezoid
		[p release];		
		}
	color=[self borderColorForEdge:NSMinYEdge];
	width=getWidth(self, NSTextBlockBorder, NSMinYEdge, rect.size);	// border width
	if(color && width > 0)
		{ // bottom
		p=[NSBezierPath new];
			[p moveToPoint:(NSPoint) { NSMinX(outer), NSMinY(outer) }];
			[p lineToPoint:(NSPoint) { NSMinX(inner), NSMinY(inner) }];
			[p lineToPoint:(NSPoint) { NSMaxX(inner), NSMinY(inner) }];
			[p lineToPoint:(NSPoint) { NSMaxX(outer), NSMinY(outer) }];
			[p closePath];
		[color set];
		[p fill];	// fill left border trapezoid
		[p release];		
		}
	[[self borderColorForEdge:NSMaxYEdge] set];	// right
	color=[self borderColorForEdge:NSMaxYEdge];
	width=getWidth(self, NSTextBlockBorder, NSMaxYEdge, rect.size);	// border width
	if(color && width > 0)
		{ // top
		p=[NSBezierPath new];
			[p moveToPoint:(NSPoint) { NSMinX(outer), NSMaxY(outer) }];
			[p lineToPoint:(NSPoint) { NSMinX(inner), NSMaxY(inner) }];
			[p lineToPoint:(NSPoint) { NSMaxX(inner), NSMaxY(inner) }];
			[p lineToPoint:(NSPoint) { NSMaxX(outer), NSMaxY(outer) }];
			[p closePath];
		[color set];
		[p fill];	// fill right border trapezoid
		[p release];		
		}
	[[self backgroundColor] set];
	NSRectFill(inner);	// fill background behind text
}

- (NSRect) rectForLayoutAtPoint:(NSPoint) point	/* relative position within text container rect */
						 inRect:(NSRect) rect	/* text container rect */
				  textContainer:(NSTextContainer *) cont
				 characterRange:(NSRange) range;
{ // called by -[NSTypeSetter getLineFragmentRect:(NSRectPointer)lineFragmentRect usedRect:(NSRectPointer)lineFragmentUsedRect remainingRect:(NSRectPointer)remainingRect forStartingGlyphAtIndex:(NSUInteger)startingGlyphIndex proposedRect:(NSRect)proposedRect lineSpacing:(CGFloat)lineSpacing paragraphSpacingBefore:(CGFloat)paragraphSpacingBefore paragraphSpacingAfter:(CGFloat)paragraphSpacingAfter]
	
	// we probably should determine recursively how much space we need
	// constrain rect.width by _contentWidth;
	// handle alignment if rect is larger than what we need
	// take the character range for the contents
	// rect.size is a little smaller than [cont containerSize] - maybe 2x rect.origin.y (was 5.0 in one example)
	NSLayoutManager *lm=[cont layoutManager];
	NSTextStorage *ts=[lm textStorage];
	NSAttributedString *contents = [ts attributedSubstringFromRange:range];
	NSRect r;

	CGFloat li, ri, ti, bi;	// inset from bounds to content
	li	= getWidth(self, NSTextBlockPadding, NSMinXEdge, rect.size)		// space between cells
		+ getWidth(self, NSTextBlockBorder, NSMinXEdge, rect.size)		// border width
		+ getWidth(self, NSTextBlockMargin, NSMinXEdge, rect.size);		// space (inset) between border and text
	ri	= getWidth(self, NSTextBlockPadding, NSMaxXEdge, rect.size)
		+ getWidth(self, NSTextBlockBorder, NSMaxXEdge, rect.size)
		+ getWidth(self, NSTextBlockMargin, NSMaxXEdge, rect.size);
	bi	= getWidth(self, NSTextBlockPadding, NSMinYEdge, rect.size)
		+ getWidth(self, NSTextBlockBorder, NSMinYEdge, rect.size)
		+ getWidth(self, NSTextBlockMargin, NSMinYEdge, rect.size);
	ti	= getWidth(self, NSTextBlockPadding, NSMaxYEdge, rect.size)
		+ getWidth(self, NSTextBlockBorder, NSMaxYEdge, rect.size)
		+ getWidth(self, NSTextBlockMargin, NSMaxYEdge, rect.size);
	
	// FIXME: do we do column breakdown and alignment here?
	
	// we should ask the layout manager!;
	// or how else does it depend on contents dimensions?
	
	// we may simply split the content rect by columns into cells

	r=[contents boundingRectWithSize:(NSSize) {	rect.size.width-li-ri, rect.size.height-ti-bi } options:0];
/// TEST: r.size.width=20;
	/// FIXME: contentWidth is 0.0 !?!
	CGFloat wmax=_contentWidthValueType == NSTextBlockPercentageValueType?_contentWidth*rect.size.width:_contentWidth;
//	if(r.size.width > wmax)
//		r.size.width=wmax;	// limit to content width
	r.origin.x+=rect.origin.x+point.x+li;
	r.origin.y+=rect.origin.y+point.y+ti;
	return r; 
}

- (void) setBackgroundColor:(NSColor *) color; { ASSIGN(_backgroundColor, color); }
- (void) setBorderColor:(NSColor *) color; { int i; for(i=0; i<=NSMaxYEdge; i++) ASSIGN(_borderColorForEdge[i], color); }
- (void) setBorderColor:(NSColor *) color forEdge:(NSRectEdge) edge; { NSAssert(edge <= NSMaxYEdge, @"invalid edge"); ASSIGN(_borderColorForEdge[edge], color); }
- (void) setContentWidth:(CGFloat) val type:(NSTextBlockValueType) type; { _contentWidth=val; _contentWidthValueType=type; }
- (void) setValue:(CGFloat) val type:(NSTextBlockValueType) type forDimension:(NSTextBlockDimension) dimension;
{
	NSAssert(dimension <= NSTextBlockMaximumHeight, @"invalid dimension");
	_value[dimension]=val;
	_valueType[dimension]=type;
}
- (void) setVerticalAlignment:(NSTextBlockVerticalAlignment) alignment; { _verticalAlignment=alignment; }
- (void) setWidth:(CGFloat) val type:(NSTextBlockValueType) type forLayer:(NSTextBlockLayer) layer;
{ // set width for all edges
	int i;
	// FIXME: don't use NSAssert but raise NSException!
	NSAssert(layer >= NSTextBlockPadding && layer <= NSTextBlockMargin, @"invalid layer");
	for(i=0; i<=NSMaxYEdge; i++)
		{
		_width[layer-NSTextBlockPadding][i]=val;
		_widthType[layer-NSTextBlockPadding][i]=type;
		}
}
- (void) setWidth:(CGFloat) val type:(NSTextBlockValueType) type forLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;
{
	NSAssert(layer >= NSTextBlockPadding && layer <= NSTextBlockMargin, @"invalid layer");
	NSAssert(edge <= NSMaxYEdge, @"invalid edge");
	_width[layer-NSTextBlockPadding][edge]=val;
	_widthType[layer-NSTextBlockPadding][edge]=type;
}
- (CGFloat) valueForDimension:(NSTextBlockDimension) dimension; { NSAssert(dimension <= NSTextBlockMaximumHeight, @"invalid dimension"); return _value[dimension]; }
- (NSTextBlockValueType) valueTypeForDimension:(NSTextBlockDimension) dimension; { NSAssert(dimension <= NSTextBlockMaximumHeight, @"invalid dimension"); return _valueType[dimension]; }
- (NSTextBlockVerticalAlignment) verticalAlignment; { return _verticalAlignment; }
- (CGFloat) widthForLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;
{
	NSAssert(layer >= NSTextBlockPadding && layer <= NSTextBlockMargin, @"invalid layer");
	NSAssert(edge <= NSMaxYEdge, @"invalid edge");
	return _width[layer-NSTextBlockPadding][edge];
}
- (NSTextBlockValueType) widthValueTypeForLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;
{
	NSAssert(layer >= NSTextBlockPadding && layer <= NSTextBlockMargin, @"invalid layer");
	NSAssert(edge <= NSMaxYEdge, @"invalid edge");
	return _widthType[layer-NSTextBlockPadding][edge];
}

- (void) encodeWithCoder:(NSCoder *)aCoder				// NSCoding protocol
{
	//	[super encodeWithCoder:aCoder];
	if([aCoder allowsKeyedCoding])
		{
		}
	else
		{
		}
	NIMP;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if([aDecoder allowsKeyedCoding])
		{
		}
	else
		{
		}
	return NIMP;
}

- (id) copyWithZone:(NSZone *) z
{
	return NIMP;
}

@end

@implementation NSTextTable

- (NSRect) boundsRectForBlock:(NSTextTableBlock *) block
				  contentRect:(NSRect) content
					   inRect:(NSRect)rect
				textContainer:(NSTextContainer *) container
			   characterRange:(NSRange) range; { NIMP; return NSZeroRect; }
- (BOOL) collapsesBorders; { return _collapsesBorders; }
- (void) drawBackgroundForBlock:(NSTextTableBlock *) block
					  withFrame:(NSRect) frame
						 inView:(NSView *) controlView
				 characterRange:(NSRange) range
				  layoutManager:(NSLayoutManager *) manager; { NIMP }
- (BOOL) hidesEmptyCells; { return _hidesEmptyCells; }
- (NSTextTableLayoutAlgorithm) layoutAlgorithm; { return _layoutAlgorithm; }
- (NSUInteger) numberOfColumns; { return _numberOfColumns; }
- (NSRect) rectForBlock:(NSTextTableBlock *) block
		  layoutAtPoint:(NSPoint) start
				 inRect:(NSRect) rect
		  textContainer:(NSTextContainer *) container
		 characterRange:(NSRange) range; { NIMP; return NSZeroRect; }
- (void) setCollapsesBorders:(BOOL) flag; { _collapsesBorders=flag; }
- (void) setHidesEmptyCells:(BOOL) flag; { _hidesEmptyCells=flag; }
- (void) setLayoutAlgorithm:(NSTextTableLayoutAlgorithm) algorithm; { _layoutAlgorithm=algorithm; }
- (void) setNumberOfColumns:(NSUInteger) n; { _numberOfColumns=n; }

@end

@implementation NSTextTableBlock

- (void) dealloc;
{
	[_table release];
	[super dealloc];
}

- (id) initWithTable:(NSTextTable *) table
		 startingRow:(NSInteger) row
			 rowSpan:(NSInteger) rspan
	  startingColumn:(NSInteger) col
		  columnSpan:(NSInteger) cspan;
{
	if((self=[super init]))
		{
		_table=[table retain];
		_row=row;
		_rspan=rspan;
		_col=col;
		_cspan=cspan;
		}
	return self;
}

/* FIXME:
 we may have to override
 
 - (NSRect) rectForLayoutAtPoint:(NSPoint) point
	inRect:(NSRect) rect	// text container rect
		textContainer:(NSTextContainer *) cont
	characterRange:(NSRange) range;
 
 and consult [table numberOfColumns]
 
 to determine the right position of the cells
 */


- (NSInteger) columnSpan; { return _cspan; }
- (NSInteger) rowSpan; { return _rspan; }
- (NSInteger) startingColumn; { return _col; }
- (NSInteger) startingRow; { return _row; }
- (NSTextTable *) table; { return _table; }

@end
