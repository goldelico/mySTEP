//
//  CTCallCenter.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 04.07.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CTCall;

// extension

@protocol CTCallCenterDelegate
- (BOOL) handleCallEvent:(CTCall *) call;	// should ring and -accept/-discard etc. depending on -callState
@end

@interface CTCallCenter : NSObject
{
	NSMutableSet *currentCalls;
	id <CTCallCenterDelegate> delegate;
}

+ (CTCallCenter *) callCenter;

// @property (nonatomic, copy) void (^callEventHandler)(CTCall *)

- (NSSet *) currentCalls;

@end

@interface CTCallCenter (Extensions)

- (id <CTCallCenterDelegate>) delegate;
- (void) setDelegate:(id <CTCallCenterDelegate>) d;

- (CTCall *) dial:(NSString *) number;	/* allows +, *, # and spaces within numbers */
- (BOOL) sendSMS:(NSString *) number message:(NSString *) message;

@end
