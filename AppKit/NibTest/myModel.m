//
//  myModel.m
//  myTest
//
//  Created by Dr. H. Nikolaus Schaller on Mon Jan 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "myModel.h"

@implementation myModel

- (double) getValue;
{
	return _value;
}

- (void) setValue:(double) val;
{
	_value=val;
}

@end
