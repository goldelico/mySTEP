//
//  PDFDestionation.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDFPage;

@interface PDFDestination: NSObject
{
	PDFPage *_page;
	NSPoint _location;
}

- (id) initWithPage:(PDFPage *) page atPoint:(NSPoint) point;
- (PDFPage *) page;
- (NSPoint) point;

@end
