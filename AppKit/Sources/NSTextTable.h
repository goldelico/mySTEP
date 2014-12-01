/*
	NSTextTable.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.

	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	12. December 2007 - aligned with 10.5 
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

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
	NSTextBlockPadding=-1,	// space around border (transparent)
	NSTextBlockBorder,	// colored border
	NSTextBlockMargin	// space between text and border (background color)
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
	// CHECKME: are the arrays dimensioned correctly?
	CGFloat _width[NSTextBlockMargin-NSTextBlockPadding+1][NSMaxYEdge+1];
	CGFloat _value[NSTextBlockMaximumHeight+1];
	CGFloat _contentWidth;
	NSColor *_backgroundColor;
	NSColor *_borderColorForEdge[NSMaxYEdge+1];
	NSTextBlockValueType _widthType[NSTextBlockMargin-NSTextBlockPadding+1][NSMaxYEdge+1];
	NSTextBlockValueType _valueType[NSTextBlockMaximumHeight+1];
	NSTextBlockValueType _contentWidthValueType;
	NSTextBlockVerticalAlignment _verticalAlignment;
}

- (NSColor *) backgroundColor;
- (NSColor *) borderColorForEdge:(NSRectEdge) edge;
- (NSRect) boundsRectForContentRect:(NSRect) cont
							 inRect:(NSRect) rect
					  textContainer:(NSTextContainer *) container
					 characterRange:(NSRange) range;
- (CGFloat) contentWidth;
- (NSTextBlockValueType) contentWidthValueType;
- (void) drawBackgroundWithFrame:(NSRect) rect
						  inView:(NSView *) view
				  characterRange:(NSRange) range
				   layoutManager:(NSLayoutManager *) lm;
// - (id) init; 
- (NSRect) rectForLayoutAtPoint:(NSPoint) point
						 inRect:(NSRect) rect
				  textContainer:(NSTextContainer *) cont
				 characterRange:(NSRange) range;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setBorderColor:(NSColor *) color;
- (void) setBorderColor:(NSColor *) color forEdge:(NSRectEdge) edge;
- (void) setContentWidth:(CGFloat) val type:(NSTextBlockValueType) type;
- (void) setValue:(CGFloat) val type:(NSTextBlockValueType) type forDimension:(NSTextBlockDimension) dimension;
- (void) setVerticalAlignment:(NSTextBlockVerticalAlignment) alignment;
- (void) setWidth:(CGFloat) val type:(NSTextBlockValueType) type forLayer:(NSTextBlockLayer) layer;
- (void) setWidth:(CGFloat) val type:(NSTextBlockValueType) type forLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;
- (CGFloat) valueForDimension:(NSTextBlockDimension) dimension;
- (NSTextBlockValueType) valueTypeForDimension:(NSTextBlockDimension) dimension;
- (NSTextBlockVerticalAlignment) verticalAlignment;
- (CGFloat) widthForLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;
- (NSTextBlockValueType) widthValueTypeForLayer:(NSTextBlockLayer) layer edge:(NSRectEdge) edge;

@end

enum
{
	NSTextTableAutomaticLayoutAlgorithm =0,
	NSTextTableFixedLayoutAlgorithm
};
typedef NSUInteger NSTextTableLayoutAlgorithm;

@interface NSTextTable : NSTextBlock
{
	NSTextTableLayoutAlgorithm _layoutAlgorithm;
	unsigned _numberOfColumns;
	BOOL _collapsesBorders;
	BOOL _hidesEmptyCells;
}

- (NSRect) boundsRectForBlock:(NSTextTableBlock *) block
				  contentRect:(NSRect) content
					   inRect:(NSRect) rect
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
- (NSUInteger) numberOfColumns;
- (NSRect) rectForBlock:(NSTextTableBlock *) block
		  layoutAtPoint:(NSPoint) start
				 inRect:(NSRect) rect
		  textContainer:(NSTextContainer *) container
		 characterRange:(NSRange) range;
- (void) setCollapsesBorders:(BOOL) flag;
- (void) setHidesEmptyCells:(BOOL) flag;
- (void) setLayoutAlgorithm:(NSTextTableLayoutAlgorithm) algorithm;
- (void) setNumberOfColumns:(NSUInteger) n;

@end

@interface NSTextTableBlock : NSTextBlock
{
	NSTextTable *_table;
	int _col;
	int _cspan;
	int _row;
	int _rspan;
}

- (NSInteger) columnSpan;
- (id) initWithTable:(NSTextTable *) table
		 startingRow:(NSInteger) row
			 rowSpan:(NSInteger) rspan
	  startingColumn:(NSInteger) col
		  columnSpan:(NSInteger) cspan;
- (NSInteger) rowSpan;
- (NSInteger) startingColumn;
- (NSInteger) startingRow;
- (NSTextTable *) table;

@end

#endif /* _mySTEP_H_NSTextTable */
