//
//  PDFView.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import "PDFKitPrivate.h"

@interface _PDFPagesView : NSView
{ // this becomes the content view of the NSScrollView
	PDFView *_pdfView;
	NSColor *_backgroundColor;
	PDFDocument *_document;
	id _delegate;
	float _scaleFactor;
	float _greekingThreshold;
	PDFDisplayBox _displayBox;
	PDFDisplayMode _displayMode;
	unsigned _currentPage;
	BOOL _allowsDragging;
	BOOL _autoScales;
	BOOL _displaysAsBook;
	BOOL _displaysPageBreaks;
	BOOL _shouldAntiAlias;
}

- (void) layoutDocumentView;	// change our bounds so that all pages fit

@end

@implementation _PDFPagesView

- (void) layoutDocumentView;
{
	NSRect rect=NSZeroRect;
	// if single column
	rect.size.width=100.0;		// page width
	rect.size.height=[_document pageCount]*(200.0 + 20.0) - 20.0;
	// else
	rect.size.width=200.0;		// page width
	rect.size.height=(([_document pageCount]+1)/2)*(200.0 + 20.0) - 20.0;
	// notify superview that we have changed our bounds
	[self setBounds:rect];
	[self setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect) rect;
{
#if 1
	NSLog(@"PDFView drawRect: %@", NSStringFromRect(rect));
#endif
	if(_backgroundColor)
		{ // draw background
#if 1
		NSLog(@"PDFView _backgroundColor: %@", _backgroundColor);
#endif
		[_backgroundColor set];
		NSRectFill(rect);
		}
	[NSBezierPath clipRect:rect];	// clip to expected rect
	// find all pages that fall into the drawing area
	[_pdfView drawPage:[_document pageAtIndex:0]];
}

@end

@implementation PDFView

// view management and drawing

- (id) initWithFrame:(NSRect) rect;
{
	if((self=[super initWithFrame:rect]))
		{
		_scaleFactor=1.0;
		_displayBox=kPDFDisplayBoxCropBox;
		_displayMode=kPDFDisplaySinglePage;
		_allowsDragging=YES;
		_autoScales=YES;
		_displaysAsBook=NO;
		_displaysPageBreaks=YES;
		_greekingThreshold=3.0;
		_shouldAntiAlias=YES;
		[self layoutDocumentView];
		}
	return self;
}

- (void) dealloc;
{
	[super dealloc];
}

- (void) clearSelection;
{
	[self setCurrentSelection:nil];
}

- (PDFSelection *) currentSelection; { NIMP; return nil; }

// basic methods (getters&setters)

- (BOOL) allowsDragging; { return _allowsDragging; }
- (void) setAllowsDragging:(BOOL) flag; { _allowsDragging=flag; }
- (BOOL) autoScales; { return _autoScales; }
- (void) setAutoScales:(BOOL) flag; { _autoScales=flag; [self layoutDocumentView]; }
- (NSColor *) backgroundColor; { return _backgroundColor; }
- (void) setBackgroundColor:(NSColor *) color; { [_backgroundColor autorelease]; _backgroundColor=[color retain]; }
- (id) delegate; { return _delegate; }
- (PDFDisplayBox) displayBox; { return _displayBox; }
- (void) setDisplayBox:(PDFDisplayBox) box; { _displayBox=box; }
- (void) setDelegate:(id) delegate; { [_delegate autorelease]; _delegate=[delegate retain]; }
- (PDFDisplayMode) displayMode; { return _displayMode; }
- (void) setDisplayMode:(PDFDisplayMode) mode; { _displayMode=mode; [self setNeedsDisplay:YES]; }
- (BOOL) displaysAsBook; { return _displaysAsBook; }
- (void) setDisplaysAsBook:(BOOL) flag; { _displaysAsBook=flag; [self layoutDocumentView]; }
- (BOOL) displaysPageBreaks; { return _displaysPageBreaks; }
- (void) setDisplaysPageBreaks:(BOOL) flag; { _displaysPageBreaks=flag; [self layoutDocumentView]; }

- (PDFDocument *) document; { return _document; }
- (id) documentView; { return self; }

- (void) drawPage:(PDFPage *) page;
{
	// fill background?
	[page drawWithBox:[self displayBox]];
}

- (float) greekingThreshold; { return _greekingThreshold; }

- (void) layoutDocumentView;
{
	// create a scroll view
	// add a document view that does the layout of all pages taking spaces into account
	[self setNeedsDisplay:YES];
}

- (float) scaleFactor; { return _scaleFactor; }

- (void) setCurrentSelection:(PDFSelection *) sel; { NIMP; return; }

- (void) setDocument:(PDFDocument *) document;
{
	if(document == _document)
		return;
	[_document autorelease];
	_document=[document retain];
	[self layoutDocumentView];
}

- (void) setGreekingThreshold:(float) val; { _greekingThreshold=val; [self setNeedsDisplay:YES]; }

- (void) setScaleFactor:(float) factor;
{
#if 1
	NSLog(@"setScaleFactor:%f", factor);
#endif
	factor=[_delegate PDFViewWillChangeScaleFactor:self toScale:factor];	// allow for limitation
	if(factor == _scaleFactor)
		return;
	_scaleFactor=factor;
	[self layoutDocumentView];
}

- (void) setShouldAntiAlias:(BOOL) flag; { _shouldAntiAlias=flag; [self setNeedsDisplay:YES]; }
- (BOOL) shouldAntiAlias; { return _shouldAntiAlias; }

- (IBAction) takeBackgroundColorFrom:(id) Sender; { [self setBackgroundColor:[Sender backgroundColor]]; }
- (IBAction) takePasswordFrom:(id) Sender; { [[self document] setPassword:[Sender stringValue]]; }

- (IBAction) zoomIn:(id) Sender; { [self setScaleFactor:sqrt(2.0)*[self scaleFactor]]; }
- (IBAction) zoomOut:(id) Sender; { [self setScaleFactor:sqrt(0.5)*[self scaleFactor]]; }

// ??? does this be called here

- (BOOL) canZoomIn; { return [_delegate PDFViewWillChangeScaleFactor:self toScale:sqrt(2.0)*[self scaleFactor]] != [self scaleFactor]; }
- (BOOL) canZoomOut; { return [_delegate PDFViewWillChangeScaleFactor:self toScale:sqrt(0.5)*[self scaleFactor]] != [self scaleFactor]; }

- (BOOL) canGoToPreviousPage; { return _currentPage > 0; }
- (BOOL) canGoToNextPage; { return _currentPage < [_document pageCount]; }
- (BOOL) canGoToLastPage; { return _currentPage < [_document pageCount]; }
- (BOOL) canGoToFirstPage; { return _currentPage > 0 && [_document pageCount] > 0; }

- (BOOL) canGoForward; { return NO; }
- (BOOL) canGoBack; { return NO; }

- (PDFPage *) currentPage;
{
	// NO! calculate from scroller position(s) depending on layout

	if([_document pageCount] == 0)
		return nil;	// has no current page!
	return [_document pageAtIndex:_currentPage];
}

/* 
					PDFView.m:128: warning: incomplete implementation of class `PDFView'
 PDFView.m:128: warning: method definition for `-setCursorForAreaOfInterest:' not found
 PDFView.m:128: warning: method definition for `-selectAll:' not found
 PDFView.m:128: warning: method definition for `-scrollSelectionToVisible:' not found
 PDFView.m:128: warning: method definition for `-rowSizeForPage:' not found
 PDFView.m:128: warning: method definition for `-printWithInfo:autoRotate:' not found
 PDFView.m:128: warning: method definition for `-pageForPoint:nearest:' not found
 PDFView.m:128: warning: method definition for `-goToSelection:' not found
 PDFView.m:128: warning: method definition for `-goToPrevioustPage:' not found
 PDFView.m:128: warning: method definition for `-goToPage:' not found
 PDFView.m:128: warning: method definition for `-goToNextPage:' not found
 PDFView.m:128: warning: method definition for `-goToLastPage:' not found
 PDFView.m:128: warning: method definition for `-goToFirstPage:' not found
 PDFView.m:128: warning: method definition for `-goToDestination:' not found
 PDFView.m:128: warning: method definition for `-goForward:' not found
 PDFView.m:128: warning: method definition for `-goBack:' not found
 PDFView.m:128: warning: method definition for `-currentPage' not found
 PDFView.m:128: warning: method definition for `-currentDestination' not found
 PDFView.m:128: warning: method definition for `-copy:' not found
 PDFView.m:128: warning: method definition for `-convertRect:toPage:' not found
 PDFView.m:128: warning: method definition for `-convertRect:fromPage:' not found
 PDFView.m:128: warning: method definition for `-convertPoint:toPage:' not found
 PDFView.m:128: warning: method definition for `-convertPoint:fromPage:' not found
 PDFView.m:128: warning: method definition for `-areaOfInterestForMouse:' not found

 */
@end

@implementation NSObject (PDFViewDelegate)

- (float) PDFViewWillChangeScaleFactor:(PDFView *) sender toScale:(float) scale;
{
	if(scale < 0.1)
		return 0.1;
	if(scale > 20.0)
		return 20.0;
	return scale;
}

@end
