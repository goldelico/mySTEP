//
//  CRTagManager.h
//  CoreRFID
//
//  Created by H. Nikolaus Schaller on 09.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CRTagManagerDelegate;
@class CRTag;

@interface CRTagManager : NSObject
{
	id <CRTagManagerDelegate> delegate;
}

- (id <CRTagManagerDelegate>) delegate;
- (NSArray *) tags;
- (NSString *) readerUID;

- (void) setDelegate:(id <CRTagManagerDelegate>) d;
- (void) startMonitoringTags;
- (void) stopMonitoringTags;

@end
