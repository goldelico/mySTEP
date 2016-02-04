/*
 *  LocNode.h
 *  mySTEP
 *
 *  Created by Dr. H. Nikolaus Schaller on 17 Aug 2005.
 *  Copyright (c) 2003 DSITRI. All rights reserved.
 *
 *  licensed under the LGPL
 */

#import <Foundation/Foundation.h>

@class Name, Location;

// this is a binary search tree for names - behaves as an index into the location nodes

@interface Name : NSObject
{
	Name *parent;			// for reverse traversal
	NSString *name;			// node's name
	Location *location;		// if we are a leaf
	Name *before;			// entries coming before
	Name *after;			// entries coming after
};

- (NSString *) name;
- (Location *) location;
- (Name *) search:(NSString *) name;	// search for exact match
- (void) addName:(Name *) node;			// add subnode(s) - inserted into either before/after
- (NSData *) encode:(NSMutableArray *) references;	// encode for external file

@end

// this is a quaternary search tree

@interface Location : NSObject
{
	double lon;
	double lat;
	NSArray *names;					// used if we are a leaf node
	Location *l1, *l2, *l3, *l4;	// used if we are a tree node
};

- (double) latitude;
- (double) longitude;
- (NSArray *) names;
- (Location *) searchLat:(double) lat lon:(double) lon;	// search for nearest match
- (NSData *) encode:(NSMutableArray *) references;	// encode for external file

@end
