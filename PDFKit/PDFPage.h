//
//  PDFPage.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
	kPDFDisplayBoxMediaBox,
	kPDFDisplayBoxCropBox,
	kPDFDisplayBoxBleedBox,
	kPDFDisplayBoxTrimBox,
	kPDFDisplayBoxArtBox
} PDFDisplayBox;

@class PDFAnnotation;
@class PDFDocument;
@class PDFSelection;

@interface PDFPage : NSObject
{
	NSMutableArray *_annotations;
	NSMutableDictionary *_page;		// reference to /Page dictionary
	PDFDocument *_document;			// document to read indirect objects/streams from
	BOOL _displaysAnnotations;
}

- (void) addAnnotation:(PDFAnnotation *) annotation;
- (PDFAnnotation *) annotationAtPoint:(NSPoint) point;
- (NSArray *) annotations;
- (NSAttributedString *) attributedString;
- (NSRect) boundsForBox:(PDFDisplayBox) box;
- (NSRect) characterBoundsAtIndex:(int) index;
- (int) characterIndexAtPoint:(NSPoint) point;
- (NSData *) dataRepresentation;
- (BOOL) displaysAnnotations;
- (PDFDocument *) document;
- (void) drawWithBox:(PDFDisplayBox) box;
- (id) initWithDocument:(PDFDocument *) document;
- (NSString *) label;
- (unsigned) numberOfCharacters;
- (void) removeAnnotation:(PDFAnnotation *) annotation;
- (int) rotation;
- (PDFSelection *) selectionForLineAtPoint:(NSPoint) point;
- (PDFSelection *) selectionForRange:(NSRange) range;
- (PDFSelection *) selectionForRect:(NSRect) rect;
- (PDFSelection *) selectionForWordAtPoint:(NSPoint) point;
- (PDFSelection *) selectionFromPoint:(NSPoint) start toPoint:(NSPoint) end;
- (void) setBounds:(NSRect) bounds forBox:(PDFDisplayBox) box;
- (void) setDisplaysAnnotations:(BOOL) flag;
- (void) setRotation:(int) angle;
- (NSString *) string;

@end

@interface PDFMutablePage : PDFPage
@end
