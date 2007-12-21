//
//  NSTreeNode.h
//  AppKit
//
//  Created by Fabian Spillner on 14.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSObject.h>

@class NSArray, NSIndexPath, NSMutableArray;

@interface NSTreeNode : NSObject
{
	id _representedObject;
	NSMutableArray *_childNodes;
	NSTreeNode *_parentNote;
}

+ (id) treeNodeWithRepresentedObject:(id)modelObject; 

- (NSArray *) childNodes; 
- (NSTreeNode *) descendantNodeAtIndexPath:(NSIndexPath *) path; 
- (NSIndexPath *) indexPath; 
- (id) initWithRepresentedObject:(id) repObj; 
- (BOOL) isLeaf; 
- (NSMutableArray *) mutableChildNodes; 
- (NSTreeNode *) parentNode; 
- (id) representedObject; 
- (void) sortWithSortDescriptors:(NSArray *) sortDescs recursively:(BOOL) flag; 

@end
