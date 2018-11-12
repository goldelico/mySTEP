//
//  Inspector.m
//  ObjCKit
//
//  Created by H. Nikolaus Schaller on 20.06.14.
//  Copyright 2014 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <ObjCKit/Inspector.h>

@implementation Inspector

- (id) outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if(!item) item=root;
	return [(Node *) item childAtIndex:index];
}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if(!item) item=root;
	return [(Node *) item childrenCount] > 0;
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if(!item) item=root;
	return [(Node *) item childrenCount];
}

- (id) outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return [(Node *) item type];
}

- (void) outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger row=[outlineView selectedRow];
	if(row < 0)
		return;
	[selectedNode autorelease];
	selectedNode=[[outlineView itemAtRow:row] retain];
	[attributesView reloadData];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[selectedNode attributes] count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *column=[aTableColumn identifier];
	if([column isEqualToString:@"attribute"])
		{
		return [[[selectedNode attributes] allKeys] objectAtIndex:rowIndex];
		}
	if([column isEqualToString:@"value"])
		{
		return [[[[selectedNode attributes] allValues] objectAtIndex:rowIndex] description];
		}
	return @"?";
}

- (void) openInspector:(Node *) node;	// open in a window (needs a NSRunLoop)
{ // open in a window (needs a NSRunLoop)
	if (!inspector)
		{
		[NSBundle loadNibNamed:@"Inspector" owner:self];
		}
	if(node)
		{
		[root autorelease];
		root=[node retain];
		}
	[outlineView reloadData];
	[inspector makeKeyAndOrderFront:nil];
}

@end
