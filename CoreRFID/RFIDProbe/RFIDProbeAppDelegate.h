//
//  RFIDProbeAppDelegate.h
//  RFIDProbe
//
//  Created by H. Nikolaus Schaller on 09.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreRFID/CoreRFID.h>

@interface RFIDProbeAppDelegate : NSObject <CRTagManagerDelegate>
{
	IBOutlet NSWindow *window;
	IBOutlet NSTableView *tagTable;
	CRTagManager *manager;
}


@end
