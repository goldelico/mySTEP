/* 
   NSNotification.h

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided under the 
   terms of the libFoundation BSD type license (See the Readme file).
*/

#ifndef _mySTEP_H_NSNotification
#define _mySTEP_H_NSNotification

#import <Foundation/NSObject.h>

@class NSMutableDictionary;
@class NSDictionary;
@class NSMutableArray;
@class NSArray;

@interface NSNotification : NSObject  <NSCoding, NSCopying>
{
	id _name;
	id _object;
	id _info;
	id _queued;
}

+ (NSNotification *) notificationWithName:(NSString *) name
								  object:(id) object;
+ (NSNotification *) notificationWithName:(NSString *) aName
								  object:(id) anObject
								  userInfo:(NSDictionary *) userInfo;

- (NSString *) name;    
- (id) object;
- (NSDictionary *) userInfo;

// this is not a public method in Cocoa API but we provide it anyway

- (id) initWithName:(NSString *) aName 
			 object:(id) anObject 
		   userInfo:(NSDictionary *) anUserInfo;

@end /* NSNotification */


@interface NSNotificationCenter : NSObject 
{
    id _nameToObjects;
    id _nullNameToObjects;
}

+ (id) defaultCenter;

- (void) addObserver: observer
			selector:(SEL) selector 
				name:(NSString *) name 
			  object:(id) object;
- (void) postNotification:(NSNotification *) notification;
- (void) postNotificationName:(NSString *) notificationName
					   object:(id) object;
- (void) postNotificationName:(NSString *) notificationName 
					   object:(id) object
					 userInfo:(NSDictionary *) userInfo;
- (void) removeObserver:(id) observer;
- (void) removeObserver:(id) observer
				   name:(NSString *) name
				 object:(id) object;

@end /* NSNotificationCenter */

#endif /* _mySTEP_H_NSNotification */
