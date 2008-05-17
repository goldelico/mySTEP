//
//  NSSortDescriptor.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Oct 05 2004.
//  Copyright (c) 2004 DSITRI.
//
//  H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//


#ifndef _mySTEP_H_NSSortDescriptor
#define _mySTEP_H_NSSortDescriptor

#import "Foundation/NSObject.h"
#import "Foundation/NSArray.h"

@class NSString;
@class NSCoder;

@interface NSSortDescriptor : NSObject <NSCopying, NSCoding>
{
	SEL selector;
	NSString *key;
	BOOL ascending;
}

- (BOOL) ascending;
- (NSComparisonResult) compareObject:(id) a toObject:(id) b;
- (id) initWithKey:(NSString *) key ascending:(BOOL) ascending;
- (id) initWithKey:(NSString *) key ascending:(BOOL) ascending selector:(SEL) selector;
- (NSString *) key;
- (id) reversedSortDescriptor;
- (SEL) selector;

@end

@interface NSArray (NSSortDecriptor)

- (NSArray *) sortedArrayUsingDescriptors:(NSArray *) sortDescriptors;

@end

@interface NSMutableArray (NSSortDescriptor)

- (void) sortUsingDescriptors:(NSArray *) sortDescriptors;

@end

#endif /* _mySTEP_H_NSSortDescriptor */
