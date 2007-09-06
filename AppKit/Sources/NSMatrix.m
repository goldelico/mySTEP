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

//
// Class variables
//

static tMatrix 
_newMatrix (int numRows, int numCols)
{
int rows = (numRows ? numRows : 1);
int cols = (numCols ? numCols : 1);
tMatrix m = malloc(sizeof(struct _tMatrix));
int i;

	m->matrix = malloc(rows * sizeof (BOOL*));
	for (i = 0; i < rows; i++)
		m->matrix[i] = calloc(cols, sizeof (BOOL));
	
	m->allocatedRows = rows;
	m->allocatedCols = cols;
	m->numRows = numRows;
	m->numCols = numCols;
	
	return m;
}

static void 
_freeMatrix (tMatrix m)
{
int i;

	for (i = 0; i < m->allocatedRows; i++)
		FREE (m->matrix[i]);
	FREE (m->matrix);
	FREE (m);
}

static void 
_growMatrix (tMatrix m, int numRows, int numCols)
{
int i, j;											// Grow the matrix to some 
													// arbitrary dimensions
	if (numCols > m->allocatedCols) 
		{											// Grow the existing rows 
     	for (i = 0; i < m->allocatedRows; i++) 		// to numCols
			{
			m->matrix[i] = realloc(m->matrix[i], numCols * sizeof (BOOL));
      		for (j = m->allocatedCols; j < numCols; j++)
				m->matrix[i][j] = NO;
    		}
    	m->allocatedCols = numCols;
		}

	if (numRows > m->allocatedRows) 				// Grow the rows vector 
		{								 			
		m->matrix = realloc(m->matrix, numRows * sizeof (BOOL*));
													// Add cols to each new row
		for (i = m->allocatedRows; i < numRows; i++)
			m->matrix[i] = calloc(m->allocatedCols, sizeof(BOOL));
		m->allocatedRows = numRows;
		}

	m->numRows = numRows;
	m->numCols = numCols;
}

static void 
_insertRow (tMatrix m, int rowPosition)
{
int rows = m->numRows + 1;
int i;

	if (rows > m->allocatedRows) 					// Create space for the new
		{											// rows if necessary
		m->matrix = realloc(m->matrix, rows * sizeof(BOOL*));
		m->allocatedRows = rows;
  		}

	for (i = m->numRows; i > rowPosition; i--)		// Make room for new row
		m->matrix[i] = m->matrix[i - 1];
													// Create the required row
	m->matrix[rowPosition] = calloc(m->allocatedCols, sizeof(BOOL));
	m->numRows++;
}

static void 
_insertColumn (tMatrix m, int colPosition)
{
int cols = m->numCols + 1;
int i, j;

	if (cols > m->allocatedCols) 					// Grow each row to hold
		{											// `cols' elements
		for (i = 0; i < m->allocatedRows; i++)
			m->matrix[i] = realloc(m->matrix[i], cols * sizeof(BOOL));
		m->allocatedCols = cols;
		}

	for (i = 0; i < m->numRows; i++)
		{											// Move existing columns
		BOOL *row = m->matrix[i];					// beyond insertion point

		for (j = m->numCols; j > colPosition; j--)
			row[j] = row[j - 1];
		row[colPosition] = NO;						// default value of new col
		}

	m->numCols++;
}

static void 
_removeRow (tMatrix m, int row)
{
BOOL *r = m->matrix[row];
int i;
												// Shrink the matrix by moving 
	for (i = row; i < m->numRows - 1; i++)		// row to the end and reducing
		m->matrix[i] = m->matrix[i + 1];		// the number of active rows
	m->numRows--;
	m->matrix[m->numRows] = r;
}

static void 
_removeColumn (tMatrix m, int column)
{
int i, j;

	for (i = 0; i < m->numRows; i++) 
		{
		BOOL *row = m->matrix[i];
		
		for (j = column; j < m->numCols - 1; j++)
			row[j] = row[j + 1];
		row[m->numCols] = NO;
		}
	m->numCols--;
}

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
		selectedCells = _newMatrix(rows, cols);
		_cells = [[NSMutableArray alloc] initWithCapacity:size];
		for (i = 0; i < size; i++) 
			{ // generate cells
			NSCell *cell=[_cellPrototype copy];
			[_cells addObject:cell];
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
	_freeMatrix(selectedCells);

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

	_insertColumn(selectedCells, column);
	_numCols++;

	for (i = 0; i < _numRows; i++)
		[self makeCellAtRow:i column:column];

	if (_m.mode == NSRadioModeMatrix && !_m.allowsEmptySelect && !selectedCell)
		[self selectCellAtRow:0 column:0];
}

- (void) insertColumn:(int)column withCells:(NSArray*)cellArray
{
int i, j = column;

	if (column >= _numCols)
		[self renewRows:(_numRows = MAX(1, _numRows)) columns:column];
	
	_insertColumn(selectedCells, column);
	_numCols++;
	for (i = 0; i < _numRows; i++)
		[_cells insertObject:[cellArray objectAtIndex:i]
				atIndex:(j = i*_numCols + j)];

	if (_m.mode == NSRadioModeMatrix && !_m.allowsEmptySelect && !selectedCell)
		[self selectCellAtRow:0 column:0];
}

- (void) insertRow:(int)row
{
int i;

	if (row >= _numRows)
		[self renewRows:row columns:(_numCols = MAX(1, _numCols))];

	_insertRow(selectedCells, row);
	_numRows++;

	for (i = 0; i < _numCols; i++)
		[self makeCellAtRow:row column:i];

	if (_m.mode == NSRadioModeMatrix && !_m.allowsEmptySelect && !selectedCell)
		[self selectCellAtRow:0 column:0];
}

- (void) insertRow:(int)row withCells:(NSArray*)cellArray
{
int i, insertPoint;

	if (row >= _numRows)
		[self renewRows:row columns:(_numCols = MAX(1, _numCols))];

	_insertRow(selectedCells, row);
	_numRows++;
	insertPoint = row * _numCols;
	i = _numCols;

	while(i--)
		[_cells insertObject:[cellArray objectAtIndex:i] atIndex:insertPoint];

	if (_m.mode == NSRadioModeMatrix && !_m.allowsEmptySelect && !selectedCell)
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
	if((selectedRow == row) && (selectedColumn == column))
		selectedCell = newCell;

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

	_removeColumn(selectedCells, column);
	_numCols--;

	if (_numCols == 0)
		_numRows = 0;
	if (column == selectedColumn)
		{
		selectedCell = nil;
		[self selectCellAtRow:0 column:0];
		}
}

- (void) removeRow:(int)row
{
int i = _numCols, removalPoint = row * _numCols;

	if (row >= _numRows)
		return;

	while(i--)
		[_cells removeObjectAtIndex:removalPoint];

	_removeRow(selectedCells, row);
	_numRows--;

	if (_numRows == 0)
		_numCols = 0;
	if (row == selectedRow)
		{
		selectedCell = nil;
		[self selectCellAtRow:0 column:0];
		}
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
		}	}

	_numCols = newColumns;

	for (i = _numRows; i < newRows; i++) 
		for (j = 0; j < _numCols; j++)
			[self makeCellAtRow:i column:j];

	_numRows = newRows;
	_growMatrix(selectedCells, newRows, newColumns);
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
	if ((point.x < NSMinX(bounds)) || (point.y < NSMinY(bounds))
			|| (point.x > NSMaxX(bounds)) || (point.y > NSMaxY(bounds)))
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
	else
		if (*row >= _numRows)
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
	else
		if (*column >= _numCols)
			*column = _numCols - 1;

	return !(betweenRows || betweenCols);
}

- (BOOL) getRow:(int*)row column:(int*)column ofCell:(NSCell*)aCell
{
int i, j, count = [_cells count];
id array[count];

	[_cells getObjects:array];
	for (i = 0; i < _numRows; i++) 
		for (j = 0; j < _numCols; j++)
			if (array[((i * _numCols) + j)] == aCell)
				{
				*row = i;
				*column = j;

				return YES;
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
		if (value) 
			{
			selectedCell = aCell;						// select current cell
			selectedRow = row;
			selectedColumn = column;
			[selectedCell setState:1];
			((tMatrix)selectedCells)->matrix[row][column] = YES;
			}
		else 
			if (_m.allowsEmptySelect)
				[self deselectSelectedCell];
		}
	else
		[aCell setState:value];
	
	[self setNeedsDisplayInRect:[self cellFrameAtRow:row column:column]];
}

- (void) deselectAllCells
{
	if(_m.allowsEmptySelect || (_m.mode != NSRadioModeMatrix))
		{	
		BOOL focused = ([NSView focusView] == self);
		NSRect visible = (focused) ? [self visibleRect] : NSZeroRect;
		int i, j, count = [_cells count];
		id array[count];

		[_cells getObjects:array];
		for (i = 0; i < _numRows; i++)
			for (j = 0; j < _numCols; j++)
				if (((tMatrix)selectedCells)->matrix[i][j])
					{
					NSCell *c = array[((i * _numCols) + j)];

					[c setState:0];
					if (focused)
						{
						NSRect cr = [self cellFrameAtRow:i column:j];
						NSRect ir = NSIntersectionRect(cr, visible);

						if (NSWidth(ir) && NSHeight(ir))
							[c highlight:NO withFrame:cr inView:self];
						else
							[c setCellAttribute:NSCellHighlighted to:0];
						}
					((tMatrix)selectedCells)->matrix[i][j] = NO;
					}

		if (!focused)
			[self setNeedsDisplayInRect: visible];
		selectedCell = nil;
		selectedRow = 0;
		selectedColumn = 0;
		}
}
										// Don't allow loss of selection if in
- (void) deselectSelectedCell			// radio mode and empty selection is
{										// not allowed.
	if(!selectedCell || (!_m.allowsEmptySelect && _m.mode ==NSRadioModeMatrix))
		return;

	((tMatrix)selectedCells)->matrix[selectedRow][selectedColumn] = NO;
	[selectedCell setState:0];
	selectedCell = nil;
	selectedRow = 0;
	selectedColumn = 0;
}

- (void) selectAll:(id)sender
{
	int i, j, count = [_cells count];
	id array[count];

	[_cells getObjects:array];
	selectedCell = array[0];						// select cell at (0, 0)
	selectedRow = 0;
	selectedColumn = 0;

	while(count--)
		[array[count] setState:1];
	for (i = 0; i < _numRows; i++)
		for (j = 0; j < _numCols; j++)
			((tMatrix)selectedCells)->matrix[i][j] = YES;
	[self setNeedsDisplay];
}

- (void) selectCellAtRow:(int)row column:(int)column
{
	NSCell *aCell = [self cellAtRow:row column:column];

	if (!aCell)											// should not happen 
		return;											// but just in case

	if (selectedCell && selectedCell != aCell)
		{
		((tMatrix)selectedCells)->matrix[selectedRow][selectedColumn] = NO;
		[selectedCell setState:0];
		}

	selectedCell = aCell;								// select current cell
	selectedRow = row;
	selectedColumn = column;
	((tMatrix)selectedCells)->matrix[row][column] = YES;
	[selectedCell setState:1];
	
	[self setNeedsDisplayInRect:[self cellFrameAtRow:row column:column]];
}

- (BOOL) selectCellWithTag:(int)anInt
{
int i, j, count = [_cells count];
id array[count];

	[_cells getObjects:array];
	for (i = 0; i < _numRows; i++) 
		for (j = 0; j < _numCols; j++) 
			if([array[((i * _numCols) + j)] tag] == anInt)
				{
				[self selectCellAtRow:i column:j];
				return YES;
				}

	return NO;
}

- (NSArray*) selectedCells
{
NSMutableArray *array = [NSMutableArray array];
int i, j;

	for (i = 0; i < _numRows; i++) 
		for (j = 0; j < _numCols; j++)
			if (((tMatrix)selectedCells)->matrix[i][j])
				[array addObject:[_cells objectAtIndex:((i * _numCols) + j)]];

	return array;
}

- (void) _setState:(BOOL)state inRect:(MRect)matrix
{
int i = MAX(matrix.y - matrix.height, 0), j, count = [_cells count];
NSRect upperLeftRect = [self cellFrameAtRow:i column:matrix.x];
NSRect rect = upperLeftRect;
int maxX = MIN(matrix.x + matrix.width, _numCols);
id array[count];

	[_cells getObjects:array];
	for (; i <= matrix.y; i++) 
		{
		rect.origin.x = upperLeftRect.origin.x;
	
		for (j = matrix.x; j <= maxX; j++) 
			{
			NSCell *aCell = array[((i * _numCols) + j)];

			[aCell setState:state?NSOnState:NSOffState];
			[aCell highlight:state withFrame:rect inView:self];
			((tMatrix)selectedCells)->matrix[i][j] = YES;
			rect.origin.x += _cellSize.width + _interCell.width;
    		}
		rect.origin.y += _cellSize.height + _interCell.height;
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
		[self _setState:0 inRect:unselectRect[i]];
	for (i = 0; i < selectRectsNo; i++)
		[self _setState:1 inRect:selectRect[i]];
	[window flushWindow];
}

- (void) _setState:(BOOL)state startIndex:(int)start endIndex:(int)end
{
MPoint startPoint = POINT_FROM_INDEX(start);
MPoint endPoint = POINT_FROM_INDEX(end);
NSRect upperLeftRect = [self cellFrameAtRow:startPoint.y column:0];
NSRect rect = upperLeftRect;
int i, j = startPoint.x, colLimit;
float w = _cellSize.width + _interCell.width;
float h = _cellSize.height + _interCell.height;

	rect.origin.x = NSMinX(upperLeftRect) + j * w;
	for (i = startPoint.y; i <= endPoint.y; i++) 
		{
		colLimit = (i == endPoint.y) ? endPoint.x : _numCols - 1;
		
		for (; j <= colLimit; j++) 
			{
			NSCell *aCell = [_cells objectAtIndex:((i * _numCols) + j)];

			[aCell setState:state?NSOnState:NSOffState];
			[aCell highlight:state withFrame:rect inView:self];
			((tMatrix)selectedCells)->matrix[i][j] = YES;
			rect.origin.x += w;
			}
		j = 0;
		rect.origin = (NSPoint){NSMinX(upperLeftRect), NSMinY(rect) + h};
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
		[self _setState:0 startIndex:unselectPoint.x endIndex:unselectPoint.y];
	if (doSelect)
		[self _setState:1 startIndex:selectPoint.x endIndex:selectPoint.y];
	[window flushWindow];
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

- (id) cellAtRow:(int)row column:(int)column
{
	if (row < 0 || row >= _numRows || column < 0 || column >= _numCols)
		return nil;
	
	return [_cells objectAtIndex:((row * _numCols) + column)];
}

- (id) cellWithTag:(int)anInt
{
int count = [_cells count];
id array[count];

	[_cells getObjects:array];
	while(count--)
		if ([array[count] tag] == anInt)
			return array[count];

	return nil;
}

- (id) selectTextAtRow:(int)row column:(int)column
{
	NSLog(@" NSMatrix: selectTextAtRow --- ");

	[self selectCellAtRow:row column:column];
	if (row == selectedRow && column == selectedColumn)
		{
		if ([selectedCell isSelectable])
			{
			[self selectText:self];

			return selectedCell;
		}	}

	return nil;
}

- (void) selectText:(id)sender
{
	NSLog(@" NSMatrix: selectText --- ");

	if (selectedCell && [selectedCell isEditable] && [selectedCell isEnabled])
		{
		NSRect r = [self cellFrameAtRow:selectedRow column:selectedColumn];
		NSText *t = [window fieldEditor:YES forObject:selectedCell];

		[selectedCell selectWithFrame:r
					  inView:self
					  editor:t	
					  delegate:self	
					  start:(int)0	 
					  length:(int)0];

//		[window makeFirstResponder: t];
		}
}

- (void) setNextText:(id)anObject			{ NIMP; }
- (void) setPreviousText:(id)anObject		{ NIMP; }
- (id) nextText								{ return nil; }
- (id) previousText							{ return nil; }

- (void) textDidBeginEditing:(NSNotification *)aNotification
{
	// FIXME: add NSFieldEditor to the notification user info
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidBeginEditing) object: self];
}

- (void) textDidChange:(NSNotification *)aNotification
{
	if (selectedCell && [selectedCell respondsToSelector:@selector(textDidChange:)])
		return [selectedCell textDidChange:aNotification];
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidChange) object: self];
}

- (void) textDidEndEditing:(NSNotification *)aNotification
{
NSNumber *code;

	NSLog(@" NSMatrix textDidEndEditing ");

	// FIXME: add NSFieldEditor to the userInfo
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidEndEditing) object: self];

	[selectedCell endEditing:[aNotification object]];			

	if((code = [[aNotification userInfo] objectForKey:NSTextMovement]))
		switch([code intValue])
			{
			case NSReturnTextMovement:
				[window makeFirstResponder:self];
				if(![self sendAction])
					[self sendAction:[self action] to:[self target]];
				break;
			case NSTabTextMovement:					// FIX ME select next cell
			case NSBacktabTextMovement:
				
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
	NSLog(@" NSMatrix textShouldEndEditing ");

	if(![window isKeyWindow])
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
	[[selectedCell target] performSelector:_errorAction withObject:self];
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
	// FIXME: potential stack overflow!!!
	
	int count = [_cells count];
	id array[count];

	[_cells getObjects:array];
	while(count--)
		[array[count] setScrollable:flag];

	[_cellPrototype setScrollable:flag];
}

- (void) drawRect:(NSRect)rect
{
	int i, j;
	int row1, col1;								// cell at the upper left corner
	int row2, col2;								// cell at the lower right corner
	NSRect cellRect, upperLeftRect;
	NSPoint p = {NSMaxX(rect), NSMaxY(rect)}; 
	NSSize inc = {_cellSize.width + _interCell.width,
		_cellSize.height + _interCell.height};
	
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
	cellRect = upperLeftRect = [self cellFrameAtRow:row1 column:col1];
	for (i = row1; i <= row2; i++) 					// Draw the cells within 
		{											// the drawing rectangle.
		for (j = col1; j <= col2; j++)
			{
			NSCell *aCell = [_cells objectAtIndex:((i * _numCols) + j)];

			[aCell drawWithFrame:cellRect inView:self];
			cellRect.origin.x += inc.width;
			}
		cellRect.origin.x = upperLeftRect.origin.x;
		cellRect.origin.y += inc.height;
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
		[aCell highlight:flag
			   withFrame:[self cellFrameAtRow:row column:column]
			   inView:self];
}

- (BOOL) sendAction
{
	SEL cellAction;

	if (!selectedCell || ![selectedCell isEnabled])
		return NO;

	if ((cellAction = [selectedCell action])) 
		{
		id cellTarget = [selectedCell target];

		if (cellTarget)
			{
			if ((_m.mode != NSTrackModeMatrix) && (_m.mode != NSHighlightModeMatrix))
				[cellTarget performSelector:cellAction withObject:self];
			else
				return NO;
			}
		else
			{
			if(!_target)
				return NO;
			[_target performSelector:cellAction withObject:self];	// ??? is this like Cocoa?
		}	}
	else
		{
		if(!_target || !_action)
			return NO;
		[_target performSelector:_action withObject:self];
		}
	
	return YES;
}

- (void) sendDoubleAction
{
	if (!selectedCell || ![selectedCell isEnabled])
		return;

	if (_target && _doubleAction)
		[_target performSelector:_doubleAction withObject:self];
	else
		[self sendAction];
}

- (void) sendAction:(SEL)aSelector to:(id)anObject forAllCells:(BOOL)flag
{
int i, j;
NSCell *c;

	if (flag) 
		{
		for (i = 0; i < _numRows; i++) 
			for (j = 0; j < _numCols; j++)
				{
				c = [_cells objectAtIndex:((i * _numCols) + j)];
				if (![anObject performSelector:aSelector withObject:c])
					return;
		}		}
	else 
		{
		for (i = 0; i < _numRows; i++) 
			for (j = 0; j < _numCols; j++)
				if (((tMatrix)selectedCells)->matrix[i][j])
					{
					c = [_cells objectAtIndex:((i * _numCols) + j)];
					if (![anObject performSelector:aSelector withObject:c])
						return;
		}			}
}

- (BOOL) acceptsFirstMouse:(NSEvent*)event
{
	return _m.mode == NSListModeMatrix ? NO : YES;
}

- (void) mouseDown:(NSEvent*)event
{
	int row, column, clickCount;
	// int periodCount = 0;
	NSPoint location;
	NSRect rect;
	NSRect previousCellRect;
	id aCell;
	id previousCell = nil;
	static MPoint anchor = {0, 0};
	
	if ((clickCount = [event clickCount]) > 1)
		{
		if(_target && _doubleAction && clickCount == 2)			// double click
			[_target performSelector:_doubleAction withObject:self];
		return;
		}

	_mouseDownFlags = [event modifierFlags];
	location = [self convertPoint:[event locationInWindow] fromView:nil];

	while([event type] != NSLeftMouseUp)	// loop outside until mouse goes up 
		{
		BOOL inCell;
		if ((inCell = [self getRow:&row column:&column forPoint:location]))
			{
			BOOL done = NO;
			aCell = [self cellAtRow:row column:column];		// which cell did we hit?
			rect = [self cellFrameAtRow:row column:column];	// the cell rect
			
			switch (_m.mode) 
				{
				case NSTrackModeMatrix:				// in Track mode the cell
					{
						done = [aCell trackMouse:event			
										  inRect:rect					
										  ofView:self				
									untilMouseUp:[[_cell class] prefersTrackingUntilMouseUp]];			// YES if mouse went up in cell
						break;
					}
				case NSHighlightModeMatrix:			// Highlight mode is like Track mode except that
				case NSRadioModeMatrix:
					{
						// [aCell highlight: YES withFrame: rect inView: self];
						// [window flushWindow];
						[aCell setHighlighted:YES];
						[self setNeedsDisplayInRect:rect];
						done = [aCell trackMouse:event			 
										  inRect:rect					
										  ofView:self				
									untilMouseUp:[[_cell class] prefersTrackingUntilMouseUp]];			// YES if mouse went up in cell
						// [aCell highlight: NO withFrame: rect inView: self];
						// [window flushWindow];
						[aCell setHighlighted:NO];
						[self setNeedsDisplayInRect:rect];
						break;
					}

				// FIXME:
				
				case NSListModeMatrix: 			 		// List mode allows multiple cells to be
					{									// selected
						unsigned modifiers = [event modifierFlags];
						
						if (previousCell == aCell)
							break;			// When the user first clicks on a cell 
													// we clear the existing selection 
						if (!previousCell) 	// unless the Alternate or Shift keys
							{				// have been pressed.
							if (!(modifiers & NSShiftKeyMask) 
									&& !(modifiers & NSAlternateKeyMask))
								{
								[self deselectAllCells];
								anchor = (MPoint){column, row};
								}			// Consider the selected cell as the 
											// anchor from which to extend the 
											// selection to the current cell
							if (!(modifiers & NSAlternateKeyMask))
								{
								selectedCell = aCell;		// select current cell
								selectedRow = row;
								selectedColumn = column;
								
								[aCell setState:NSOnState];
								[aCell setHighlighted:YES];
								[self setNeedsDisplayInRect:rect];
								//							[aCell highlight:YES withFrame:rect inView:self];
								if(selectedCells)
									((tMatrix)selectedCells)->matrix[row][column] =YES;
								//							[window flushWindow];
								break;
								}
							}
						
						if (_m.selectionByRect)
							[self _selectRectUsingAnchor:anchor
													last:(MPoint){selectedColumn, selectedRow}
												 current:(MPoint){column, row}];
						else
							[self _selectContinuousUsingAnchor:anchor
														  last:(MPoint){selectedColumn, selectedRow}
													   current:(MPoint){column, row}];
						
						//				[window flushWindow];
						selectedCell = aCell;				// select current cell
						selectedRow = row;
						selectedColumn = column;
						break;
					}
				}
			previousCell = aCell;
			previousCellRect = rect;
			[self scrollRectToVisible:rect];
			if (done)										
				{ // if mouse went up in this cell
				if(_m.mode == NSRadioModeMatrix && selectedCell && (selectedCell != aCell))					
					{ // deselect previously selected radio button
					[selectedCell setState:NSOffState];
					[self setNeedsDisplayInRect:[self cellFrameAtRow:selectedRow column:selectedColumn]];
					if(selectedCells)
						((tMatrix)selectedCells)->matrix[selectedRow][selectedColumn] = NO;	
					}
				selectedCell = aCell;			// change selection
				selectedRow = row;
				selectedColumn = column;
				if(selectedCell)
					{ // Finish the selection process
					if(_m.mode == NSRadioModeMatrix)
						{ // keep selected
						[selectedCell setState:NSOnState];
						[self setNeedsDisplayInRect:rect];
						}
					if(selectedCells)
						((tMatrix)selectedCells)->matrix[row][column] = YES;
					}
				if(![selectedCell action] || ![selectedCell target]) 
					[self sendAction];	// cell did not have a private action
				if([selectedCell isEditable])		// if cell is editable
					[self selectText:self];			// begin editing
				break;	// break loop
				}
			}
		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:[NSDate distantFuture]
									  inMode:NSEventTrackingRunLoopMode
									 dequeue:YES];

		NSDebugLog(@"Matrix: got event of type: %d\n", [event type]);
		}
}

- (void) updateCell:(NSCell *)aCell
{
	// FIXME: if cell has focus, redraw focus ring
	[self updateCellInside:aCell];
}

- (void) updateCellInside:(NSCell *)aCell
{ // same...
	int r, c;	// attempt to update only the cell and not the hole matrix
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
				NSCell *oldSelectedCell = selectedCell;
		
				selectedCell = c;
				[self lockFocus];
				[self highlightCell:YES atRow:i column:j];
				[window flushWindow];
				[c setState:(![c state])?NSOnState:NSOffState];	// toggle
				[self sendAction];
				[self highlightCell:NO atRow:i column:j];
				[window flushWindow];
				[self unlockFocus];
				selectedCell = oldSelectedCell;
				
				return YES;
			}	}
	
	return NO;
}

- (void) resetCursorRects
{
int i, j;

	for (i = 0; i < _numRows; i++) 
		for (j = 0; j < _numCols; j++) 
			{
			NSCell *c = [_cells objectAtIndex:((i * _numCols) + j)];

			[c resetCursorRect:[self cellFrameAtRow:i column:j] inView:self];
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
- (void) setAction:(SEL)aSelector			{ _action = aSelector; }
- (void) setDoubleAction:(SEL)aSelector		{ _doubleAction = aSelector; }
- (void) setErrorAction:(SEL)sel			{ _errorAction = sel; }
- (SEL) action								{ return _action; }
- (SEL) doubleAction						{ return _doubleAction; }
- (SEL) errorAction							{ return _errorAction; }
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
- (id) selectedCell							{ return selectedCell; }
- (int) selectedColumn						{ return selectedColumn; }
- (int) selectedRow							{ return selectedRow; }
- (int) mouseDownFlags		   				{ return _mouseDownFlags; }
- (BOOL) isFlipped							{ return YES; }
- (BOOL) acceptsFirstResponder				{ return YES; }

- (BOOL) becomeFirstResponder
{
	return [selectedCell isSelectable];
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
		selectedCells = _newMatrix(_numRows, _numCols);
		_cellPrototype = [[aDecoder decodeObjectForKey:@"NSProtoCell"] retain];
		selectedColumn = [aDecoder decodeIntForKey:@"NSSelectedCol"];
		selectedRow = [aDecoder decodeIntForKey:@"NSSelectedRow"];
		selectedCell = [aDecoder decodeObjectForKey:@"NSSelectedCell"];	// not retained
		[self selectCellAtRow:selectedRow column:selectedColumn];	// set selected cell
		// what about target, action, doubleAction, errorAction
#if 0
		NSLog(@"%@ initWithCoder:%@", self, aDecoder]);
#endif
		return self;
		}
	return self;
}

@end /* NSMatrix */
