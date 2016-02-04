/*
 *  LocNode.m
 *  mySTEP
 *
 *  Created by Dr. H. Nikolaus Schaller on 17 Aug 2005.
 *  Copyright (c) 2003 DSITRI. All rights reserved.
 *
 *  licensed under the LGPL
 */

#import "Locnode.h"

@implementation Name

#if 0
struct Namenode *searchByName(struct Namenode *root, char *name, int create)
{ // find name starting at root
	if(!root)
		return NULL;
	if(strncmp(name, root->letters, strlen(root->letters)) != 0)
		return NULL;	// invalid suffix
	if(strlen(name) == strlen(root->letters))
		return root;	// exact match
	return NULL;
}

#endif

- (NSString *) name; { return name; }
- (Location *) location; { return location; }

- (Name *) search:(NSString *) n;
{ // search for exact match
	NSComparisonResult r=[name compare:n];
	switch(r)
		{
		case NSOrderedAscending: return [before search:n];
		case NSOrderedSame: return self;
		case NSOrderedDescending: return [after search:n];
		}
	return nil;
}

- (void) addName:(Name *) node;
{ // add subnode(s) - inserted into either before/after
	if(0 /* before current */)
		{
		if(!before)
			before=node;
		else
			[before addName:node];
		}
	else
		{
		if(!after)
			after=node;
		else
			[after addName:node];
		}
}

- (NSData *) encode:(NSMutableArray *) references;
{ // encode for external file
}

@end

@implementation Location

#if 0
struct Locnode *searchByLocation(struct Locnode *root, double lat, double lon, int create)
{ // find nearest location below root
	if(!root)
		return NULL;
	if(root->subnodes[0])
		{ // tree node
		double bestdist=0.0;
		struct Locnode *bestnode=NULL;
		int i;
		for(i=0; i<4; i++)
			{ // check subquadrants for smallest distance
			  // do sort of A*-pruning!
			struct Locnode *l=searchByLocation(root->subnodes[i], lat, lon, FALSE);
			double dist=fabs(l->lat-lat)+fabs(l->lon-lon);	// manhattan distance
			if(i == 0 || dist < bestdist)
				bestnode=l, bestdist=dist;	// closer point found
			}
		return bestnode;
		}
	return root;	// I am the most closest location
}
#endif

- (double) latitude; { return lat; }
- (double) longitude; { return lon; }
- (NSArray *) names; { return names; }

#define distance(p1lat, p2lat, p1lon, p2lon) (fabs(p1lat-p2lat)+fabs(p1lon-p2lon))
				 
- (Location *) searchLat:(double) la lon:(double) lo;
{ // search for nearest match
	double dist;
	Location *best;
	if(names)
		return self;	// we are a leaf node
	dist=distance(la, lat, lo, lon);	// distance to our own reference point
	best=self;	// best yet
	// use heuristics to determine which of the 4 quadrants to probe in which order
	// if better distance, replace best
	return best;
}

- (NSData *) encode:(NSMutableArray *) references;
{ // encode for external file
}

@end
