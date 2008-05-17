/*
    NSGarbageCollector.h
    Foundation

    Created by H. Nikolaus Schaller on 05.11.07.
    Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	9. May 2008 - aligned with 10.5
*/

#import <Foundation/NSObject.h>

@interface NSGarbageCollector : NSObject
{

}

+ (id) defaultCollector; 

- (void) collectExhaustively;
- (void) collectIfNeeded;
- (void) disable;
- (void) disableCollectorForPointer:(void *) pointer;
- (void) enable;
- (void) enableCollectorForPointer:(void *) pointer;
- (BOOL) isCollecting;
- (BOOL) isEnabled;
- (NSZone *) zone;

@end
