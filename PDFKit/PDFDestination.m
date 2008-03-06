//
//  PDFDestionation.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import "PDFKitPrivate.h"

@implementation PDFDestination

- (id) initWithPage:(PDFPage *) page atPoint:(NSPoint) point;
{
	if((self=[super init]))
		{
		_page=[page retain];
		_location=point;
		}
	return self;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: %@ %@",
		NSStringFromClass([self class]),
		NSStringFromPoint(_location),
		_page];
}

- (void) dealloc;
{
	[_page release];
	[super dealloc];
}

- (PDFPage *) page; { return _page; }
- (NSPoint) point; { return _location; }

@end
