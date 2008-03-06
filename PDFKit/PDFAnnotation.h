//
//  PDFAnnotation.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PDFKit/PDFPage.h>

@class PDFBorder;

@interface PDFAnnotation : NSObject
{
	PDFBorder	*_border;
	NSRect		_bounds;
	NSColor		*_color;
	NSString	*_contents;
	PDFPage		*_page;
	NSString	*_toolTip;
	BOOL		_shouldDisplay;
	BOOL		_shouldPrint;
	BOOL		_hasAppearanceStream;	// ????
}

- (PDFBorder *) border;
- (NSRect) bounds;
- (NSColor *) color;
- (NSString *) contents;
- (void) drawWithBox:(PDFDisplayBox) box;
- (BOOL) hasAppearanceStream;	// individually by each subclass
- (id) initWithBounds:(NSRect) bounds;
- (PDFPage *) page;
- (void) setBorder:(PDFBorder *) border;
- (void) setBounds:(NSRect) bounds;
- (void) setColor:(NSColor *) color;
- (void) setContents:(NSString *) contents;
- (void) _setPage:(PDFPage *) page;
- (void) setShouldDisplay:(BOOL) flag;
- (void) setShouldPrint:(BOOL) flag;
- (BOOL) shouldDisplay;
- (BOOL) shouldPrint;
- (NSString *) toolTip;
- (NSString *) type;	// individually by each subclass

@end