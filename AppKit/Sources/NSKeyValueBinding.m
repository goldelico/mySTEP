//
//  NSKeyValueBinding.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed May 03 2006.
//  Copyright (c) 2006 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import <AppKit/NSKeyValueBinding.h>
#import "NSAppKitPrivate.h"

@implementation NSObject (NSPlaceholder)

+ (id) defaultPlaceholderForMarker:(id) marker withBinding:(NSString *) binding;
{
	return NIMP;
}

+ (void) setDefaultPlaceholder:(id) placeholder forMarker:(id) marker withBinding:(NSString *) binding;
{
	NIMP;
}

@end

@implementation NSObject (NSKeyValueBindingCreation)

+ (void) exposeBinding:(NSString *) key;
{
	NIMP;
}

- (NSArray *) exposedBindings;
{
	return NIMP;
}

- (Class) valueClassForBinding:(NSString *) binding;
{
	NIMP;
	return Nil;
}

- (void) bind:(NSString *) binding toObject:(id) controller withKeyPath:(NSString *) keyPath options:(NSDictionary *) options;
{
#if 1
	NSLog(@"bind %@ %@", binding, keyPath);
#endif
}

- (void) unbind:(NSString *) binding;
{
	NIMP;
}

@end
