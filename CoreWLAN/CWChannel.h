//
//  CWChannel.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreWLAN/CoreWLANConstants.h>

@interface CWChannel : NSObject <NSCopying, NSCoding>
{
	CWChannelBand _channelBand;
	NSInteger _channelNumber;
	CWChannelWidth _channelWidth;
}

- (BOOL) isEqualToChannel:(CWChannel *) other;

- (CWChannelBand) channelBand;
- (NSInteger) channelNumber;
- (CWChannelWidth) channelWidth;

@end
