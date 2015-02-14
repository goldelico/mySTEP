//
//  NSMailDelivery.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jul 26 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <Message/NSMailDelivery.h>

// these lines only define the interface
// You must also link your application to the private Mail.framework to use NSMailDelivery on mySTEP

@interface Mail : NSObject
+ (id) new;
- (void) setBody:(NSAttributedString *) str;
- (void) setHeaders:(NSDictionary *) str;
+ (BOOL) addRecord:(Mail *) record toFolder:(NSString *) folder;
@end

@interface MailAccount : NSObject
+ (NSString *) outbox;
+ (NSArray *) accountNames;
@end

@interface MailManager : NSObject
+ (id) sharedManager;
- (BOOL) pushMails;
@end

NSString *NSMIMEMailFormat=@"NSMIMEMailFormat";
NSString *NSASCIIMailFormat=@"NSASCIIMailFormat";

NSString *NSSMTPDeliveryProtocol=@"NSSMTPDeliveryProtocol";
NSString *NSSendmailDeliveryProtocol=@"NSSendmailDeliveryProtocol";

@implementation NSMailDelivery

+ (BOOL) hasDeliveryClassBeenConfigured;	// if any delivery account has been defined
{
#ifdef __mySTEP__
	return [[MailAccount accountNames] count] > 0;
#else
	return NO;
#endif
}

+ (BOOL) deliverMessage:(NSString *) theBody subject:(NSString *) theSubject to:(NSString *) theEmailDest;
{ // simple interface
#ifdef __mySTEP__
	NSDictionary *headers=[NSDictionary dictionaryWithObjectsAndKeys:
		theSubject, "Subject",
		theEmailDest, "To",
		nil];
	if([theBody isKindOfClass:[NSAttributedString class]])
	   return [self deliverMessage:(NSAttributedString *) theBody headers:headers format:NSMIMEMailFormat protocol:NSSMTPDeliveryProtocol];
	return [self deliverMessage:[NSAttributedString attributedStringWithString:theBody] headers:headers format:NSASCIIMailFormat protocol:NSSMTPDeliveryProtocol];
#else
	return NO;
#endif
}

+ (BOOL) deliverMessage:(NSAttributedString *) messageBody headers:(NSDictionary *) messageHeaders format:(NSString *) fmt protocol:(NSString *) proto;
{ // more general interface
#ifdef __mySTEP__
	Mail *m=[[Mail new] autorelease];
	if(!proto) proto=NSSMTPDeliveryProtocol;
	if(![proto isEqualToString:NSSMTPDeliveryProtocol])
		return NO;
	if([messageBody isKindOfClass:[NSString class]])
		[m setBody:messageBody];	// already ASCII format
	else if([fmt isEqualToString:NSASCIIMailFormat])
		[m setBody:(NSAttributedString *)[messageBody string]];	// convert to plain ASCII format
	else
		[m setBody:messageBody];	// attributed format
	[m setHeaders:messageHeaders];
	if(![Mail addRecord:m toFolder:[MailAccount outbox]])	// put in outbox - background process will try to deliver
		return NO;
	return [[MailManager sharedManager] pushMails];
#else
	return NO;
#endif
}

@end
