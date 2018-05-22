//
//  XCTest.m
//
//  Created by H. Nikolaus Schaller on 28.07.17.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
//  This is a wrapper around SenTestingKit to provide the newer XCTest API
//

#import <XCTest/XCTest.h>

#ifdef __mySTEP__

void _Cocoa_dummy(void)
{
	[SenTest class];	// reference SenTestingKit so that it is linked against
}

#endif
