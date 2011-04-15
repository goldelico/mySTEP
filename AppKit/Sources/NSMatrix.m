/* 
NSMatrix.m
 
 Matrix control class
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <Foundation/NSValue.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>

#import <AppKit/NSColor.h>
#import <AppKit/NSActionCell.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMatrix.h>

#import "NSAppKitPrivate.h"

#define CONTROL(notif_name) NSControl##notif_name##Notification
#define FREE(p) if (p) free (p)
#define INDEX_FROM_POINT(point) (point.y * _numCols + point.x)
#define POINT_FROM_INDEX(index) \
({MPoint point = { index % _numCols, index / _numCols }; point; })

enum { DEFAULT_CELL_HEIGHT = 17, DEFAULT_CELL_WIDTH = 100 };


typedef struct {									// struct used to compute 
	int x;											// selection in list mode.
	int y;
} MPoint;

typedef struct {
	int x;
	int y;
	int width;
	int height;
} MRect;

//
// Class variables
//

//*****************************************************************************
//
// 		NSMatrix 
//
//*****************************************************************************

@implementation NSMatrix

- (id) init
{
	return [self initWithFrame:NSZeroRect];
}

- (id) initWithFrame:(NSRect)frameRect
{
	return [self initWithFrame:frameRect
						  mode:NSRadioModeMatrix
					 cellClass:[NSActionCell class]
				  numberOfRows:0
			   numberOfColumns:0];
}

- (id) initWithFrame:(NSRect)frameRect
				mode:(int)aMode
		   cellClass:(Class)class
		numberOfRows:(int)rowsHigh
	 numberOfColumns:(int)colsWide
{
	return [self initWithFrame:frameRect
						  mode:aMode
					 prototype:[[class new] autorelease]
				  numberOfRows:rowsHigh
			   numberOfColumns:colsWide];
}

- (id) initWithFrame:(NSRect)frameRect
				mode:(int)aMode
		   prototype:(NSCell*)prototype
		numberOfRows:(int)rows
	 numberOfColumns:(int)cols
{
	int i, size = rows * cols;
	
	self=[super initWithFrame:frameRect];
	if(self)
		{
		if(!prototype)
			[NSException raise: NSInvalidArgumentException
						format: @"%@ initWithFrame: Tried to use nil prototype", NSStringFromClass([self class])];
		_cellPrototype = [prototype retain];
		_cells = [[NSMutableArray alloc] initWithCapacity:size];
		for (i = 0; i < size; i++) 
			{ // generate cells
			NSCell *cell=[_cellPrototype copy];
			[_cells addObject:cell];
			[cell setControlView:self];
			[cell release];	// has been retained in _cells
			}
		_numRows = rows;
		_numCols = cols;
		_cellSize = (NSSize){DEFAULT_CELL_WIDTH, DEFAULT_CELL_HEIGHT};
		_interCell = (NSSize){1, 1};
		backgroundColor = [[NSColor controlBackgroundColor] retain];
		cellBackgroundColor = [backgroundColor retain];
		_m.drawsBackground = YES;
		_m.selectionByRect = YES;
		_m.autosizesCells = YES;
		_m.mode = aMode;
		
		if (_m.mode == NSRadioModeMatrix && _numRows && _numCols)
			[self selectCellAtRow:0 column:0];
		}
	return self;
}

- (void) dealloc
{
	[_cells release];
	[_cellPrototype release];
	[backgroundColor release];
	[cellBackgroundColor release];
	[super dealloc];
}

- (void) addColumn				{ [self insertColumn:_numCols]; }
- (void) addRow					{ [self insertRow:_numRows]; }

- (void) addColumnWithCells:(NSArray*)cellArray
{
	[self insertColumn:_numCols withCells:cellArray];
}

- (void) addRowWithCells:(NSArray*)cellArray
{
	[self insertRow:_numRows withCells:cellArray];
}

- (void) insertColumn:(int)column
{
	int i;
	
	if (column >= _numCols)
		[self renewRows:(_numRows = MAX(1, _numRows)) columns:column];
	
	_numCols++;
	
	for (i = 0; i < _numRows; i++)
		[self makeCellAtRow:i column:column];
	
	if (_m.mode == NSRadioModeMatrix && !_m.allowsEmptySelect && ![self selectedCell])
		[self selectCellAtRow:0 column:0];
}

- (void) insertColumn:(int)column withCells:(NSArray*)cellArray
{
	int i, j = column;
	
	if (column >= _numCols)
		[self renewRows:(_numRows = MAX(1, _numRows)) columns:column];
	
	_numCols++;
	for (i = 0; i < _numRows; i++)
		[_cells insertObject:[cellArray objectAtIndex:i]
					 atIndex:(j = i*_numCols + j)];
	
	if (_m.mode == NSRadioModeMatrix && !_m.allowsEmptySelect && ![self selectedCell])
		[self selectCellAtRow:0 column:0];
}

- (void) insertRow:(int)row
{
	int i;
	
	if (row >= _numRows)
		[self renewRows:row columns:(_numCols = MAX(1, _numCols))];
	
	_numRows++;
	
	for (i = 0; i < _numCols; i++)
		[self makeCellAtRow:row column:i];
	
	if (_m.mode == NSRadioModeMatrix && !_m.allowsEmptySelect && ![self selectedCell])
		[self selectCellAtRow:0 column:0];
}

- (void) insertRow:(int)row withCells:(NSArray*)cellArray
{
	int i, insertPoint;
	
	if (row >= _numRows)
		[self renewRows:row columns:(_numCols = MAX(1, _numCols))];
	
	_numRows++;
	insertPoint = row * _numCols;
	i = _numCols;
	
	while(i--)
		[_cells insertObject:[cellArray objectAtIndex:i] atIndex:insertPoint];
	
	if (_m.mode == NSRadioModeMatrix && !_m.allowsEmptySelect && ![self selectedCell])
		[self selectCellAtRow:0 column:0];
}

- (NSCell*) makeCellAtRow:(int)row column:(int)column
{
	NSCell *aCell;
	
	if(_cellPrototype)
		aCell = [_cellPrototype copy];
	else
		aCell = (_cellClass) ? [_cellClass new] : [NSActionCell new];
	
	[_cells insertObject:aCell atIndex:((row * _numCols) + column)];
	[aCell setControlView:self];
	[aCell release];	// has been retained
	return aCell;
}

- (NSRect) cellFrameAtRow:(int)row column:(int)column
{
	NSRect rect;
	rect.origin.x = column * (_cellSize.width + _interCell.width);
	rect.origin.y = row * (_cellSize.height + _interCell.height);
	rect.size = _cellSize;
	return rect;
}

- (void) getNumberOfRows:(int*)rowCount columns:(int*)columnCount
{
    *rowCount = _numRows;
    *columnCount = _numCols;
}

- (void) putCell:(NSCell*)newCell atRow:(int)row column:(int)column
{
	[_cells replaceObjectAtIndex:(row * _numCols) + column withObject:newCell];
	[self setNeedsDisplayInRect:[self cellFrameAtRow:row column:column]];
}

- (void) removeColumn:(int)column
{
	int i = _numRows;
	
	if (column >= _numCols)
		return;
	
	while(i--)
		[_cells removeObjectAtIndex:((i * _numCols) + column)];
	
	_numCols--;
	
	if (_numCols == 0)
		_numRows = 0;
}

- (void) removeRow:(int)row
{
	int i = _numCols, removalPoint = row * _numCols;
	
	if (row >= _numRows)
		return;
	
	while(i--)
		[_cells removeObjectAtIndex:removalPoint];
	
	_numRows--;
	
	if (_numRows == 0)
		_numCols = 0;
}

- (void) renewRows:(int)newRows columns:(int)newColumns
{								// First check to see if the rows really have
	int i, j;						// fewer cells than newColumns. This may happen
									// because the row arrays does not shrink when
	if (newColumns > _numCols) 	// a lower number of cells is given.
		{
		if (_numRows && newColumns > ([_cells count] / _numRows)) 
			{									// Add cols to existing rows.
			for (i = 0; i < _numRows; i++) 		// Call makeCellAtRow:column:
				for (j = _numCols; j < newColumns; j++)
					[self makeCellAtRow:i column:j];
			}
		}
	
	_numCols = newColumns;
	
	for (i = _numRows; i < newRows; i++) 
		for (j = 0; j < _numCols; j++)
			[self makeCellAtRow:i column:j];
	
	_numRows = newRows;
	[self deselectAllCells];
}

- (void) sortUsingFunction:(int (*)(id element1, id element2, 
									void *userData))comparator
				   context:(void*)context
{
	[_cells sortUsingFunction:comparator context:context];
}

- (void) sortUsingSelector:(SEL)comparator
{
	[_cells sortUsingSelector:comparator];
}

- (BOOL) getRow:(int*)row column:(int*)column forPoint:(NSPoint)point
{
	BOOL betweenRows, betweenCols;
	float h, w, approxRowsHeight, approxColsWidth;
	int approxRow, approxCol;
	// First test limit cases
	if ((point.x < NSMinX(_bounds)) || (point.y < NSMinY(_bounds))
		|| (point.x > NSMaxX(_bounds)) || (point.y > NSMaxY(_bounds)))
		return NO;
	
	h = _cellSize.height + _interCell.height;
	approxRow = point.y / h;
	approxRowsHeight = h * approxRow;
	// Determine if the point 
	betweenRows = !(point.y > approxRowsHeight		// is inside the cell
					&& point.y <= approxRowsHeight + _cellSize.height);
	
	*row = approxRow;
	if (*row < 0)
		*row = 0;
	else if (*row >= _numRows)
			*row = _numRows - 1;
	
	w = _cellSize.width + _interCell.width;
	approxCol = point.x / w;
	approxColsWidth = approxCol * w;
	// Determine if the point  
	betweenCols = !(point.x > approxColsWidth		// is inside the cell
					&& point.x <= approxColsWidth + _cellSize.width);
	
	*column = approxCol;
	if (*column < 0)
		*column = 0;
	else if (*column >= _numCols)
			*column = _numCols - 1;
	
	return !(betweenRows || betweenCols);
}

- (BOOL) getRow:(int *)row column:(int *)column ofCell:(NSCell *)aCell
{ // find cell location
	int i, j;
	for (i = 0; i < _numRows; i++)
		{
		for (j = 0; j < _numCols; j++)
			{
			if ([_cells objectAtIndex:((i * _numCols) + j)] == aCell)
				{ // found
				*row = i;
				*column = j;
				return YES;
				}
			}
		}			
	return NO;
}

- (void) setState:(int)value atRow:(int)row column:(int)column
{
	NSCell *aCell = [self cellAtRow:row column:column];
	if (!aCell)
		return;
	if (_m.mode == NSRadioModeMatrix) 
		{
		int selectedRow, selectedColumn;
		NSCell *selectedCell=[self selectedCell];	// find currently selected cell (if any)
		if(!value && !_m.allowsEmptySelect)
			return;
		if(selectedCell != aCell)
			{ // deselect previous
			[selectedCell setState:NSOffState];
			[self getRow:&selectedRow column:&selectedColumn ofCell:selectedCell];
			[self setNeedsDisplayInRect:[self cellFrameAtRow:selectedRow column:selectedColumn]];
			}
		}
	[aCell setState:value];
	[self setNeedsDisplayInRect:[self cellFrameAtRow:row column:column]];
}

- (void) deselectAllCells
{
	if(_m.allowsEmptySelect || (_m.mode != NSRadioModeMatrix))
		{	
		int count = [_cells count];
		while(count--)
			[[_cells objectAtIndex:count] setState:NSOffState];
			// FIXME: can we optimize if not all cells are selected?
		[self setNeedsDisplay:YES];
		}
}

- (void) deselectSelectedCell
{
	NSCell *selectedCell=[self selectedCell];
	int selectedRow, selectedColumn;
	if(!selectedCell || (!_m.allowsEmptySelect && _m.mode == NSRadioModeMatrix))
		return;	// Don't allow loss of selection if in radio mode and empty selection is not allowed.
	[self getRow:&selectedRow column:&selectedColumn ofCell:selectedCell];
	[self setState:NSOffState atRow:selectedRow column:selectedColumn];
}

- (void) selectAll:(id)sender
{
	int count = [_cells count];
	if(!count)
		return;
	while(count--)
		[[_cells objectAtIndex:count] setState:NSOnState];
	[self setNeedsDisplay:YES];
}

- (void) selectCell:(NSCell *) cell;
{
	int row, col;
	if (cell && [self getRow:&row column:&col ofCell:cell])
		[self setState:NSOnState atRow:row column:col];
}

- (void) selectCellAtRow:(int)row column:(int)column
{
	[self selectCell:[self cellAtRow:row column:column]];
}

- (BOOL) selectCellWithTag:(int)anInt
{
	NSCell *cell=[self cellWithTag:anInt];
	[self selectCell:cell];
	return cell != nil;
}

- (NSArray*) selectedCells
{
	NSMutableArray *array = [NSMutableArray array];
	NSEnumerator *e=[_cells objectEnumerator];
	NSCell *cell;
	while((cell=[e nextObject]))
		{
		if([cell state] != NSOffState)
			[array addObject:cell];
		}
	return array;
}

- (void) _setState:(BOOL)state inRect:(MRect)matrix
{
	int i = MAX(matrix.y - matrix.height, 0), j;
	int maxX = MIN(matrix.x + matrix.width, _numCols);

	[self setNeedsDisplayInRect:NSUnionRect([self cellFrameAtRow:i column:matrix.x], [self cellFrameAtRow:matrix.y column:maxX])];	// first and last cell
	
	for (; i <= matrix.y; i++) 
		{
		for (j = matrix.x; j <= maxX; j++)
			[[_cells objectAtIndex:((i * _numCols) + j)] setState:state];
		}
}

/* 
This method is used for selecting cells in list mode with selection by 
 rect option enabled. `anchor' is the first point in the selection (the 
 coordinates of the cell first clicked). `last' is the last point up to 
 which the anterior selection has been made. `current' is the point to 
 which we must extend the selection. 
 
 We use an imaginary coordinate system whose center is the `anchor' point.
 We should determine in which quadrants are located the `last' and the
 `current' points. Based on this we extend the selection to the rectangle
 determined by `anchor' and `current' points.
 
 The algorithm uses two rectangles: one determined by `anchor' and
 `current' that defines how the final selection rectangle will look, and
 another one determined by `anchor' and `last' that defines the current
 visible selection.
 
 The three points above determine 9 distinct zones depending on position
 of `last' and `current' relative to `anchor'. Each of these zones has a 
 different way of extending the selection from `last' to`current'.
 
 Note the coordinate system is a flipped one not a usual geometric one
 (the y coordinate increases downward).
 */

#ifndef SIGN
#define SIGN(X) (((X)==0)?0:(((X)>0)?1:-1))
#endif

- (void) _selectRectUsingAnchor:(MPoint)anchor
						   last:(MPoint)last
						current:(MPoint)current
{
	int dxca = current.x - anchor.x;
	int dyca = current.y - anchor.y;
	int dxla = last.x - anchor.x;
	int dyla = last.y - anchor.y;
	int dxca_dxla, dyca_dyla;
	int selectRectsNo = 0, unselectRectsNo = 0;
	MRect selectRect[2];
	MRect unselectRect[2];
	int i, tmpx, tmpy;
	
	dxca_dxla = SIGN(dxca) / (dxla != 0 ? SIGN(dxla) : 1);	// protect against division by zero
	dyca_dyla = SIGN(dyca) / (dyla != 0 ? SIGN(dyla) : 1);
	
	if (dxca_dxla >= 0) 
		{
		if (dyca_dyla >= 0) 
			{					// `current' is in the lower right quadrant.
			if (ABS(dxca) <= ABS(dxla)) 
				{
				if (ABS(dyca) <= ABS(dyla)) 
					{								// `current' is in zone I. 
					NSDebugLog (@"zone I");
					
					if (dxca != dxla) 
						{
						i = unselectRectsNo++;
						tmpx = dxca > 0 ?current.x + 1 :current.x + SIGN(dxla);
						unselectRect[i].x = MIN(tmpx, last.x);
						unselectRect[i].y = MAX(anchor.y, current.y);
						unselectRect[i].width = ABS(last.x - tmpx);
						unselectRect[i].height = ABS(current.y - anchor.y);
						}
					
					if (dyca != dyla) 
						{
						i = unselectRectsNo++;
						tmpy = dyca > 0 ?current.y + 1 :current.y + SIGN(dyla);
						unselectRect[i].x = MIN(anchor.x, last.x);
						unselectRect[i].y = MAX(tmpy, last.y);
						unselectRect[i].width = ABS(last.x - anchor.x);
						unselectRect[i].height = ABS(last.y - tmpy);
						}	}
				else 
					{								// `current' is in zone F. 
					NSDebugLog (@"zone F");
					
					selectRectsNo = 1;
					tmpy = dyla >= 0 ? last.y + 1 : last.y - 1;
					selectRect[0].x = MIN(anchor.x, current.x);
					selectRect[0].y = MAX(tmpy, current.y);
					selectRect[0].width = ABS(current.x - anchor.x);
					selectRect[0].height = ABS(current.y - tmpy);
					
					if (dxca != dxla) 
						{
						unselectRectsNo = 1;
						tmpx = dxca > 0 ?current.x + 1 :current.x + SIGN(dxla);
						unselectRect[0].x = MIN(tmpx, last.x);
						unselectRect[0].y = MAX(anchor.y, last.y);
						unselectRect[0].width = ABS(last.x - tmpx);
						unselectRect[0].height = ABS(last.y - anchor.y);
						}	}	}
			else 
				{
				if (ABS(dyca) <= ABS(dyla)) 
					{								// `current' is in zone H.
					NSDebugLog (@"zone H");
					selectRectsNo = 1;
					
					tmpx = dxla >= 0 ? last.x + 1 : last.x - 1;
					selectRect[0].x = MIN(tmpx, current.x);
					selectRect[0].y = MAX(anchor.y, current.y);
					selectRect[0].width = ABS(current.x - tmpx);
					selectRect[0].height = ABS(current.y - anchor.y);
					
					if (dyca != dyla) 
						{
						unselectRectsNo = 1;
						
						tmpy = dyca >= 0 ? current.y + 1 : current.y - 1;
						unselectRect[0].x = MIN(anchor.x, last.x);
						unselectRect[0].y = MAX(tmpy, last.y);
						unselectRect[0].width = ABS(last.x - anchor.x);
						unselectRect[0].height = ABS(last.y - tmpy);
						}	}
				else 
					{								// `current' is in zone G.
					NSDebugLog (@"zone G");
					selectRectsNo = 2;
					
					tmpx = dxla >= 0 ? last.x + 1 : last.x - 1;
					selectRect[0].x = MIN(tmpx, current.x);
					selectRect[0].y = MAX(anchor.y, last.y);
					selectRect[0].width = ABS(current.x - tmpx);
					selectRect[0].height = ABS(last.y - anchor.y);
					
					tmpy = dyla >= 0 ? last.y + 1 : last.y - 1;
					selectRect[1].x = MIN(anchor.x, current.x);
					selectRect[1].y = MAX(tmpy, current.y);
					selectRect[1].width = ABS(current.x - anchor.x);
					selectRect[1].height = ABS(current.y - tmpy);
					}	}	}
		else 
			{					// `current' is in the upper right quadrant 
			if (ABS(dxca) <= ABS(dxla)) 
				{								// `current' is in zone B.
				NSDebugLog (@"zone B");
				
				selectRectsNo = 1;
				tmpy = dyca > 0 ? anchor.y + 1 : anchor.y - 1;
				selectRect[0].x = MIN(anchor.x, current.x);
				selectRect[0].y = MAX(current.y, tmpy);
				selectRect[0].width = ABS(current.x - anchor.x);
				selectRect[0].height = ABS(tmpy - current.y);
				
				if (dyla) 
					{
					unselectRectsNo = 1;
					tmpy = dyca < 0 ? anchor.y + 1 : anchor.y + SIGN(dyla);
					unselectRect[0].x = MIN(anchor.x, current.x);
					unselectRect[0].y = MAX(tmpy, last.y);
					unselectRect[0].width = ABS(last.x - anchor.x);
					unselectRect[0].height = ABS(last.y - tmpy);
					}
				
				if (dxla && dxca != dxla) 
					{
					i = unselectRectsNo++;
					tmpx = dxca > 0 ? current.x + 1 : current.x + SIGN(dxla);
					unselectRect[i].x = MIN(tmpx, last.x);
					unselectRect[i].y = MAX(anchor.y, last.y);
					unselectRect[i].width = ABS(last.x - tmpx);
					unselectRect[i].height = ABS(last.y - anchor.y);
					}	}
			else 
				{									// `current' is in zone A.
				NSDebugLog (@"zone A");
				
				if (dyca != dyla) 
					{
					i = selectRectsNo++;
					tmpy = dyca < 0 ? anchor.y - 1 : anchor.y + 1;
					selectRect[i].x = MIN(anchor.x, last.x);
					selectRect[i].y = MAX(tmpy, current.y);
					selectRect[i].width = ABS(last.x - anchor.x);
					selectRect[i].height = ABS(current.y - tmpy);
					}
				
				i = selectRectsNo++;
				tmpx = dxca > 0 ? last.x + 1 : last.x - 1;
				selectRect[i].x = MIN(tmpx, current.x);
				selectRect[i].y = MAX(current.y, anchor.y);
				selectRect[i].width = ABS(current.x - tmpx);
				selectRect[i].height = ABS(anchor.y - current.y);
				
				if (dyla) 
					{
					unselectRectsNo = 1;
					tmpy = dyca < 0 ? anchor.y + 1 : anchor.y - 1;
					unselectRect[0].x = MIN(anchor.x, last.x);
					unselectRect[0].y = MAX(tmpy, last.y);
					unselectRect[0].width = ABS(last.x - anchor.x);
					unselectRect[0].height = ABS(last.y - tmpy);
					}	}	}	}
	else 
		{
		if (dyca_dyla > 0) 
			{						// `current' is in the lower left quadrant 
			if (ABS(dyca) <= ABS(dyla)) 
				{									// `current' is in zone D. 
				NSDebugLog (@"zone D");
				selectRectsNo = 1;
				
				tmpx = dxca < 0 ? anchor.x - 1 : anchor.x + 1;
				selectRect[0].x = MIN(tmpx, current.x);
				selectRect[0].y = MAX(anchor.y, current.y);
				selectRect[0].width = ABS(current.x - tmpx);
				selectRect[0].height = ABS(current.y - anchor.y);
				
				if (dxla) 
					{
					unselectRectsNo = 1;
					tmpx = dxca < 0 ? anchor.x + 1 : anchor.x - 1;
					unselectRect[0].x = MIN(tmpx, last.x);
					unselectRect[0].y = MAX(anchor.y, current.y);
					unselectRect[0].width = ABS(last.x - tmpx);
					unselectRect[0].height = ABS(current.y - anchor.y);
					}
				
				if (dyla && dyca != dyla) 
					{
					i = unselectRectsNo++;
					tmpy = dyca > 0 ? current.y + 1 : current.y + SIGN(dyla);
					unselectRect[i].x = MIN(anchor.x, last.x);
					unselectRect[i].y = MAX(tmpy, last.y);
					unselectRect[i].width = ABS(last.x - anchor.x);
					unselectRect[i].height = ABS(last.y - tmpy);
					}	}
			else 
				{									// `current' is in zone E. 
				NSDebugLog (@"zone E");
				
				i = selectRectsNo++;
				tmpx = dxca > 0 ? anchor.x + 1 : anchor.x - 1;
				selectRect[i].x = MIN(tmpx, current.x);
				selectRect[i].y = MAX(anchor.y, last.y);
				selectRect[i].width = ABS(current.x - tmpx);
				selectRect[i].height = ABS(last.y - anchor.y);
				
				i = selectRectsNo++;
				tmpy = dyca > 0 ? last.y + 1 : last.y - 1;
				selectRect[i].x = MIN(current.x, anchor.x);
				selectRect[i].y = MAX(current.y, tmpy);
				selectRect[i].width = ABS(anchor.x - current.x);
				selectRect[i].height = ABS(tmpy - current.y);
				
				if (dxla) 
					{
					unselectRectsNo = 1;
					tmpx = dxca > 0 ? anchor.x - 1 : anchor.x + 1;
					unselectRect[0].x = MIN(tmpx, last.x);
					unselectRect[0].y = MAX(anchor.y, last.y);
					unselectRect[0].width = ABS(last.x - tmpx);
					unselectRect[0].height = ABS(last.y - anchor.y);
					}	}	}
		else 
			{										// `current' is in zone C. 
			NSDebugLog (@"zone C");
			selectRectsNo = 1;
			
			selectRect[0].x = MIN(current.x, anchor.x);
			selectRect[0].y = MAX(current.y, anchor.y);
			selectRect[0].width = ABS(anchor.x - current.x);
			selectRect[0].height = ABS(anchor.y - current.y);
			
			if (dyca != dyla) 
				{
				unselectRectsNo = 1;
				unselectRect[0].x = MIN(anchor.x, last.x);
				unselectRect[0].y = MAX(anchor.y, last.y);
				unselectRect[0].width = ABS(last.x - anchor.x);
				unselectRect[0].height = ABS(last.y - anchor.y);
				}	}	}		// We now know which rectangles must be selected and 
								// unselected.  Iterate thru these while performing op.
								// First unselect and only then do the cells selection.
	for (i = 0; i < unselectRectsNo; i++)
		[self _setState:NSOffState inRect:unselectRect[i]];
	for (i = 0; i < selectRectsNo; i++)
		[self _setState:NSOnState inRect:selectRect[i]];
}

- (void) _setState:(BOOL)state startIndex:(int)start endIndex:(int)end
{
	MPoint startPoint = POINT_FROM_INDEX(start);
	MPoint endPoint = POINT_FROM_INDEX(end);
	int i, j = startPoint.x, colLimit;
	
	for (i = startPoint.y; i <= endPoint.y; i++) 
		{
		colLimit = (i == endPoint.y) ? endPoint.x : _numCols - 1;
		
		for (; j <= colLimit; j++) 
			{
			NSCell *aCell = [_cells objectAtIndex:((i * _numCols) + j)];			
			[aCell setState:state?NSOnState:NSOffState];
			}
		j = 0;
		}
}

- (void) _selectContinuousUsingAnchor:(MPoint)anchor
								 last:(MPoint)last
							  current:(MPoint)current
{													// Select and unselect
	int anchorIndex = INDEX_FROM_POINT(anchor);			// cells in list mode with 
	int lastIndex = INDEX_FROM_POINT(last);				// select by rect disabled
	int currentIndex = INDEX_FROM_POINT(current);		// The idea is to compare 
	BOOL doSelect = NO;									// the points based on
	MPoint selectPoint, unselectPoint;					// their linear index in
	BOOL doUnselect = NO;								// matrix and then perform
	int dca = currentIndex - anchorIndex;				// the appropriate action
	int dla = lastIndex - anchorIndex;
	int dca_dla = SIGN(dca) / (SIGN(dla) ? SIGN(dla) : 1);
	
	if (dca_dla >= 0) 
		{
		if (ABS(dca) >= ABS(dla)) 
			{
			doSelect = YES;
			if (currentIndex > lastIndex)
				selectPoint = (MPoint){lastIndex, currentIndex};
			else 
				selectPoint = (MPoint){currentIndex, lastIndex};
			}
		else 
			{
			doUnselect = YES;
			if (currentIndex < lastIndex) 
				unselectPoint = (MPoint){currentIndex + 1, lastIndex};
			else 
				unselectPoint = (MPoint){lastIndex, currentIndex - 1};
			}	}
	else 
		{
		doSelect = doUnselect = YES;
		if (anchorIndex < currentIndex) 
			selectPoint = (MPoint){anchorIndex, currentIndex};
		else 
			selectPoint = (MPoint){currentIndex, anchorIndex};
		if (anchorIndex < lastIndex) 
			unselectPoint = (MPoint){anchorIndex, lastIndex};
		else 
			unselectPoint = (MPoint){lastIndex, anchorIndex};
		}
	
	if (doUnselect)
		[self _setState:NSOnState startIndex:unselectPoint.x endIndex:unselectPoint.y];
	if (doSelect)
		[self _setState:NSOffState startIndex:selectPoint.x endIndex:selectPoint.y];
}

- (void) setSelectionFrom:(int)startPos
					   to:(int)endPos
				   anchor:(int)anchorPos
				highlight:(BOOL)flag
{
	MPoint anchor = POINT_FROM_INDEX(anchorPos);
	MPoint last = POINT_FROM_INDEX(startPos);
	MPoint current = POINT_FROM_INDEX(endPos);
	
	if (_m.selectionByRect)
		[self _selectRectUsingAnchor:anchor last:last current:current];
	else
		[self _selectContinuousUsingAnchor:anchor last:last current:current];
}

- (id) selectedCell
{ // returns the rightmost bottommost selected cell
	int row, column;
	// FIXME: this should be cached and rebuilt only if a cell state changes (how can we know that? KVO?)
	// the problem is that we can externally change the cell state
	// a simple solution would be to cache the result cell and return it as long as it is still selected
	// search for a different only if it is off (or the last cell pointer is removed by a friendly setter)
	for(row=_numRows-1; row >= 0; row--)
		{
		for(column=_numCols-1; column >= 0; column--)
			{
			NSCell *cell=[_cells objectAtIndex:((row * _numCols) + column)];
			if([cell state] != NSOffState)
				return cell;	// found
			}
		}
	return nil;
}

- (int) selectedColumn
{ // return the rightmost column where we have a selected cell
	int row, column;
	// FIXME: this should be cached and rebuilt only if a cell state changes (how can we know that? KVO?)
	for(column=_numCols-1; column >= 0; column--)
		{
		for(row=_numRows-1; row >= 0; row--)
			{
			NSCell *cell=[_cells objectAtIndex:((row * _numCols) + column)];
			if([cell state] != NSOffState)
				return column;	// found
			}
		}
	return -1;	// none
}

- (int) selectedRow
{ // return last (spatial not temporal!) row with a selected cell
	int row, column;
	for(row=_numRows-1; row >= 0; row--)
		{
		for(column=_numCols-1; column >= 0; column--)
			{
			NSCell *cell=[_cells objectAtIndex:((row * _numCols) + column)];
			if([cell state] != NSOffState)
				return row;	// found
			}
		}
	return -1;
}

- (id) cellAtRow:(int)row column:(int)column
{
	if (row < 0 || row >= _numRows || column < 0 || column >= _numCols)
		return nil;	
	return [_cells objectAtIndex:((row * _numCols) + column)];
}

- (id) cellWithTag:(int)anInt
{
	NSEnumerator *e=[_cells objectEnumerator];
	NSCell *cell;
	while((cell=[e nextObject]))
		if ([cell tag] == anInt)
			return cell;
	return nil;
}

- (id) selectTextAtRow:(int)row column:(int)column
{
	NSCell *cell=[self cellAtRow:row column:column];
#if 1
	NSLog(@" NSMatrix: selectTextAtRow --- ");
#endif
	if (cell && [cell isEditable])
		{
		[self selectCell:cell];
		[self selectText:self];			
		return cell;
		}
	return nil;
}

- (void) selectText:(id)sender
{
	NSCell *selectedCell=[self selectedCell];
#if 1
	NSLog(@" NSMatrix: selectText cell=%@", selectedCell);
#endif
	if (selectedCell && [selectedCell isEditable] && [selectedCell isEnabled])
		{
		NSText *t = [_window fieldEditor:YES forObject:selectedCell];
		int selectedRow, selectedColumn;
		NSRect r;
		[self getRow:&selectedRow column:&selectedColumn ofCell:selectedCell];
		r = [self cellFrameAtRow:selectedRow column:selectedColumn];		
		[selectedCell selectWithFrame:r
							   inView:self
							   editor:t	
							 delegate:self	
								start:(int)0	 
							   length:(int)0];		
		//		[window makeFirstResponder: t];
		}
}

- (void) textDidBeginEditing:(NSNotification *)aNotification
{
	// FIXME: add NSFieldEditor to the notification user info
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidBeginEditing) object: self];
}

- (void) textDidChange:(NSNotification *)aNotification
{
	NSCell *selectedCell=[self selectedCell];
	if (selectedCell && [selectedCell respondsToSelector:@selector(textDidChange:)])
		{
		[selectedCell textDidChange:aNotification];
		return;
		}
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidChange) object: self];
}

- (void) textDidEndEditing:(NSNotification *)aNotification
{
	NSNumber *code;
	NSCell *selectedCell=[self selectedCell];

	NSLog(@" NSMatrix textDidEndEditing for cell %@", selectedCell);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidEndEditing) object: self];
	
	[selectedCell endEditing:[aNotification object]];			
	
	if((code = [[aNotification userInfo] objectForKey:NSTextMovement]))
		switch([code intValue])
			{
			case NSReturnTextMovement:
#if 1
				NSLog(@"enter key");
#endif
				[_window makeFirstResponder:self];
				[self sendAction];
				break;
			case NSTabTextMovement:					// FIX ME select next cell
			case NSBacktabTextMovement:
				case NSUpTextMovement:
				case NSDownTextMovement:
					break;
				
			case NSIllegalTextMovement:
			default:
				break;
			}
}

- (BOOL) textShouldBeginEditing:(NSText*)textObject		
{ 
	if (_delegate && [_delegate respondsToSelector:@selector(control:textShouldBeginEditing:)])
		return [_delegate control:self textShouldBeginEditing:textObject];
	return YES; 
}

- (BOOL) textShouldEndEditing:(NSText*)aTextObject
{															// delegate method
	NSCell *selectedCell=[self selectedCell];
	NSLog(@" NSMatrix textShouldEndEditing (text=%@)", aTextObject);
	NSLog(@" storage=%@", [aTextObject textStorage]);
	NSLog(@" string=%@", [aTextObject string]);
	NSLog(@" cell=%@", selectedCell);
	
	if(![_window isKeyWindow])
		return NO;

	if(selectedCell && [selectedCell isEntryAcceptable: [aTextObject string]])
		{
		if (_delegate && [_delegate respondsToSelector:@selector(control:textShouldEndEditing:)])
			if(![_delegate control:self textShouldEndEditing:aTextObject])
				{
				NSBeep();
				
				return NO;
				}

		[selectedCell setStringValue:[aTextObject string]];

		return YES;
		}
	
	NSBeep();												// entry not valid
															//	[self sendAction:_errorAction toTarget:[selectedCell target]];
	[aTextObject setString:[selectedCell stringValue]];
	
	return NO;
}

- (void) setValidateSize:(BOOL)flag			
{
	NIMP;
}

- (void) sizeToCells
{
	NSSize newSize;
	newSize.width = MAX(_numCols, 1) * (_cellSize.width + _interCell.width);
	newSize.height = MAX(_numRows, 1) * (_cellSize.height + _interCell.height);
	[self setFrameSize: newSize];
}

- (void) scrollCellToVisibleAtRow:(int)row column:(int)column
{
	[self scrollRectToVisible:[self cellFrameAtRow:row column:column]];
}

- (void) setScrollable:(BOOL)flag
{
	NSEnumerator *e=[_cells objectEnumerator];
	NSCell *cell;
	while((cell=[e nextObject]))
		[cell setScrollable:flag];
	[_cellPrototype setScrollable:flag];
}

- (void) drawRect:(NSRect)rect
{
	int i, j;
	int row1, col1;								// cell at the upper left corner
	int row2, col2;								// cell at the lower right corner

	NSPoint p = {NSMaxX(rect), NSMaxY(rect)}; 
	
	if(_m.drawsBackground)							
		{			
		[backgroundColor set];					
		NSRectFill(rect);								// draw the background
		}
	
	if(![self getRow:&row1 column:&col1 forPoint:rect.origin])
		{
		if (row1 < 0)
			row1 = 0;
		if (col1 < 0)
			col1 = 0;
		}
	
	if(![self getRow:&row2 column:&col2 forPoint:p])
		{
		if (row2 >= _numRows)
			row2 = _numRows - 1;
		if (col2 >= _numCols)
			col2 = _numCols - 1;
		}
#if 1
	NSLog (@"%@ draw cells in rect %@ between (%d, %d) and (%d, %d)", self, NSStringFromRect(rect), row1,col1, row2,col2);
#endif
	for (i = row1; i <= row2; i++) 					// Draw the cells within 
		{											// the drawing rectangle.
		for (j = col1; j <= col2; j++)
			[self drawCellAtRow:i column:j];
		}
}

- (void) drawCellAtRow:(int)row column:(int)column
{
	NSCell *aCell = [self cellAtRow:row column:column];
	NSRect cellFrame = [self cellFrameAtRow:row column:column];
	[aCell drawWithFrame:cellFrame inView:self];
}

- (void) highlightCell:(BOOL)flag
				 atRow:(int)row
				column:(int)column
{
	NSCell *aCell = [self cellAtRow:row column:column];	
	if (aCell) 
		[aCell highlight:flag withFrame:[self cellFrameAtRow:row column:column] inView:self];
}

- (BOOL) sendAction
{
	SEL cellAction;
	NSCell *selectedCell=[self selectedCell];
#if 1
	NSLog(@"sendAction selected=%@", selectedCell);
	NSLog(@"cell action=%@ target=%@", NSStringFromSelector([selectedCell action]), [selectedCell target]);
	NSLog(@"self action=%@ target=%@", NSStringFromSelector([self action]), [self target]);
#endif
	if (!selectedCell || ![selectedCell isEnabled])
		return NO;
	
	if ((cellAction = [selectedCell action]) && [self sendAction:cellAction to:[selectedCell target]])
		return YES;
	return [self sendAction:_action toTarget:_target];
}

- (void) sendDoubleAction
{
	NSCell *selectedCell=[self selectedCell];
	if (!selectedCell || ![selectedCell isEnabled])
		return;
	if (_target && _doubleAction)
		[self sendAction:_doubleAction toTarget:_target];
	else
		[self sendAction];
}

- (void) sendAction:(SEL)aSelector to:(id)anObject forAllCells:(BOOL)flag
{
	int i, j;
	NSCell *c;
	
	for (i = 0; i < _numRows; i++) 
		{
		for (j = 0; j < _numCols; j++)
			{
			c = [_cells objectAtIndex:((i * _numCols) + j)];
			if((flag || [c state] != NSOffState) && ![anObject performSelector:aSelector withObject:c])
				return;
			}
		}
}

- (BOOL) acceptsFirstMouse:(NSEvent *) event
{
	return _m.mode == NSListModeMatrix ? NO : YES;
}

- (void) mouseDown:(NSEvent *) event
{
	int clickCount = [event clickCount];
	NSPoint location;	// location in view
	BOOL inCell;		// initially in cell or in intercell spacing?
	id aCell=nil;			// selected cell
	int row, column;	// row/col of selected cell
	NSRect rect;		// rect of selected cell
	id previousCell = nil;			// previous cell during ListMode
	static MPoint anchor = {0, 0};	// initial cell during ListMode
	_mouseDownFlags = [event modifierFlags];
	if(_ignoresMultiClick && clickCount > 1)
		{
		[super mouseDown:event];	// NSControl will try to forward to next responder
		return;
		}
	location = [self convertPoint:[event locationInWindow] fromView:nil];	// location on view
	inCell = [self getRow:&row column:&column forPoint:location];			// cell index - returns NO if outside or on the intercell spacing
	if(inCell)
		{
		aCell = [self cellAtRow:row column:column];							// cell (if any)
		rect = [self cellFrameAtRow:row column:column];						// the real cell rect
		}
	while([event type] != NSLeftMouseUp)
		{ // loop outside until mouse finally goes up
		if(inCell && (_m.mode == NSListModeMatrix || NSMouseInRect(location, rect, [self isFlipped])))
			{ // track while in initial cell or list mode
			BOOL done = NO;
			switch(_m.mode) 
				{
				case NSTrackModeMatrix:
					{ // simply track the cell (it will update its state autonomously)
						done = [aCell trackMouse:event
										  inRect:rect		
										  ofView:self
									untilMouseUp:[[aCell class] prefersTrackingUntilMouseUp]];			// YES if mouse went up in cell
						[self setNeedsDisplayInRect:rect];
						break;
					}
				case NSHighlightModeMatrix:
					{ // Highlight mode is like Track mode except that it highlights and toggles the cell state (ignoring Mixed mode)
						int state=[aCell state];
						[aCell setHighlighted:YES];
						[self setNeedsDisplayInRect:rect];
						done = [aCell trackMouse:event
										  inRect:rect
										  ofView:self
									untilMouseUp:[[aCell class] prefersTrackingUntilMouseUp]];			// YES if mouse went up in cell
						[aCell setHighlighted:NO];
						[self setNeedsDisplayInRect:rect];
						if(done)
							[aCell setState:state == NSOffState?NSOnState:NSOffState];	// toggle state
						break;
					}
				case NSRadioModeMatrix:
					{ // similar to Highlight Mode except that it enforces radio button behaviour
						int state=[aCell state];
						[aCell setHighlighted:YES];
						[self setNeedsDisplayInRect:rect];
						done = [aCell trackMouse:event
										  inRect:rect
										  ofView:self
									untilMouseUp:[[aCell class] prefersTrackingUntilMouseUp]];			// YES if mouse went up in cell
						[aCell setHighlighted:NO];
						[self setNeedsDisplayInRect:rect];
						if(done)
							{
							[aCell setState:state];	// restore any changed state
							[self setState:NSOnState atRow:row column:column];	// force selection (deselects previously selected cell)
							}
						break;
					}
					
				case NSListModeMatrix:
					{ // List mode allows multiple cells to be selected/deselected (as used in NSBrowser)
						unsigned modifiers = [event modifierFlags];
						int state=NSOnState;	// default
						// FIXME:
						// wenn schon selektiert (ohne Shift) dann passiert gar nichts, v.a. wird nicht state=highlighted
						// Alt-Click auf leere selection selektiert nicht nur den geclickten sondern auch den allerersten (Bug?)
						if(!previousCell)
							{ // initial click
							if([aCell state] == NSOffState && !(modifiers & (NSShiftKeyMask | NSAlternateKeyMask)))
								{ // initially selecting a non-selected cell with no modifiers deselects all others
								int count = [_cells count];
								while(count--)
									{
									NSCell *cell;
									cell=[_cells objectAtIndex:count];
									if(cell != aCell)
										{
										[cell setState:NSOffState];
										[cell setHighlighted:NO];
										}
									}
								// FIXME: can we optimize if not all cells are selected?
								[self setNeedsDisplay:YES];
								anchor = (MPoint){column, row};
								}
							}
						else if(aCell != previousCell)
							{ // extend/shrink selection							
#if 1
							NSLog(@"extend to (%d, %d)", row, column);
#endif					
#if 0
							if (_m.selectionByRect)
								[self _selectRectUsingAnchor:anchor
														last:(MPoint){selectedColumn, selectedRow}
													 current:(MPoint){column, row}];
							else
								[self _selectContinuousUsingAnchor:anchor
															  last:(MPoint){selectedColumn, selectedRow}
														   current:(MPoint){column, row}];
#endif
							if(modifiers & NSAlternateKeyMask)
								state=([aCell state]==NSOffState)?NSOnState:NSOffState;	// new state
							else
								state=NSOnState;	// select
							[aCell setState:state];
							[aCell setHighlighted:state];
							previousCell = aCell;
							}
						done = [aCell trackMouse:event
										  inRect:rect
										  ofView:self
									untilMouseUp:[[aCell class] prefersTrackingUntilMouseUp]];			// YES if mouse went up in this cell
						[aCell setState:state];
						[aCell setHighlighted:state];
						break;
					}
				}	// switch
			[self scrollRectToVisible:rect];
			if(done)
				{ // if mouse went up in initial cell
				if(![aCell action] || ![aCell target])
					{ // cell did not have a private action
					// shouldn't we handle first responders???
					if(clickCount == 2)			// notify a double click
						[self sendDoubleAction];
					else
						[self sendAction];
					}
				if([aCell isEditable])			// if cell is editable
					{
					[self selectCell:aCell];	// select the cell so that the action methods get called
					[self selectText:self];		// begin editing
					}
				break;	// break loop
				}
			}
		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:[NSDate distantFuture]
									  inMode:NSEventTrackingRunLoopMode
									 dequeue:YES];
#if 0
		NSLog(@"Matrix: got next event: %@", event);
#endif
		location = [self convertPoint:[event locationInWindow] fromView:nil];	// new location
		if(_m.mode == NSListModeMatrix)
			{ // update cell while we move
			inCell = [self getRow:&row column:&column forPoint:location];			// cell index - returns NO if outside or on the intercell spacing
			if(inCell)
				{ // ignore while we are on intercell spacing
				aCell = [self cellAtRow:row column:column];							// new cell (if any)
				rect = [self cellFrameAtRow:row column:column];						// the real cell rect
				}			   
			}
		}
}

- (void) updateCell:(NSCell *)aCell
{ // NOTE: not called when changein state!
	// FIXME: if cell has focus, redraw focus ring
	[self updateCellInside:aCell];
}

- (void) updateCellInside:(NSCell *)aCell
{ // same...
	int r, c;	// attempt to update only the cell and not the whole matrix
	if([self getRow:&r column:&c ofCell:aCell])
		{
		[self setNeedsDisplayInRect:[self cellFrameAtRow:r column:c]];
		return;
		}
	[self setNeedsDisplay:YES];	// oh well, update the whole matrix
}

- (BOOL) performKeyEquivalent:(NSEvent*)event
{ // find a cell that responds to this key event
	int i, j;
	NSString *key = [event charactersIgnoringModifiers];
	unsigned int modifiers=[event modifierFlags] & (NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask | NSShiftKeyMask);
	for (i = 0; i < _numRows; i++) 
		for (j = 0; j < _numCols; j++) 
			{
			NSCell *c = [_cells objectAtIndex:((i * _numCols) + j)];
			
			if(![c isEnabled])
				continue;
			if(([(NSButtonCell *) c keyEquivalentModifierMask] == modifiers) && [[c keyEquivalent] isEqualToString:key]) 
				{ // required modifier is present
#if 0
				// Button animation...
				
				NSCell *oldSelectedCell = selectedCell;
				
				selectedCell = c;
				[self lockFocus];
				[self highlightCell:YES atRow:i column:j];
				[_window flushWindow];
				[c setState:(![c state])?NSOnState:NSOffState];	// toggle
				[self sendAction];
				[self highlightCell:NO atRow:i column:j];
				[_window flushWindow];
				[self unlockFocus];
				selectedCell = oldSelectedCell;
#endif
				
				return YES;
				}
			}
	return NO;
}

- (void) resetCursorRects
{
	int i, j;
	
	for (i = 0; i < _numRows; i++) 
		{
		for (j = 0; j < _numCols; j++) 
			{
			NSCell *c = [_cells objectAtIndex:((i * _numCols) + j)];
			[c resetCursorRect:[self cellFrameAtRow:i column:j] inView:self];
			}
		}
}

- (NSArray*) cells							{ return _cells; }
- (void) setMode:(NSMatrixMode)aMode		{ _m.mode = aMode; }
- (NSMatrixMode) mode						{ return _m.mode; }
- (void) setCellClass:(Class)class			{ _cellClass = class; }
- (Class) cellClass							{ return _cellClass; }
- (void) setPrototype:(NSCell*)aCell		{ ASSIGN(_cellPrototype, aCell); }
- (id) prototype							{ return _cellPrototype; }
- (NSSize) cellSize							{ return _cellSize; }
- (NSSize) intercellSpacing					{ return _interCell; }
- (void) setCellSize:(NSSize)size			{ _cellSize = size; }
- (void) setIntercellSpacing:(NSSize)size	{ _interCell = size; }
- (void) setBackgroundColor:(NSColor*)c		{ ASSIGN(backgroundColor, c); }
- (void) setCellBackgroundColor:(NSColor*)c { ASSIGN(cellBackgroundColor, c); }
- (NSColor*) cellBackgroundColor			{ return cellBackgroundColor; }
- (NSColor*) backgroundColor				{ return backgroundColor; }
- (void) setDelegate:(id)object				{ [super setDelegate:object]; }
- (id) delegate								{ return _delegate; }
- (id) target								{ return _target; }
- (void) setTarget:anObject					{ ASSIGN(_target, anObject); }
- (void) setDoubleAction:(SEL)aSelector		{ _doubleAction = aSelector; }
- (SEL) doubleAction						{ return _doubleAction; }
- (void) setSelectionByRect:(BOOL)flag		{ _m.selectionByRect = flag; }
- (void) setDrawsBackground:(BOOL)flag		{ _m.drawsBackground = flag; }
- (void) setAllowsEmptySelection:(BOOL)flag	{ _m.allowsEmptySelect = flag; }
- (void) setDrawsCellBackground:(BOOL)flag	{ _m.drawsCellBackground = flag; }
- (void) setAutosizesCells:(BOOL)flag		{ _m.autosizesCells = flag; }
- (BOOL) isSelectionByRect					{ return _m.selectionByRect; }
- (BOOL) isOpaque							{ return _m.drawsBackground; }
- (BOOL) drawsBackground					{ return _m.drawsBackground; }
- (BOOL) drawsCellBackground				{ return _m.drawsCellBackground; }
- (BOOL) allowsEmptySelection				{ return _m.allowsEmptySelect; }
- (BOOL) autosizesCells						{ return _m.autosizesCells; }
- (BOOL) isAutoscroll						{ return _m.autoscroll; }
- (void) setAutoscroll:(BOOL)flag			{ _m.autoscroll = flag; }
- (int) numberOfRows						{ return _numRows; }
- (int) numberOfColumns						{ return _numCols; }
- (int) mouseDownFlags		   				{ return _mouseDownFlags; }
- (BOOL) isFlipped							{ return YES; }
- (BOOL) acceptsFirstResponder				{ return YES; }

	// override NSControl's methods
- (SEL) action								{ return _action; }
- (void) setAction:(SEL)aSelector			{ _action = aSelector; }

- (BOOL) becomeFirstResponder
{
	return [[self selectedCell] isSelectable];
}

- (void) encodeWithCoder:(NSCoder *)aCoder				{ [super encodeWithCoder:aCoder]; }

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		unsigned int matrixflags=[aDecoder decodeIntForKey:@"NSMatrixFlags"];
		
#define HIGHLIGHTMODE	((matrixflags&0x80000000) != 0)
#define RADIOMODE	((matrixflags&0x40000000) != 0)
#define LISTMODE	((matrixflags&0x20000000) != 0)
#define MODE	HIGHLIGHTMODE?NSHighlightModeMatrix:(RADIOMODE?NSRadioModeMatrix:(LISTMODE?NSListModeMatrix:NSTrackModeMatrix))
		_m.mode=MODE;
#define EMPTYSEL	((matrixflags&0x10000000) != 0)
		_m.allowsEmptySelect=EMPTYSEL;
#define AUTOSCROLL	((matrixflags&0x08000000) != 0)
		_m.autoscroll=AUTOSCROLL;
#define SELRECT	((matrixflags&0x04000000) != 0)
		_m.selectionByRect=SELRECT;
#define CELLBACKGROUND	((matrixflags&0x02000000) != 0)
		_m.drawsCellBackground=CELLBACKGROUND;
#define BACKGROUND	((matrixflags&0x01000000) != 0)
		_m.drawsBackground=BACKGROUND;
#define AUTOSIZE	((matrixflags&0x00800000) != 0)
		_m.autosizesCells=AUTOSIZE;
		
		backgroundColor = [[aDecoder decodeObjectForKey:@"NSBackgroundColor"] retain];
#if 0
		NSLog(@"NSMatrix initWithCoder backgroundColor=%@", backgroundColor);
#endif
		cellBackgroundColor = [[aDecoder decodeObjectForKey:@"NSCellBackgroundColor"] retain];
		_cells = [[aDecoder decodeObjectForKey:@"NSCells"] retain];
		_cellClass = NSClassFromString([aDecoder decodeObjectForKey:@"NSCellClass"]);
		_cellSize = [aDecoder decodeSizeForKey:@"NSCellSize"];
		_interCell = [aDecoder decodeSizeForKey:@"NSIntercellSpacing"];
		_numCols = [aDecoder decodeIntForKey:@"NSNumCols"];
		_numRows = [aDecoder decodeIntForKey:@"NSNumRows"];
		_cellPrototype = [[aDecoder decodeObjectForKey:@"NSProtoCell"] retain];
			// FIXME: I have seen the case that there is only a NSSelectedRow and a NSSelectedCell but no NSSelectedCol
		if([aDecoder containsValueForKey:@"NSSelectedRow"] || [aDecoder containsValueForKey:@"NSSelectedCol"])
			[self selectCellAtRow:[aDecoder decodeIntForKey:@"NSSelectedRow"] column:[aDecoder decodeIntForKey:@"NSSelectedCol"]];
		if([aDecoder containsValueForKey:@"NSSelectedCell"])
			[self selectCell:[aDecoder decodeObjectForKey:@"NSSelectedCell"]];
#if 0
		NSLog(@"%@ initWithCoder:%@", self, aDecoder]);
#endif
return self;
		}
return self;
}

@end /* NSMatrix */
