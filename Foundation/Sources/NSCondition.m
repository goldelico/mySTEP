//
//  NSCondition.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 05.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSCondition.h"
#import <Foundation/NSString.h>

@implementation NSCondition

- (void) broadcast;
{
	NIMP;
}

- (NSString *) name; { return _name; }
- (void) setName:(NSString *) newName; { ASSIGN(_name, newName); }

- (void) signal;
{
	NIMP;
}

- (void) wait;
{
	NIMP;
}

- (BOOL) waitUntilDate:(NSDate *) limit;
{
	NIMP;
	return NO;
}

@end
