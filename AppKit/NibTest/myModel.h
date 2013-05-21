//
//  myModel.h
//  myTest
//
//  Created by Dr. H. Nikolaus Schaller on Mon Jan 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// for Bindings test

@interface myModel : NSObject
{
	double _value;
}

- (double) getValue;
- (void) setValue:(double) val;

@end
