//
//  objc10.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "objc10.h"


@implementation Node (Objc10)

- (void) objc10;	// translate objc 2.0 idioms to objc 1.0
{
	[self performSelectorForAllChildren:_cmd];
}

- (void) objc10something;
{
	[self performSelectorForAllChildren:@selector(objc10)];
	// check for idioms
	// . notation for KVC
	// @try, @catch
	// @synchronized
	// @synthesize
	// @autorelease
	// ARC
}

@end
