//
//  PDFOutline.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDFDestination;
@class PDFDocument;

@interface PDFOutline : NSObject
{
	NSArray *_children;
	PDFDestination *_destination;
	PDFDocument *_document;
	NSString *_label;
}

- (PDFOutline *) childAtIndex:(int) index;
- (PDFDestination *) destination;
- (PDFDocument *) document;
- (id) initWithDocument:(PDFDocument *) document;
- (id) _initWithDocument:(PDFDocument *) document
			 destination:(PDFDestination *) dest 
				children:(NSArray *) children
				   label:(NSString *) label;
- (NSString *) label;
- (int) numberOfChildren;

@end
