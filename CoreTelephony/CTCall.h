//
//  CTCall.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 04.07.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString const *CTCallStateDialing;
extern NSString const *CTCallStateIncoming;
extern NSString const *CTCallStateConnected;
extern NSString const *CTCallStateDisconnected;

@interface CTCall : NSObject
{
	NSString *callID;
	NSString *callState;
}


- (NSString *) callID;
- (NSString *) callState;

@end

@interface CTCall (Extensions)

- (void) terminate;
- (void) hold;
- (void) reject;	// if incoming
- (void) divert;

@end
