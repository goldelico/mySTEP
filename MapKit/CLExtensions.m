//
//  CLExtensions.m
//  myNavigator extensions to MacOS X 10.6
//
//  Created by H. Nikolaus Schaller on 08.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#ifndef __mySTEP__

@interface CLLocationManager : NSObject
@end

#import "CLExtensions.h"

@implementation NSBlockHandler

- (id) initWithDelegate:(id) d action:(SEL) a
{
	if((self=[self init]))
		{
		delegate=d;
		action=a;
		}
	return self;
}

+ (NSBlockHandler *) handlerWithDelegate:(id) d action:(SEL) a;
{
	return [[[self alloc] initWithDelegate:d action:a] autorelease];
}

- (id) perform;
{
	return [delegate performSelector:action];
}

- (id) performWithObject:(id) obj;
{
	return [delegate performSelector:action withObject:obj];
}

- (id) performWithObject:(id) obj1 withObject:(id) obj2;
{
	return [delegate performSelector:action withObject:obj1 withObject:obj2];
}

@end

#endif

// EOF
