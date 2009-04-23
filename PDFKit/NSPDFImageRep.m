//
//  NSPDFImageRep.m
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <PDFKit/PDFKit.h>

#ifndef __mySTEP__
#import <AppKit/NSPDFImageRep.h>
#define NSPDFImageRep mySTEP_NSPDFImageRep
#endif

@class PDFDocument;

@interface NewNSPDFImageRep : NSImageRep
{
	PDFDocument *doc;
	unsigned currentPage;
}

+ (id) imageRepWithData:(NSData *) data;
- (id) initWithData:(NSData *) data;
- (NSRect) bounds;
- (int) currentPage;
- (int) pageCount;
- (NSData *) PDFRepresentation;
- (void) setPage:(int) index;

@end

@implementation NewNSPDFImageRep

// make us poseAsClass NSPDFImageRep?

+ (id) imageRepWithData:(NSData *) data;
{
	return [[[self alloc] initWithData:data] autorelease];
}

- (id) initWithData:(NSData *) data;
{
	if((self=[super init]))
		{
		doc=[[PDFDocument alloc] initWithData:data];	// try
		if(!doc)
			{
			[self release];
			return nil;
			}
		}
	return self;
}

- (void) dealloc;
{
	[doc release];
	[super dealloc];
}

- (BOOL) draw;
{
	if(currentPage < 0 || currentPage >= [doc pageCount])
		return NO;
	// could check other parameters
	[[doc pageAtIndex:currentPage] drawWithBox:kPDFDisplayBoxMediaBox];
	return YES;
}

- (NSRect) bounds; { return [[doc pageAtIndex:currentPage] boundsForBox:kPDFDisplayBoxMediaBox]; }
- (int) currentPage; { return currentPage; }
- (int) pageCount; { return [doc pageCount]; }
- (NSData *) PDFRepresentation; { return [doc dataRepresentation]; }
- (void) setPage:(int) index; {	currentPage=index; }

@end
