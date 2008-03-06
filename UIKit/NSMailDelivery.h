//
//  NSMailDelivery.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jul 26 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *NSMIMEMailFormat;
extern NSString *NSASCIIMailFormat;

extern NSString *NSSMTPDeliveryProtocol;
extern NSString *NSSendmailDeliveryProtocol;

@interface NSMailDelivery : NSObject

+ (BOOL) hasDeliveryClassBeenConfigured;	// if any delivery account has been defined

+ (BOOL) deliverMessage:(NSString *) theBody subject:(NSString *) theSubject to:(NSString *) theEmailDest;
+ (BOOL) deliverMessage:(NSAttributedString *) messageBody	// all formatting will be discarded for NSASCIIMailFormat
				headers:(NSDictionary *) messageHeaders		// NSArray dictrionary objects will be converted into a comma separated list
				 format:(NSString *) fmt
			   protocol:(NSString *) proto;					// use nil to specify platform default format

@end
