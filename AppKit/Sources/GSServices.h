/* 
   GSServices.h

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:    Novemeber 1998
  
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_GSServices
#define _mySTEP_H_GSServices

@class NSArray;
@class NSCell;
@class NSDate;
@class NSMenu;
@class NSMutableArray;
@class NSMutableDictionary;
@class NSMutableSet;
@class NSString;

@interface GSServices : NSObject
{
	NSMenu *servicesMenu;
	NSMutableArray *languages;
	NSMutableSet *returnInfo;
	NSMutableDictionary *combinations;
	NSMutableDictionary *title2info;
	NSArray *menuTitles;
	NSString *servicesPath;
	NSDate *disabledStamp;
	NSDate *servicesStamp;
	NSMutableSet *allDisabled;
	NSMutableDictionary	*allServices;
}

+ (GSServices*) sharedManager;

- (void) doService:(NSCell*)item;
- (NSString*) item2title:(NSCell*)item;
- (void) loadServices;
- (NSDictionary*) menuServices;
- (void) rebuildServices;
- (void) rebuildServicesMenu;
- (void) registerAsServiceProvider;
- (void) registerSendTypes:(NSArray *)sendTypes
               returnTypes:(NSArray *)returnTypes;
- (NSMenu *) servicesMenu;
- (id) servicesProvider;
- (void) setServicesMenu:(NSMenu *)anObject;
- (int) setShowsServicesMenuItem:(NSString*)item to: (BOOL)enable;
- (BOOL) showsServicesMenuItem:(NSString*)item;
- (BOOL) validateMenuItem:(NSCell*)item;

@end

id GSContactApplication(NSString *appName, NSString *port, NSDate *expire);

@interface NSObject (GSProvider)
- (void) performService:(NSString*)name withPasteboard:(NSPasteboard*)pb userData:(NSString*)ud  error:(NSString**)e;
@end

#endif /* _mySTEP_H_GSServices */
