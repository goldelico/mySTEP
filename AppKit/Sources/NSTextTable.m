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

- (NSColor *) backgroundColor; { return _backgroundColor; }
- (NSColor *) borderColorForEdge:(NSRectEdge) edge; { NSAssert(edge <= NSMaxYEdge, @"invalid edge"); return _borderColorForEdge[edge]; }

- (NSRect) boundsRectForContentRect:(NSRect) cont
							 inRect:(NSRect) rect
					  textContainer:(NSTextContainer *) container
					 characterRange:(NSRange) range;
{
	// bounds may differ on left&right side
	// [self widthForLayer:NSTextBlockPadding edge:NSMinXEdge]; -- defines space between border and content
	// [self widthForLayer:NSTextBlockBorder edge:NSMinXEdge]; -- defines border width
	// [self widthForLayer:NSTextBlockMargin edge:NSMinXEdge]; -- inset where border starts
	cont=NSInsetRect(cont, -5.0, -5.0);	// add margins
	return cont;
}

- (float) contentWidth; { return _contentWidth; }
- (NSTextBlockValueType) contentWidthValueType; { return _contentWidthValueType; }

- (void) drawBackgroundWithFrame:(NSRect) rect
						  inView:(NSView *) view
				  characterRange:(NSRange) range
				   layoutManager:(NSLayoutManager *) lm;
{
	[[self backgroundColor] set];
	NSRectFill(rect);	// fill complete background
	[[self borderColorForEdge:NSMinXEdge] set];
	// define trapezoid by:
	// [self widthForLayer:NSTextBlockBorder edge:NSMinXEdge]; -- defines border width
	// [self widthForLayer:NSTextBlockMargin edge:NSMinXEdge]; -- inset where border starts
	// fill left border trapezoid
	[[self borderColorForEdge:NSMaxXEdge] set];
	// fill right border trapezoid
	[[self borderColorForEdge:NSMinYEdge] set];
	// fill bottom border trapezoid
	[[self borderColorForEdge:NSMaxYEdge] set];
	// fill bottom border trapezoid	
}

- (NSRect) rectForLayoutAtPoint:(NSPoint) point
						 inRect:(NSRect) rect
				  textContainer:(NSTextContainer *) cont
				 characterRange:(NSRange) range;
{
	// called by -[NSTypeSetter getLineFragmentRect:(NSRectPointer)lineFragmentRect usedRect:(NSRectPointer)lineFragmentUsedRect remainingRect:(NSRectPointer)remainingRect forStartingGlyphAtIndex:(NSUInteger)startingGlyphIndex proposedRect:(NSRect)proposedRect lineSpacing:(CGFloat)lineSpacing paragraphSpacingBefore:(CGFloat)paragraphSpacingBefore paragraphSpacingAfter:(CGFloat)paragraphSpacingAfter]
	
	// we probably should determine recursively how much space we need
	// constrain rect.width by _contentWidth;
	// handle alignment if rect is larger than what we need
	// take the character range for the contents
	// rect.size is a little smaller than [cont containerSize] - maybe 2x rect.origin.y (was 5.0 in one example)
	NSLayoutManager *lm=[cont layoutManager];
	NSTextStorage *ts=[lm textStorage];
	NSAttributedString *contents = [ts attributedSubstringFromRange:range];
	
	// FIXME: do we do column breakdown and alignment here?
	
	// we should ask the layout manager!;
	// or how else does it depend on contents dimensions?
	NSRect r=[contents boundingRectWithSize:rect.size options:0];
	float wmax=_contentWidthValueType == NSTextBlockPercentageValueType?_contentWidth*rect.size.width:_contentWidth;
	if(r.size.width > wmax)
		r.size.width=wmax;	// limit to content width
	r.origin.x+=point.x;
	r.origin.y+=point.y;
	return r; 
}

- (void) setBackgroundColor:(NSColor *) color; { ASSIGN(_backgroundColor, color); }
- (void) setBorderColor:(NSColor *) color; { int i; for(i=0; i<=NSMaxYEdge; i++)  ASSIGN(_borderColorForEdge[i], color); }
- (void) setBorderColor:(NSColor *) color forEdge:(NSRectEdge) edge; { NSAssert(edge <= NSMaxYEdge, @"invalid edge"); ASSIGN(_borderColorForEdge[edge], color); }
- (void) setContentWidth:(float) val type:(NSTextBlockValueType) type; { _contentWidth=val; _contentWidthValueType=type; }
- (void) setValue:(float) val type:(NSTextBlockValueType) type forDimension:(NSTextBlockDimension) dimension;
{
	NSAssert(dimension <= NSTextBlockMaximumHeight, @"invalid dimension");
	_value[dimension]=val;
	_valueType[dimension]=type;
}
- (void) setVerticalAlignment:(NSTextBlockVerticalAlignment) alignment; { _verticalAlignment=alignment; }
- (void) setWidth:(float) val type:(NSTextBlockValueType) type forLayer:(NSTextBlockLayer) layer;
{ // set width for all edges
	int i;
	// FIXME: don't use NSAssert but NSException!
	NSAssert(layer <= NSTextBlockMargin, @"invalid layer");
	for(i=0; i<=NSMaxYEdge; i++)
		{
		_width[layer][i]=val;
		_widthType[layer][i]=type;
		}
}
- (void) setWidth:(float) val type:(NSTextBlockValueType) type forLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;
{
	NSAssert(layer <= NSTextBlockMargin, @"invalid layer");
	NSAssert(edge <= NSMaxYEdge, @"invalid edge");
	_width[layer][edge]=val;
	_widthType[layer][edge]=type;
}
- (float) valueForDimension:(NSTextBlockDimension) dimension; { NSAssert(dimension <= NSTextBlockMaximumHeight, @"invalid dimension"); return _value[dimension]; }
- (NSTextBlockValueType) valueTypeForDimension:(NSTextBlockDimension) dimension; { NSAssert(dimension <= NSTextBlockMaximumHeight, @"invalid dimension"); return _valueType[dimension]; }
- (NSTextBlockVerticalAlignment) verticalAlignment; { return _verticalAlignment; }
- (float) widthForLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;
{
	NSAssert(layer <= NSTextBlockMargin, @"invalid layer");
	NSAssert(edge <= NSMaxYEdge, @"invalid edge");
	return _width[layer][edge];
}
- (NSTextBlockValueType) widthValueTypeForLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;
{
	NSAssert(layer <= NSTextBlockMargin, @"invalid layer");
	NSAssert(edge <= NSMaxYEdge, @"invalid edge");
	return _widthType[layer][edge];
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
- (unsigned) numberOfColumns; { return _numberOfColumns; }
- (NSRect) rectForBlock:(NSTextTableBlock *) block
		  layoutAtPoint:(NSPoint) start
				 inRect:(NSRect) rect
		  textContainer:(NSTextContainer *) container
		 characterRange:(NSRange) range; { NIMP; return NSZeroRect; }
- (void) setCollapsesBorders:(BOOL) flag; { _collapsesBorders=flag; }
- (void) setHidesEmptyCells:(BOOL) flag; { _hidesEmptyCells=flag; }
- (void) setLayoutAlgorithm:(NSTextTableLayoutAlgorithm) algorithm; { _layoutAlgorithm=algorithm; }
- (void) setNumberOfColumns:(unsigned) n; { _numberOfColumns=n; }

@end

@implementation NSTextTableBlock

- (void) dealloc;
{
	[_table release];
	[super dealloc];
}

- (id) initWithTable:(NSTextTable *) table
		 startingRow:(int) row
			 rowSpan:(int) rspan
	  startingColumn:(int) col
		  columnSpan:(int) cspan;
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

- (int) columnSpan; { return _cspan; }
- (int) rowSpan; { return _rspan; }
- (int) startingColumn; { return _col; }
- (int) startingRow; { return _row; }
- (NSTextTable *) table; { return _table; }

@end
