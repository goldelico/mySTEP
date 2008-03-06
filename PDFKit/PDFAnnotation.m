//
//  PDFAnnotation.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import "PDFKitPrivate.h"

@implementation PDFAnnotation

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@:",
		NSStringFromClass([self class])
		];
}

- (void) dealloc;
{
	[super dealloc];
}

@end
