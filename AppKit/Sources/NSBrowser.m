/* 
   NSBrowser.m

   Control to display and access hierarchal data

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:	Felipe A. Rodriguez <far@pcmagic.net>
   Date:	March 1999
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSEnumerator.h>

#import <AppKit/NSBrowser.h>
#import <AppKit/NSBrowserCell.h>
#import <AppKit/NSScroller.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSTextFieldCell.h>

#import "NSAppKitPrivate.h"

#define COLUMN_SEP	 6
#define BORDER_WIDTH 4							// border width assumes bezeled

#define VISIBLE_COUNT		 (_firstVisibleColumn + _numberOfVisibleColumns)
#define LAST_VISIBLE_COLUMN  (VISIBLE_COUNT - 1)
#define COLUMN_IS_VISIBLE(c) ((c >= _firstVisibleColumn) && c < VISIBLE_COUNT)


@implementation NSBrowser

+ (Class) cellClass							{ return [NSBrowserCell class]; }

- (id) initWithFrame:(NSRect)rect
{
	float sw = [NSScroller scrollerWidth];
	if((self=[super initWithFrame: rect]))
		{
		[self setCell:[[NSTextFieldCell new] autorelease]];	// (re)define title cell
		//	[_cell setTextColor: [NSColor whiteColor]];
		//	[_cell setBackgroundColor: [NSColor darkGrayColor]];
		// alignment
		[self setCellPrototype:[[[[self class] cellClass] new] autorelease]];
		_matrixClass = [NSMatrix class];
		_pathSeparator = @"/";

		_br.allowsBranchSelection = YES;
		_br.allowsEmptySelection = YES;
		_br.allowsMultipleSelection = YES;
		_br.separatesColumns = YES;
		_br.titleFromPrevious = YES;
		_br.isTitled = YES;
		_br.hasHorizontalScroller = YES;
		_br.acceptArrowKeys = YES;
		_br.sendActionOnArrowKeys = YES;
		_br.reuseColumns = YES;
		
		_minColumnWidth = (sw + BORDER_WIDTH);
		
		_scroller = [[NSScroller alloc] initWithFrame: (NSRect){{0,0},{NSWidth(_frame),sw}}];
		[_scroller setTarget: self];
		[_scroller setAction: @selector(scrollViaScroller:)];
		[_scroller setAutoresizingMask: NSViewWidthSizable];
		[self addSubview: _scroller];
		
		_titles = [NSMutableArray new];
		_columns = [NSMutableArray new];
		_unusedColumns = [NSMutableArray new];

		[self tile];
		[self setMaxVisibleColumns:1];  // default
		}
	return self;
}

- (void) dealloc
{
	[_cellPrototype release];
	[_pathSeparator release];
	[_scroller release];
	[_columns release];
	
	[super dealloc];
}

- (BOOL) sendAction		
{
	NSLog(@"NSBrowser sendAction %@ to %@", NSStringFromSelector([self action]), [self target]);
	return [self sendAction:[self action] to:[self target]];
}

- (SEL) doubleAction					{ return _doubleAction; }
- (id) cellPrototype					{ return _cellPrototype; }
- (Class) matrixClass					{ return _matrixClass; }
- (NSString*) pathSeparator				{ return _pathSeparator; }
- (int) numberOfVisibleColumns			{ return _numberOfVisibleColumns; }
- (int) lastVisibleColumn				{ return LAST_VISIBLE_COLUMN; }
- (float) minColumnWidth				{ return _minColumnWidth; }
- (int) firstVisibleColumn				{ return _firstVisibleColumn; }
- (int) maxVisibleColumns				{ return _maxVisibleColumns; }
- (BOOL) isTitled						{ return _br.isTitled; }
- (BOOL) separatesColumns				{ return _br.separatesColumns; }
- (BOOL) isLoaded						{ return _isLoaded; }
- (BOOL) reusesColumns					{ return _br.reuseColumns; }
- (BOOL) takesTitleFromPreviousColumn	{ return _br.titleFromPrevious; }
- (BOOL) allowsBranchSelection			{ return _br.allowsBranchSelection; }
- (BOOL) allowsEmptySelection			{ return _br.allowsEmptySelection; }
- (BOOL) allowsMultipleSelection		{ return _br.allowsMultipleSelection; }
- (BOOL) sendsActionOnArrowKeys			{ return _br.sendActionOnArrowKeys; }
- (BOOL) acceptsArrowKeys				{ return _br.acceptArrowKeys; }
- (BOOL) hasHorizontalScroller			{ return _br.hasHorizontalScroller; }
- (void) setAcceptsArrowKeys:(BOOL)flag	{ _br.acceptArrowKeys = flag; }
- (void) setPathSeparator:(NSString *)a	{ ASSIGN(_pathSeparator, a); }
- (void) setReusesColumns:(BOOL)flag	{ _br.reuseColumns = flag; }
- (void) setCellPrototype:(NSCell *)c	{ ASSIGN(_cellPrototype, c); }
- (void) setMatrixClass:(Class)classId	{ _matrixClass = classId; }
- (void) setDoubleAction:(SEL)aSelector	{ _doubleAction = aSelector; }

- (void) setCellClass:(Class)classId
{
	[self setCellPrototype: [[[classId alloc] init] autorelease]];
}

- (void) setTakesTitleFromPreviousColumn:(BOOL)flag
{
	_br.titleFromPrevious = flag;
}

- (void) setAllowsEmptySelection:(BOOL)flag
{
	_br.allowsEmptySelection = flag;
}

- (void) setAllowsBranchSelection:(BOOL)flag
{
	_br.allowsBranchSelection = flag;
}

- (void) setAllowsMultipleSelection:(BOOL)flag
{
	_br.allowsMultipleSelection = flag;
}

- (void) setSendsActionOnArrowKeys:(BOOL)flag
{
	_br.sendActionOnArrowKeys = flag;
}

- (void) setHasHorizontalScroller:(BOOL)flag
{
	if (_br.hasHorizontalScroller != flag)
		{
		if (!(_br.hasHorizontalScroller = flag))
			{
			[_scroller retain];
			[_scroller removeFromSuperview];
			}

		[self tile];
		}
}

- (void) setSeparatesColumns:(BOOL)flag
{
	if (_br.separatesColumns != flag)
		{
		_br.separatesColumns = flag;
		[self tile];
		}
}

- (void) setTitled:(BOOL)flag
{
	_br.isTitled = flag;
	[self tile];
}

- (void) _updateScrollView:(NSScrollView *)sc
{
id matrix = [sc documentView];
													// Adjust matrix to fit in
	if (sc && matrix)								// scrollview do so only if 	
		{											// column has been loaded
		NSSize ms = [matrix cellSize];
		NSSize cs = [sc contentSize];

		if(ms.width != cs.width)
			{
			ms.width = cs.width;
			[matrix setCellSize: ms];
			[matrix sizeToCells];
		}	}
}

- (void) _updateColumnFrames
{
int count = [_columns count];

	while (count-- > 0)
		{
		NSScrollView *sc = [_columns objectAtIndex: count];

		if (COLUMN_IS_VISIBLE(count))
			{
			if (![sc superview])				// Add as subview if necessary
				[self addSubview: sc];
			[sc setFrame: [self frameOfInsideOfColumn: count]];
			[self _updateScrollView: sc];
			}
		else									// If it is not visible remove
			if ([sc superview])					// it from it's superview 
				[[sc retain] removeFromSuperview];
		}
}

- (float) titleHeight
{
//	return [_cell cellSize].height;

	return 24;
}

- (int) lastColumn
{
int i, count = [_columns count];				// Find the last loaded column
												// A column is loaded if it has
	for (i = 0; i < count; ++i)					// a doc view matrix.
		if (![[_columns objectAtIndex: i] documentView])
			break;

	return MAX(0, i-1);
}

- (int) columnOfMatrix:(NSMatrix *)matrix
{												// Find the column that has
	int i, count = [_columns count];				// matrix as it's doc view

	for (i = 0; i < count; ++i)
		if (matrix == [[_columns objectAtIndex: i] documentView])
			return i;

	return NSNotFound;
}

- (int) selectedColumn
{
int i = [_columns count] - 1;

	for (;(i >= 0); i--)
		if ([[[_columns objectAtIndex:i] documentView] selectedCell])
			return i;

	return NSNotFound;
}

- (void) setMaxVisibleColumns:(int)columnCount
{
	int i = [_columns count];
	_maxVisibleColumns = columnCount;
	if(i > _maxVisibleColumns)
		NSLog(@"can't reduce numberOfVisibleColumns yet");  // FIX ME reduce numberOfVisible if > new max
	while(i++ < _maxVisibleColumns)		// Create additional columns if necessary
		[self addColumn];
	[self tile];
}

- (void) setMinColumnWidth:(float)columnWidth
{
float sw = [NSScroller scrollerWidth];
float bw = 4;									// assume bezeled border width

	if (_br.separatesColumns)					// Take the border into account
		sw += bw;
												// width min = scroller+border
	_minColumnWidth = (columnWidth < sw) ? (int)sw : columnWidth;	

	[self tile];
}

- (void) addColumn
{
	int c = [_columns count];
	NSScrollView *sc;

	sc = [[NSScrollView alloc] initWithFrame: [self frameOfInsideOfColumn: c]];
	[sc setHasHorizontalScroller: NO];
	[sc setHasVerticalScroller: YES];
	[self addSubview: sc];
	[_columns addObject: sc];
	[_titles addObject: @""];
}

- (void) displayAllColumns
{
int i, count = [_columns count];

	for (i = 0; i < count; ++i)
		[self setNeedsDisplayInRect: [self frameOfInsideOfColumn:i]];
	if(_br.isTitled)
		for (i = 0; i < count; ++i)
			[self setNeedsDisplayInRect: [self titleFrameOfColumn: i]];
}

- (void) displayColumn:(int)column			// FIX ME should display col not
{											// just the title
	if (!(COLUMN_IS_VISIBLE(column)))
		return;

	if([[_columns objectAtIndex: column] documentView])
		{ // Ask the delegate for the column title
		if([_delegate respondsToSelector:@selector(browser:titleOfColumn:)])
			[self setTitle: [_delegate browser: self
									   titleOfColumn: column]
									   ofColumn: column];
		else
			{ // Check if we take title from previous column
			if (_br.titleFromPrevious)
				{ // If first column then use the path separator
				if (column == 0)
					[self setTitle: _pathSeparator ofColumn: 0];
				else			// Get the selected cell. Use its string value
					{			// as the title Only if it is not a leaf
					id c = [self selectedCellInColumn: column - 1];
	
					if ([c isLeaf] || ![c stringValue])
						[self setTitle: @"" ofColumn: column];
					else
						[self setTitle: [c stringValue] ofColumn: column];
				}	}
			else
				[self setTitle: @"" ofColumn: column];
		}	}

	[self drawTitle: [_titles objectAtIndex: column]	// Draw the title
		  inRect: [self titleFrameOfColumn: column]
		  ofColumn: column];
}

- (void) loadColumnZero
{
	[self reloadColumn: 0];
	[self setLastColumn: 0];					// set the last column loaded
	_isLoaded = YES;
	[self tile];
}

- (void) reloadColumn:(int)column
{ // Make sure the column exists
int i, rows = 0, cols = 0;
NSMatrix *m = nil;
NSScrollView *sc;
#if 1
	NSLog(@"reloadColumn:%d", column);
#endif
	if (column >= (int)[_columns count])
		return;

	sc = [_columns objectAtIndex: column];
	if (!_br.delegateCreatesRowsInMatrix)
		{
		rows = [_delegate browser:self numberOfRowsInColumn:column];
		cols = 1;
		}

	if (_br.reuseColumns)
		if (!(m = [sc documentView]) && [_unusedColumns count])
			{
			[sc setDocumentView: (m = [_unusedColumns objectAtIndex: 0])];
			[_unusedColumns removeObjectAtIndex: 0];
			}

	if (!m)
		{ // create a new column matrix
		unsigned int mode = _br.allowsMultipleSelection
							? NSListModeMatrix : NSRadioModeMatrix;

		m = [[_matrixClass alloc] initWithFrame: (NSRect){{0,0},{100,100}}
								  mode: mode
								  prototype: _cellPrototype
								  numberOfRows: rows
								  numberOfColumns: cols];
		[m setAllowsEmptySelection: _br.allowsEmptySelection];
		[m setTarget: self];
		[m setAction: @selector(doClick:)];
		[m setDoubleAction: @selector(doDoubleClick:)];
		[sc setDocumentView: m];
		[m release];	// should have been retained by setDocumentView
		}
	else
		[m renewRows:rows columns: 1];

	if (!_br.delegateCreatesRowsInMatrix)		// Load from passive delegate
		{										
		for (i = 0; i < rows; ++i)				// loop thru cells loading each
			[self loadedCellAtRow: i column: column];
		}										// Load from active delegate
	else										// Ask delegate to create rows
		[_delegate browser:self createRowsForColumn:column inMatrix:m];

	[self _updateScrollView: sc];

	[self setNeedsDisplayInRect: [self frameOfInsideOfColumn:column]];
}

- (void) selectAll:(id)sender
{
	if (_br.allowsMultipleSelection)
		[[self matrixInColumn: [self lastVisibleColumn]] selectAll: sender];
}

- (void) setLastColumn:(int)column		
{ 
	NSMatrix *matrix;
#if 1
	NSLog(@"NSBrowser setLastColumn: %d  count: %d \n", column, [_columns count]);
#endif
	if (column >= (int)[_columns count])
		return;
	if ((matrix = [[_columns objectAtIndex: column] documentView]))
		{
		int i, count = [_columns count];

		for (i = (column + 1); i < count; ++i)
			{
			NSScrollView *s = [_columns objectAtIndex: i];
	
			if ([s documentView])
				{
				if (_br.reuseColumns)
					[_unusedColumns addObject: [s documentView]];
	
				[s setDocumentView: nil];
				[self setTitle: @"" ofColumn: i];
				[self setNeedsDisplayInRect: [self frameOfInsideOfColumn: i]];
			}	}

		if (!(COLUMN_IS_VISIBLE(column)))
			[self scrollColumnToVisible: column];
		[self updateScroller];
		}
}

- (void) validateVisibleColumns
{
int i;
										// xxx Should we trigger an exception?
	if (![_delegate respondsToSelector:@selector(browser:isColumnValid:)])
		return;	
										// Loop through the visible columns
	for (i = _firstVisibleColumn; i <= LAST_VISIBLE_COLUMN; ++i)
		{
		BOOL v = [_delegate browser: self isColumnValid: i];
										// Ask delegate if the column is valid 
		if (!v)							// and if not then reload the column
			[self reloadColumn: i];
		}
}

- (void) drawTitle:(NSString *)title 
			inRect:(NSRect)aRect
			ofColumn:(int)column
{
	if (_br.isTitled && COLUMN_IS_VISIBLE(column))
		{
		[_cell setStringValue: title];
		[_cell drawWithFrame: aRect inView: self];
		}
}

- (void) setTitle:(NSString *)aString ofColumn:(int)column
{
	if (column < [_titles count])
		[_titles replaceObjectAtIndex:column withObject:aString];

	// fixme: this ends up in -displayIfNeeded recursion
	if (COLUMN_IS_VISIBLE(column))
		[self setNeedsDisplayInRect: [self titleFrameOfColumn: column]];
}

- (NSRect) titleFrameOfColumn:(int)column
{
float titleHeight = [self titleHeight];
NSRect r;
int n;

	if (!_br.isTitled)								// Not titled then no frame
		return NSZeroRect;
													// Number of columns over 
	n = column - _firstVisibleColumn;				// from the first
	
	r.origin.x = (n * _columnSize.width) + 2;		// Calculate the frame
	r.origin.y = _frame.size.height - titleHeight + 2;
	r.size.width = _columnSize.width - 4;
	r.size.height = titleHeight - 4;
	
	if (_br.separatesColumns)
		r.origin.x += n * COLUMN_SEP;
	
	return r;
}

- (NSString*) titleOfColumn:(int)column
{
	return [_titles objectAtIndex: column];
}

- (void) scrollColumnsLeftBy:(int)shiftAmount
{													// Cannot shift past the
	if ((_firstVisibleColumn - shiftAmount) < 0)	// zero column
		shiftAmount = _firstVisibleColumn;
	
	if (shiftAmount <= 0)
		return;
	
	if ([_delegate respondsToSelector: @selector(browserWillScroll:)])
		[_delegate browserWillScroll: self];		// Notify the delegate
	
	_firstVisibleColumn = _firstVisibleColumn - shiftAmount;
	[self _updateColumnFrames];						// Update scrollviews
	[self updateScroller];							// Update the scroller
														
	if ([_delegate respondsToSelector: @selector(browserDidScroll:)])
		[_delegate browserDidScroll: self];			// Notify the delegate

	[self displayAllColumns];
}

- (void) scrollColumnsRightBy:(int)shiftAmount
{
int lastColumnLoaded = [self lastColumn];			// Cannot shift past the
													// last loaded column
	if ((shiftAmount + LAST_VISIBLE_COLUMN) > lastColumnLoaded)
		shiftAmount = lastColumnLoaded - LAST_VISIBLE_COLUMN;
	
	if (shiftAmount <= 0)
		return;
	
	if ([_delegate respondsToSelector: @selector(browserWillScroll:)])
		[_delegate browserWillScroll: self];		// Notify the delegate
	
	_firstVisibleColumn = _firstVisibleColumn + shiftAmount;
	[self _updateColumnFrames];						// Update scrollviews
	[self updateScroller];							// Update the scroller
	
	if ([_delegate respondsToSelector: @selector(browserDidScroll:)])
		[_delegate browserDidScroll: self];			// Notify the delegate

	[self displayAllColumns];
}

- (void) scrollColumnToVisible:(int)column
{
int i;										// If col is last visible or number
											// of visible columns is greater 
	if (LAST_VISIBLE_COLUMN == column)		// than number loaded do nothing
		return;
	if (_firstVisibleColumn ==0 && [self lastColumn] < _numberOfVisibleColumns)
		return;

	if ((i = LAST_VISIBLE_COLUMN - column) > 0)
		[self scrollColumnsLeftBy: i];
	else
		[self scrollColumnsRightBy: (-i)];
}

- (void) scrollViaScroller:(NSScroller *)sender
{
	NSScrollerPart h = [sender hitPart];

	if ((h == NSScrollerDecrementLine) || (h == NSScrollerDecrementPage))
		[self scrollColumnsLeftBy: 1];					// Scroll to the left
	else if ((h == NSScrollerIncrementLine) || (h == NSScrollerIncrementPage))
		[self scrollColumnsRightBy: 1];					// Scroll to the right
	else if ((h == NSScrollerKnob) || (h == NSScrollerKnobSlot))
		{
		int i = rint([sender floatValue] * [self lastColumn]);

		[self scrollColumnToVisible: i];
		}
}

- (void) updateScroller			// If there are not enough columns to scroll
{								// with then the column must be visible
int lastColumnLoaded = [self lastColumn];

	if((lastColumnLoaded == 0) || (lastColumnLoaded < _numberOfVisibleColumns))
		{									// disable horiz scroller only if
		if(_firstVisibleColumn == 0)		// browser's first col is visible
			[_scroller setEnabled: NO];
		}
	else
		{
		float p = (float)((float)_numberOfVisibleColumns 
							/ (float)(lastColumnLoaded + 1));
		float i = (lastColumnLoaded + 1) - _numberOfVisibleColumns;
		float f = 1 + ((LAST_VISIBLE_COLUMN - lastColumnLoaded) / i);

		[_scroller setFloatValue: f knobProportion: p];
		[_scroller setEnabled: YES];
		}

	return;
}

- (void) doClick:(id)sender					// handle a single click in a cell
{
	int column = [self columnOfMatrix: sender];
	BOOL shouldSelect = YES;
	NSArray *a;
											// If the matrix isn't ours then 
	if (column == NSNotFound)				// just return
		return;

	if (_br.delegateSelectsCellsByRow)		// Ask delegate if selection is ok
		{
		shouldSelect = [_delegate browser: self
								  selectRow: [sender selectedRow]
								  inColumn: column];
		}
	else if (_br.delegateSelectsCellsByString)	// Try the other method
		{
		id a = [[sender selectedCell] stringValue];

		shouldSelect = [_delegate browser:self
								  selectCellWithString:a
								  inColumn: column];
		}
	
	if (!shouldSelect)							// If we should not select cell
		{										// deselect it and return
		[sender deselectSelectedCell];
		return;
		}

	a = [sender selectedCells];
	
	if ([a count] == 1)							// If only one cell is selected
		{
		id c = [a objectAtIndex: 0];			
												// If the cell is a leaf then
		if ([c isLeaf])							// unload the columns after
			[self setLastColumn: column];
		else									// The cell is not a leaf so we 
			{									// need to load a column.  If 
			int next = column + 1;				// last column then add a col

			if (column == (int)([_columns count] - 1))
				[self addColumn];
												// Load column
			[self reloadColumn: next];
												// If this column is the last 
			if (column == LAST_VISIBLE_COLUMN)	// visible column then scroll 
				[self scrollColumnsRightBy: 1];	// right by one column
			else
				{
				[self setLastColumn: next];
				[self setNeedsDisplayInRect:[self titleFrameOfColumn: next]];
		}	}	}
	else										// If multiple selection then
		[self setLastColumn: column];			// we unload the columns after
	
	[self sendAction];							// Send action to the target
}


- (void) doDoubleClick:(id)sender				// Already handled the single
{												// click so send double action
	[self sendAction: _doubleAction to: [self target]];
}

- (id) loadedCellAtRow:(int)row column:(int)column		// FIX ME wrong
{
id c = nil;

	if (column < [_columns count])							// col range check
		{
		id matrix = [[_columns objectAtIndex: column] documentView];
		NSArray *columnCells = [matrix cells];

		if (row >= [columnCells count])						// row range check
			return nil;
		
		c = [matrix cellAtRow: row column: 0];				// Get the cell
		
		if (![c isLoaded])									// Load if not yet
			{												// loaded
			[_delegate browser:self willDisplayCell:c atRow:row column:column];
			[c setLoaded: YES];
		}	}
	
	return c;
}

- (NSMatrix*) matrixInColumn:(int)column
{
	return [[_columns objectAtIndex: column] documentView];
}

- (id) selectedCell
{
int i = [self selectedColumn];

	return (i == NSNotFound) ? nil : [[self matrixInColumn: i] selectedCell];
}

- (id) selectedCellInColumn:(int)column
{
	return [[self matrixInColumn: column] selectedCell];
}

- (void) selectRow:(int)row inColumn:(int)column;
{
	// CHECKME: are we really the same as a doClick or does doClick use us for all work besides sendAction?
	[self doClick:[[self matrixInColumn: column] cellAtRow:row column:0]];
}

- (int) selectedRowInColumn:(int)column
{
	return [[self matrixInColumn: column] selectedRow];
}

- (NSArray*) selectedCells
{
int i = [self selectedColumn];

	return (i == NSNotFound) ? nil : [[self matrixInColumn: i] selectedCells];
}

- (NSRect) frameOfColumn:(int)column
{													// Number of columns over
int n = column - _firstVisibleColumn;				// from the first 
NSRect r = {{n * _columnSize.width, 0}, _columnSize};

	if (_br.separatesColumns)
		r.origin.x += n * COLUMN_SEP;
													// Adjust for horizontal
	if (_br.hasHorizontalScroller)					// scroller
		r.origin.y = [NSScroller scrollerWidth] + 4;
	
	return r;
}

- (NSRect) frameOfInsideOfColumn:(int)column
{
NSRect r = [self frameOfColumn: column];

	return NSInsetRect(r, 2, 2);
}

- (BOOL) setPath:(NSString *)path					
{ 
	NSArray *subStrings = [path componentsSeparatedByString:_pathSeparator];
	int numberOfSubStrings, i, count = [_columns count] - 1;
#if 1
	NSLog(@"NSBrowser setPath:%@ -> %@", path, subStrings);
#endif

	if(!path)
		return NO;
	// this assumes that the delegate's data has not changed!
	if(_isLoaded)
		{
		[self setLastColumn: 0];
		[self scrollColumnsLeftBy: count + 1];			
		}
	else
		[self loadColumnZero];
	numberOfSubStrings = [subStrings count];
	if((numberOfSubStrings == 1) && [(NSString *)[subStrings objectAtIndex:0] length] == 0)	
		return YES;									// optimized root path sel

	for(i = 1; i < numberOfSubStrings; i++)			// cycle thru str's array
		{											// created from path
		NSMatrix *matrix = [[_columns objectAtIndex: i-1] documentView];
		NSArray *cells = [matrix cells];
		int j, k, numOfRows, numOfCols;
		NSBrowserCell *selectedCell, *matchingCell = nil;	
		NSString *a = [subStrings objectAtIndex:i];

		[matrix getNumberOfRows:&numOfRows columns:&numOfCols];

		for (j = 0; j < numOfRows; j++)				// find the cell in the
			for (k = 0; k < numOfCols; k++)			// browser matrix with
				{									// title equal to "a"
				selectedCell = [cells objectAtIndex:((j * numOfCols) + k)];	

				if([[selectedCell stringValue] isEqualToString: a])
					{
					int r, c;
	
					k = numOfCols;
					j = numOfRows;
					if([matrix getRow:&r column:&c ofCell:selectedCell])
						{
						[matrix selectCellAtRow:r column:c];
						matchingCell = selectedCell;
				}	}	}
													// if unable to find a cell
		if(!matchingCell)							// whose title matches "a"
			{										// return NO
			NSLog(@"NSBrowser: unable to find cell in matrix\n");
			return NO;
			}
													// if the cell is not a
		if(![matchingCell isLeaf])					// leaf add a column to the
			{										// browser for it
			if(i > count)
				[self addColumn];			
			[self reloadColumn: i];					// Load the column
			[self scrollColumnsRightBy: 1];			// scroll right by one col
			}
		else										// the cell is a leaf so we
			break;									// break out
		}
#if 0
	NSLog(@"setPath done");
#endif
	return YES; 
}

- (NSString*) path
{
	return [self pathToColumn: [_columns count]];
}

- (NSString*) pathToColumn:(int)column
{
NSMutableString *s = [_pathSeparator mutableCopy];
int i, lastColumnLoaded = [self lastColumn];
id c;

	if (column > lastColumnLoaded)
		column = lastColumnLoaded + 1;				// limit to loaded columns

	for (i = 0; i < column && (c = [self selectedCellInColumn: i]); i++)
		{
		if(i > 0)
			[s appendString: _pathSeparator];
		[s appendString: [c stringValue]];
		}

	return (NSString*)[s autorelease];
}

- (void) setFrame:(NSRect)frameRect
{
	NSDebugLog (@"NSBrowser setFrame");
  	[super setFrame:frameRect];
	[self tile];								// recalc browser's elements
}

- (void) setFrameSize:(NSSize)newSize
{
	NSDebugLog (@"NSBrowser setFrameSize:");
	[super setFrameSize:newSize];
	[self tile];								// recalc browser's elements
}

- (void) resizeWithOldSuperviewSize:(NSSize)oldSize		
{
	NSDebugLog (@"NSBrowser resizeWithOldSuperviewSize:");
	[super resizeWithOldSuperviewSize:oldSize];
	[self tile];								// recalc browser's elements
}

- (void) tile									// assume that frame and bounds
{												// have been set appropriately
int columnsPossible = (int)(NSWidth(_frame) / (_minColumnWidth + COLUMN_SEP));
int currentVisibleColumns = _numberOfVisibleColumns;
#if 1
	NSLog (@"NSBrowser tile");
#endif
	_numberOfVisibleColumns = MIN(_maxVisibleColumns, columnsPossible);

	if (_br.separatesColumns)
		_columnSize.width = ((NSWidth(_frame) - ((_numberOfVisibleColumns 
								- 1) * COLUMN_SEP)) / _numberOfVisibleColumns);
	else
		_columnSize.width = NSWidth(_frame) / (float)_numberOfVisibleColumns;
	_columnSize.width = ceil(_columnSize.width);
	_columnSize.height = _frame.size.height;
	
	if (_br.hasHorizontalScroller)						// Horizontal scroller
		_columnSize.height -= ([NSScroller scrollerWidth] + 4);

	if (_br.isTitled)									// Adjust for Title
		_columnSize.height -= [self titleHeight];
	
	if (_columnSize.height < 0)
		_columnSize.height = 0;

	if(currentVisibleColumns != _numberOfVisibleColumns)
		{
		if(_numberOfVisibleColumns > currentVisibleColumns)
			{
			if(_firstVisibleColumn > 0)
				{
				int c = _numberOfVisibleColumns - currentVisibleColumns;
				int d = MAX([_columns count] - currentVisibleColumns, 1);

				[self scrollColumnsLeftBy: MIN(d, c)];
				}
			else
				[_scroller setEnabled: NO];
			}
		else
			{
			int c = currentVisibleColumns - _numberOfVisibleColumns;

			if ([_columns count] > _numberOfVisibleColumns)
				[self scrollColumnsRightBy: c];
		}	}

	[self _updateColumnFrames];
}

- (void) drawRect:(NSRect)rect
{
int i;
 
	if (!_isLoaded)						// Load the first column if not already
		{								// loaded
		[self loadColumnZero];
		[self displayColumn: 0];
		[self displayAllColumns];
		}
										// Loop through the visible columns
	for (i = _firstVisibleColumn; i <= LAST_VISIBLE_COLUMN; ++i)
		{							 
		NSRect r = NSIntersectionRect([self titleFrameOfColumn: i], rect);

		if (! NSIsEmptyRect(r))			// If the column title intersects with
			[self displayColumn: i];	// the rect to be drawn then draw that
		}								// column
}	

- (void) mouseDown:(NSEvent*)event				{ return; }		// ignore events for the browser frame
- (void) drawCell:(NSCell *)aCell				{ NIMP; }		// override NSControl's
- (void) drawCellInside:(NSCell *)aCell			{ NIMP; }		// defaults
- (void) selectCell:(NSCell *)aCell				{ NIMP; }
// - (void) updateCell:(NSCell *)aCell			{ NIMP; }
- (void) updateCellInside:(NSCell *)aCell		{ NIMP; }

- (id) delegate									{ return _delegate; }

- (void) setDelegate:(id)anObject
{ // you can't set the delegate to nil!
SEL s = @selector(browser:willDisplayCell:atRow:column:);
SEL a = @selector(browser:createRowsForColumn:inMatrix:);
SEL n = @selector(browser:numberOfRowsInColumn:);

	if ([anObject respondsToSelector:n])
		{
		_br.delegateCreatesRowsInMatrix = NO;			// Passive delegate

		if ([anObject respondsToSelector: a])
			[NSException raise: NSBrowserIllegalDelegateException
						 format: @"Delegate %@ responds to both %@ and %@", anObject, NSStringFromSelector(a), NSStringFromSelector(n)];
		}
	else
		{
		_br.delegateCreatesRowsInMatrix = YES;			// Active delegate

		if (![anObject respondsToSelector: a])
			[NSException raise: NSBrowserIllegalDelegateException
						 format: @"Delegate %@ does not respond to %@ or %@", anObject, NSStringFromSelector(a), NSStringFromSelector(n)];
		}

	if ([anObject respondsToSelector: s])
		_br.delegateImplementsWillDisplayCell = YES;
	else
		if (!_br.delegateCreatesRowsInMatrix)
			[NSException raise: NSBrowserIllegalDelegateException
						 format: @"Passive delegate %@ must respond to %@", anObject, NSStringFromSelector(n)];

	s = @selector(browser:selectRow:inColumn:);
	_br.delegateSelectsCellsByRow = ([anObject respondsToSelector: s]);
	s = @selector(browser:selectCellWithString:inColumn:);
	_br.delegateSelectsCellsByString = ([anObject respondsToSelector: s]);
	s = @selector(browser:titleOfColumn:);
	_br.delegateSetsTitles = ([anObject respondsToSelector: s]);

	[super setDelegate:anObject];	// NSControl's private method
#if 0	// this causes trouble if awakeFromNib wants to set a subclass for cellPrototype!
	// we might better set up some 'needs reload' flag which triggers a loadColumnZero in drawRect:
	if(_isLoaded)
		{ // reload column zero if delegate has changed
		[self loadColumnZero];
		}
#endif
}

- (void) encodeWithCoder:(NSCoder *)aCoder						// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
}

- (id) initWithCoder:(NSCoder *)coder
{
	self=[super initWithCoder:coder];
	if([coder allowsKeyedCoding])
		{
		int brFlags=[coder decodeInt32ForKey:@"NSBrFlags"];
		[self setCell:[[NSTextFieldCell new] autorelease]];	// (re)define title cell
// FIXME: should be decoded from the bits of brFlags
		_br.allowsBranchSelection = YES;
		_br.allowsEmptySelection = YES;
		_br.allowsMultipleSelection = YES;
		_br.separatesColumns = YES;
		_br.titleFromPrevious = YES;
		_br.isTitled = NO;
		_br.hasHorizontalScroller = YES;
		_br.acceptArrowKeys = YES;
		_br.sendActionOnArrowKeys = YES;
		_br.reuseColumns = YES;
		
		_numberOfVisibleColumns=[coder decodeIntForKey:@"NSNumberOfVisibleColumns"];
		_columnResizing=[coder decodeIntForKey:@"NSColumnResizingType"];
		_minColumnWidth=[coder decodeIntForKey:@"NSMinColumnWidth"];
		_preferedColumnWidth=[coder decodeFloatForKey:@"NSPreferedColumnWidth"];
		_pathSeparator=[[coder decodeObjectForKey:@"NSPathSeparator"] retain];
		_cellPrototype=[[coder decodeObjectForKey:@"NSCellPrototype"] retain];
		if([coder containsValueForKey:@"NSDelegate"])
			[self setDelegate:[coder decodeObjectForKey:@"NSDelegate"]];
		if([coder containsValueForKey:@"NSFirstColumnTitle"])
			[self setTitle:[coder decodeObjectForKey:@"NSFirstColumnTitle"] ofColumn:0];
		// other init
		_matrixClass = [NSMatrix class];
		_scroller = [[NSScroller alloc] initWithFrame:(NSRect){{0,0},{NSWidth(_frame),[NSScroller scrollerWidth]}}];
		[_scroller setTarget:self];
		[_scroller setAction:@selector(scrollViaScroller:)];
		[_scroller setAutoresizingMask:NSViewWidthSizable];
		[self addSubview:_scroller];
		_titles = [NSMutableArray new];
		_columns = [NSMutableArray new];
		_unusedColumns = [NSMutableArray new];
		[self tile];
		[self setMaxVisibleColumns:[coder decodeIntForKey:@"NSMaxNumberOfVisibleColumns"]];  // create columns as needed
		return self;
		}
	return self;
}

@end /* NSBrowser */
