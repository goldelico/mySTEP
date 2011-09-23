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
	NSString *peer;
	enum {
		kCTCallStateDialing,
		kCTCallStateIncoming,
		kCTCallStateConnected,
		kCTCallStateDisconnected
	} callState;
}

- (NSString *) callID;
- (NSString *) callState;

@end

@interface CTCall (Extensions)

- (NSString *) peerPhoneNumber;	// caller ID or called ID

- (void) terminate;
- (void) hold;
- (void) reject;	// if incoming
- (void) divert;

// set 
- (void) handsfree:(BOOL) flag;	// switch on handsfree speakers (or headset?)
- (void) mute:(BOOL) flag;	// mute microphone
- (void) volume:(float) value;	// general volume (earpiece, handsfree, headset)

- (void) sendDTMF:(NSString *) digit;	// 0..9, a-c, #, *

@end
