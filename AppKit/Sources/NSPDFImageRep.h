/*
	NSPDFImageRep.h
	mySTEP
 
	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.

	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	29. November 2007 - aligned with 10.5  
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSPDFImageRep
#define _mySTEP_H_NSPDFImageRep

#import "AppKit/NSImageRep.h"

@interface NSPDFImageRep : NSImageRep
{
}

+ (id)imageRepWithData:(NSData *)pdfData; 

- (NSRect) bounds; 
- (NSInteger) currentPage; 
- (id) initWithData:(NSData *) data; 
- (NSInteger) pageCount; 
- (NSData *) PDFRepresentation; 
- (void) setCurrentPage:(NSInteger) index; 

@end

#endif /* _mySTEP_H_NSObjectController */
