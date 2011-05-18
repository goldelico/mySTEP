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
	if(tableView == tagTable)
		return [[manager tags] count];
	if(tableView == devicesTable)
		{
		if(!devices)
			{
			devices=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev" error:NULL];
			devices=[devices filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH 'cu.'"]];
			devices=[devices sortedArrayUsingSelector:@selector(compare:)];
			[devices retain];
			}
		return [devices count];
		}
	return 1;
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *ident=[aTableColumn identifier];
	if(aTableView == tagTable)
		{
		if([ident isEqualToString:@"name"])
			return [NSString stringWithFormat:@"%d", rowIndex+1];
		if([ident isEqualToString:@"description"])
			return [(CRTag *) [[manager tags] objectAtIndex:rowIndex] description];		
		}
	if(aTableView == devicesTable)
		return [devices objectAtIndex:rowIndex];
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

- (void) refresh
{
	[devices release];
	devices=nil;
	[devicesTable reloadData];
	if([[devicesTable window] isVisible])
		[self performSelector:_cmd withObject:nil afterDelay:1.0];	// auto-refresh while visible
}

- (IBAction) openPreferencesPanel:(id) Sender;
{
	int r, cnt;
	NSString *current=[[NSUserDefaults standardUserDefaults] stringForKey:@"RFIDReaderSerialDevice"];	// get current device selection
	[devicesTable setDoubleAction:@selector(chooseDevice:)];
	[[devicesTable window] makeKeyAndOrderFront:nil];
	[self refresh];
	cnt=[devicesTable numberOfRows];
	for(r=0; r<cnt; r++)
		{
		if([[@"/dev" stringByAppendingPathComponent:[devices objectAtIndex:r]] isEqualToString:current])
			[devicesTable selectRow:r byExtendingSelection:NO];	// select last choosen entry (if it still exists)		
		}
}

- (IBAction) chooseDevice:(id) Sender;
{
	int row=[devicesTable selectedRow];
	if(row >= 0)
		{
		NSString *fullname=[@"/dev" stringByAppendingPathComponent:[devices objectAtIndex:row]];
		[manager stopMonitoringTags];
		[[devicesTable window] close];
		[[NSUserDefaults standardUserDefaults] setObject:fullname forKey:@"RFIDReaderSerialDevice"];
		[[NSUserDefaults standardUserDefaults] synchronize];	// publish to other apps
		[manager startMonitoringTags];	// open new device
		}
}

@end
