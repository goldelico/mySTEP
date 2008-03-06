//
//  PDFOutline.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import "PDFKitPrivate.h"

@implementation PDFOutline

- (PDFOutline *) childAtIndex:(int) index; { return [_children objectAtIndex:index]; }
- (PDFDestination *) destination; { return _destination; }
- (PDFDocument *) document; { return _document; }

- (id) initWithDocument:(PDFDocument *) document
{
	return [document outlineRoot];
}

- (id) _initWithDocument:(PDFDocument *) document
			 destination:(PDFDestination *) dest 
				children:(NSArray *) children
				   label:(NSString *) label;
{
	if((self=[super init]))
		{
		_document=document;	// retain??
		_destination=[dest retain];
		_children=[children retain];
		_label=[label retain];
		}
	return self;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: ", NSStringFromClass([self class])];
}

- (void) dealloc;
{
	[_destination release];
	[_children release];
	[_label release];
	[super dealloc];
}

- (NSString *) label; { return _label; }
- (int) numberOfChildren; { return [_children count]; }

@end
