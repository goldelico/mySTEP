//
//  PDFView.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PDFKit/PDFPage.h>

@class PDFDocument;

typedef enum
{
	kPDFDisplaySinglePage,
	kPDFDisplaySinglePageContinuous,
	kPDFDisplayTwoUp,
	kPDFDisplayTwoUpContinuous
} PDFDisplayMode;

typedef enum
{
	kPDFNoArea=1<<0,
	kPDFPageArea=1<<1,
	kPDFTextArea=1<<2,
	kPDFAnnotationArea=1<<3,
	kPDFLinkArea=1<<4,
	kPDFControlArea=1<<5,
	kPDFTextFieldArea=1<<6,
	kPDFPopupArea=1<<7
} PDFAreaOfInterest;

@interface PDFView : NSView
{
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

// basic methods

- (BOOL) allowsDragging;
- (PDFAreaOfInterest) areaOfInterestForMouse:(NSEvent *) event;
- (BOOL) autoScales;
- (NSColor *) backgroundColor;
- (BOOL) canGoBack;
- (BOOL) canGoForward;
- (BOOL) canGoToFirstPage;
- (BOOL) canGoToLastPage;
- (BOOL) canGoToNextPage;
- (BOOL) canGoToPreviousPage;
- (BOOL) canZoomIn;
- (BOOL) canZoomOut;
- (void) clearSelection;
- (NSPoint) convertPoint:(NSPoint) point fromPage:(PDFPage *) page;
- (NSPoint) convertPoint:(NSPoint) point toPage:(PDFPage *) page;
- (NSRect) convertRect:(NSRect) rect fromPage:(PDFPage *) page;
- (NSRect) convertRect:(NSRect) rect toPage:(PDFPage *) page;
- (void) copy:(id) sender;
- (PDFDestination *) currentDestination;
- (PDFPage *) currentPage;
- (PDFSelection *) currentSelection;
- (id) delegate;
- (PDFDisplayBox) displayBox;
- (PDFDisplayMode) displayMode;
- (BOOL) displaysAsBook;
- (BOOL) displaysPageBreaks;
- (PDFDocument *) document;
- (id) documentView;
- (void) drawPage:(PDFPage *) page;
- (IBAction) goBack:(id) sender;
- (IBAction) goForward:(id) sender;
- (void) goToDestination:(PDFDestination *) dest;
- (IBAction) goToFirstPage:(id) sender;
- (IBAction) goToLastPage:(id) sender;
- (IBAction) goToNextPage:(id) sender;
- (void) goToPage:(PDFPage *) page;
- (IBAction) goToPrevioustPage:(id) sender;
- (void) goToSelection:(PDFSelection *) sel;
- (float) greekingThreshold;
- (void) layoutDocumentView;
- (PDFPage *) pageForPoint:(NSPoint) pnt nearest:(BOOL) flag;
- (void) printWithInfo:(NSPrintInfo *) info autoRotate:(BOOL) flag;
- (NSSize) rowSizeForPage:(PDFPage *) page;
- (float) scaleFactor;
- (void) scrollSelectionToVisible:(id) sender;
- (IBAction) selectAll:(id) sender;
- (void) setAllowsDragging:(BOOL) flag;
- (void) setAutoScales:(BOOL) flag;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setCurrentSelection:(PDFSelection *) sel;
- (void) setCursorForAreaOfInterest:(PDFAreaOfInterest) area;
- (void) setDelegate:(id) delegate;
- (void) setDisplayBox:(PDFDisplayBox) box;
- (void) setDisplayMode:(PDFDisplayMode) mode;
- (void) setDisplaysAsBook:(BOOL) flag;
- (void) setDisplaysPageBreaks:(BOOL) flag;
- (void) setDocument:(PDFDocument *) document;
- (void) setGreekingThreshold:(float) val;
- (void) setScaleFactor:(float) factor;
- (void) setShouldAntiAlias:(BOOL) flag;
- (BOOL) shouldAntiAlias;
- (IBAction) takeBackgroundColorFrom:(id) Sender;
- (IBAction) takePasswordFrom:(id) Sender;
- (IBAction) zoomIn:(id) Sender;
- (IBAction) zoomOut:(id) Sender;

@end

@interface NSObject (PDFViewDelegate)

- (float) PDFViewWillChangeScaleFactor:(PDFView *) sender toScale:(float) scale;

@end
