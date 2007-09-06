//
//  NSNib.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSNib
#define _mySTEP_H_NSNib

#import <Foundation/Foundation.h>

extern NSString *NSNibOwner;
extern NSString *NSNibTopLevelObjects;

@interface NSNib : NSObject <NSCoding>
{
	id decoded;	// decoded root object tree
	NSMutableArray *objects;
}

- (id) initWithContentsOfURL:(NSURL *) url;
- (id) initWithNibNamed:(NSString *) name bundle:(NSBundle *) bundle;
- (BOOL) instantiateNibWithExternalNameTable:(NSDictionary *) table;
- (BOOL) instantiateNibWithOwner:(id) owner topLevelObjects:(NSArray **) objects;

@end

#endif /* _mySTEP_H_NSNib */
