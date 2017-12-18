//
//  BatteryView.m
//  MenuExtras
//
//  Created by H. Nikolaus Schaller on 23.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "BatteryView.h"

#import <CoreDevice/CoreDevice.h>

@implementation BatteryView

- (void) changed:(NSNotification *) n
{
	[self setNeedsDisplay:YES];
}

- (id) initWithFrame:(NSRect) frame
{
	self = [super initWithFrame:frame];
	if (self)
		{
	// Initialization code here.
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changed:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changed:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
		[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
		}
	return self;
}

- (void) drawRect:(NSRect) rect
{
	NSRect body, pin;
	UIDevice *batt=[UIDevice currentDevice];
	UIDeviceBatteryState s=[batt batteryState];
	if([batt batteryState] != UIDeviceBatteryStateUnknown)
		{
		float level=[batt batteryLevel];
/*		if(level < 0.95 && s == UIDeviceBatteryStateCharging)
			[batterypin setHidden:((time(NULL)&1) != 0)];	// make it blink
		else
			[batterypin setHidden:NO];
 */
		}
#if OLD
	if(isOnAC)
		{
			// draw power connector
		}
	if(!isAvailable)
		return;
	NSDivideRect(rect, &body, &pin, 0.9, NSMaxXEdge);
	// we can also use a private NSLevelIndicatorCell to draw...
	NSFrameRect(body);
	pin.origin.y=pin.size.height*0.25;
	pin.size.height*=0.25;
	NSFrameRect(pin);
#endif
}

- (void) setStyle:(int) s; { style=s; }

@end
