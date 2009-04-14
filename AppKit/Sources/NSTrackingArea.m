//
//  NSTrackingArea.m
//  AppKit
//
//  Created by Fabian Spillner on 13.12.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSTrackingArea.h"


@implementation NSTrackingArea

- (NSTrackingArea *) initWithRect:(NSRect) rect 
													options:(NSTrackingAreaOptions) opts 
														owner:(id) obj 
												 userInfo:(NSDictionary *) info; 
{
	if((self=[super init]))
			{
				_rect=rect;
				_options=opts;
				_owner=obj;	// retain??
				_userInfo=[info retain];
			}
	return self;
}

- (void) dealloc
{
	[_userInfo release];
	[super dealloc];
}

- (NSTrackingAreaOptions) options; { return _options; }
- (id) owner; { return _owner; }
- (NSRect) rect; { return _rect; }
- (NSDictionary *) userInfo; { return _userInfo; }

@end
