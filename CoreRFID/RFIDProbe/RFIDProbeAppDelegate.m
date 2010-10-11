//
//  RFIDProbeAppDelegate.m
//  RFIDProbe
//
//  Created by H. Nikolaus Schaller on 09.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "RFIDProbeAppDelegate.h"

@implementation RFIDProbeAppDelegate

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

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *ident=[aTableColumn identifier];
	if([ident isEqualToString:@"name"])
		return [NSString stringWithFormat:@"%d", rowIndex+1];
	if([ident isEqualToString:@"description"])
		return [[[manager tags] objectAtIndex:rowIndex] description];
	return @"?";
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
