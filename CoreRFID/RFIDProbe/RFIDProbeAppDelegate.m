//
//  RFIDProbeAppDelegate.m
//  RFIDProbe
//
//  Created by H. Nikolaus Schaller on 09.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "RFIDProbeAppDelegate.h"

@implementation RFIDProbeAppDelegate

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	manager=[CRTagManager new];
	[manager setDelegate:self];
	[manager startMonitoringTags];
	[tagTable reloadData];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[manager tags] count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *ident=[aTableColumn identifier];
	if([ident isEqualToString:@"name"])
		return [NSString stringWithFormat:@"%d", rowIndex+1];
	if([ident isEqualToString:@"description"])
		return [(CRTag *) [[manager tags] objectAtIndex:rowIndex] description];
	return @"?";
}

- (void) tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *ident=[aTableColumn identifier];
	if([ident isEqualToString:@"name"])
		{		
			int hash=[[(CRTag *) [[manager tags] objectAtIndex:rowIndex] tagUID] hash];
			[aCell setBackgroundColor:[NSColor colorWithCalibratedRed:((hash >> 16)%255)/255.0
																green:((hash >> 8)%255)/255.0
																 blue:((hash >> 0)%255)/255.0
																alpha:1.0]];
		}
}

- (void) tagManager:(CRTagManager *) mngr didFailWithError:(NSError *) err;
{
	// e.g. we have no RFID device
	// show alert and exit application or try-again mode
}

- (void) tagManager:(CRTagManager *) mngr didFindTag:(CRTag *) err;
{
	[tagTable reloadData];
}

- (void) tagManager:(CRTagManager *) mngr didLooseTag:(CRTag *) err;
{
	[tagTable reloadData];
}

@end
