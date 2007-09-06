//
//  NSTextTable.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSTextTable
#define _mySTEP_H_NSTextTable

#import "AppKit/NSController.h"
#import "AppKit/NSText.h"

@class NSTextContainer;
@class NSLayoutManager;
@class NSTextTableBlock;

typedef enum _NSTextBlockValueType
{
	NSTextBlockAbsoluteValueType,
	NSTextBlockPercentageValueType
} NSTextBlockValueType;

typedef enum _NSTextBlockDimension
{
	NSTextBlockWidth,
	NSTextBlockMinimumWidth,	
	NSTextBlockMaximumWidth,
	NSTextBlockHeight,
	NSTextBlockMinimumHeight,	
	NSTextBlockMaximumHeight
} NSTextBlockDimension;


typedef enum _NSTextBlockLayer
{
	NSTextBlockPadding,	
	NSTextBlockBorder,
	NSTextBlockMargin
} NSTextBlockLayer;

typedef enum _NSTextBlockVerticalAlignment
{
	NSTextBlockTopAlignment,
	NSTextBlockMiddleAlignment,
	NSTextBlockBottomAlignment,
	NSTextBlockBaselineAlignment
} NSTextBlockVerticalAlignment;

@interface NSTextBlock : NSObject <NSCoding, NSCopying>
{
	NSColor *_backgroundColor;
	NSColor *_borderColorForEdge[NSMaxYEdge+1];
	float _contentWidth;
	NSTextBlockValueType _contentWidthValueType;
	float _value[NSTextBlockMaximumHeight+1];
	NSTextBlockValueType _valueType[NSTextBlockMaximumHeight+1];
	NSTextBlockVerticalAlignment _verticalAlignment;
	float _width[NSTextBlockMargin+1][NSMaxYEdge+1];
	NSTextBlockValueType _widthType[NSTextBlockMargin+1][NSMaxYEdge+1];
}

- (NSColor *) backgroundColor;
- (NSColor *) borderColorForEdge:(NSRectEdge) edge;
- (NSRect) boundsRectForContentRect:(NSRect) cont
														 inRect:(NSRect) rect
											textContainer:(NSTextContainer *) container
										 characterRange:(NSRange) range;
- (float) contentWidth;
- (NSTextBlockValueType) contentWidthValueType;
- (void) drawBackgroundWithFrame:(NSRect) rect
													inView:(NSView *) view
									characterRange:(NSRange) range
									 layoutManager:(NSLayoutManager *) lm;
- (NSRect) rectForLayoutAtPoint:(NSPoint) point
												 inRect:(NSRect) rect
									textContainer:(NSTextContainer *) cont
								 characterRange:(NSRange) range;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setBorderColor:(NSColor *) color;
- (void) setBorderColor:(NSColor *) color forEdge:(NSRectEdge) edge;
- (void) setContentWidth:(float) val type:(NSTextBlockValueType) type;
- (void) setValue:(float) val type:(NSTextBlockValueType) type forDimension:(NSTextBlockDimension) dimension;
- (void) setVerticalAlignment:(NSTextBlockVerticalAlignment) alignment;
- (void) setWidth:(float) val type:(NSTextBlockValueType) type forLayer:(NSTextBlockLayer) layer;
- (void) setWidth:(float) val type:(NSTextBlockValueType) type forLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;
- (float) valueForDimension:(NSTextBlockDimension) dimension;
- (NSTextBlockValueType) valueTypeForDimension:(NSTextBlockDimension) dimension;
- (NSTextBlockVerticalAlignment) verticalAlignment;
- (float) widthForLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;
- (NSTextBlockValueType) widthValueTypeForLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;

@end

typedef enum _NSTextTableLayoutAlgorithm
{
	NSTextTableAutomaticLayoutAlgorithm =0,
	NSTextTableFixedLayoutAlgorithm
} NSTextTableLayoutAlgorithm;

@interface NSTextTable : NSTextBlock
{
	NSTextTableLayoutAlgorithm _layoutAlgorithm;
	unsigned _numberOfColumns;
	BOOL _collapsesBorders;
	BOOL _hidesEmptyCells;
}

- (NSRect) boundsRectForBlock:(NSTextTableBlock *) block
				  contentRect:(NSRect) content
					   inRect:(NSRect)rect
				textContainer:(NSTextContainer *) container
			   characterRange:(NSRange) range;
- (BOOL) collapsesBorders;
- (void) drawBackgroundForBlock:(NSTextTableBlock *) block
					  withFrame:(NSRect) frame
						 inView:(NSView *) controlView
				 characterRange:(NSRange) range
				  layoutManager:(NSLayoutManager *) manager;
- (BOOL) hidesEmptyCells;
- (NSTextTableLayoutAlgorithm) layoutAlgorithm;
- (unsigned) numberOfColumns;
- (NSRect) rectForBlock:(NSTextTableBlock *) block
		  layoutAtPoint:(NSPoint) start
				 inRect:(NSRect) rect
		  textContainer:(NSTextContainer *) container
		 characterRange:(NSRange) range;
- (void) setCollapsesBorders:(BOOL) flag;
- (void) setHidesEmptyCells:(BOOL) flag;
- (void) setLayoutAlgorithm:(NSTextTableLayoutAlgorithm) algorithm;
- (void) setNumberOfColumns:(unsigned) n;

@end

@interface NSTextTableBlock : NSTextBlock
{
	NSTextTable *_table;
	int _col;
	int _cspan;
	int _row;
	int _rspan;
}

- (int) columnSpan;
- (id) initWithTable:(NSTextTable *) table
				 startingRow:(int) row
						 rowSpan:(int) rspan
			startingColumn:(int) col
					columnSpan:(int) cspan;
- (int) rowSpan;
- (int) startingColumn;
- (int) startingRow;
- (NSTextTable *) table;

@end

#endif /* _mySTEP_H_NSTextTable */
