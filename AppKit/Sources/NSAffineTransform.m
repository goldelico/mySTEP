//
//  NSAffineTransform.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import <Foundation/NSString.h>

#import <AppKit/NSGraphics.h>
#import <AppKit/NSAffineTransform.h>
#import <AppKit/NSBezierPath.h>

#import "NSBackendPrivate.h"

@implementation NSAffineTransform (AppKit)

- (void) concat	
{
	[[NSGraphicsContext currentContext] _concatCTM:self];
}

- (void) set
{
	[[NSGraphicsContext currentContext] _setCTM:self];
}

- (NSBezierPath *) transformBezierPath:(NSBezierPath *) aPath;
{
	NSBezierPath *p=[aPath copy];
	[p transformUsingAffineTransform:self];
	return [p autorelease];
}

@end /* NSAffineTransform */

@interface NSPSMatrix : NSObject
@end

@implementation NSPSMatrix	/* private class used by Cocoa drawing system and sometimes archived (e.g. NSProgressIndicator) */

- (void) encodeWithCoder:(NSCoder *) coder
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder
{
	return self;
}

@end

