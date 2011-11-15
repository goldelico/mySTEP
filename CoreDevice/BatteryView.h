//
//  BatteryView.h
//  MenuExtras
//
//  Created by H. Nikolaus Schaller on 23.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BatteryView : NSView
{
	int style;	// display style
}

- (void) setStyle:(int) style;

@end
