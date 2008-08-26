//
//  NSGarbageCollector.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 05.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSGarbageCollector.h"


@implementation NSGarbageCollector

+ (id) defaultCollector;
{
	static NSGarbageCollector *gc;
	if(!gc) gc=[[self alloc] init];
	return gc;
}

- (void) collectExhaustively; { NIMP; }
- (void) collectIfNeeded; { NIMP; }
- (void) disable; { NIMP; }
- (void) disableCollectorForPointer:(void *) pointer; { NIMP; }
- (void) enable; { NIMP; }
- (void) enableCollectorForPointer:(void *) pointer; { NIMP; }
- (BOOL) isCollecting; { return NO; }
- (BOOL) isEnabled; { return NO; }
- (NSZone *) zone; { return NSDefaultMallocZone(); }

@end
