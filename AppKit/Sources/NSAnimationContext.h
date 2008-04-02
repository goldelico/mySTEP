//
//  NSAnimationContext.h
//  AppKit
//
//  Created by Fabian Spillner on 05.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAnimationContext : NSObject
{
}

+ (void) beginGrouping;
+ (NSAnimationContext *) currentContext;
+ (void) endGrouping;

- (NSTimeInterval) duration;
- (void) setDuration:(NSTimeInterval) dur;

@end
