/* 
   GSServices.m

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:    Novemeber 1998
  
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#include <Foundation/NSArray.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSException.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSTimer.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSPortNameServer.h>
#include <Foundation/NSProxy.h>
#include <Foundation/NSConnection.h>
#include <Foundation/NSDistantObject.h>
#include <Foundation/NSMethodSignature.h>
#include <Foundation/NSInvocation.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSWorkspace.h>

#include "GSServices.h"

@interface GSListener : NSObject	// defined in NSWorkspace.m
+ (id) listener;
@end

static GSServices *__manager = nil;

// static id __servicesProvider = nil;

@implementation GSServices

+ (GSServices*) sharedManager
{									// Create a new listener to handle incoming 
NSString *p;						// services requests for this application.
									// Register listener as a service provider
	if (__manager)					// via NSRegisterServicesProvider().
		return __manager;

	// FIXME: we need a better way to specify this!

	p = [NSString stringWithFormat: @"%@/.mySTEP/%@", NSHomeDirectory(), @".mySTEPServices"];

	__manager = [GSServices alloc];
	__manager->servicesPath = [p retain];
	__manager->returnInfo = [[NSMutableSet alloc] initWithCapacity: 8];
	__manager->combinations = [[NSMutableDictionary alloc] initWithCapacity:8];

	[__manager loadServices];

	return __manager;
}

- (void) dealloc
{
	NSUnregisterServicesProvider([[NSBundle mainBundle] bundleIdentifier]);
	[languages release];
	[returnInfo release];
	[combinations release];
	[title2info release];
	[menuTitles release];
	[servicesMenu release];
	[servicesPath release];
	[disabledStamp release];
	[servicesStamp release];
	[allDisabled release];
	[allServices release];

	[super dealloc];
}

- (void) doService:(NSCell*)item
{
NSString *title = [self item2title: item];
NSDictionary *info = [title2info objectForKey: title];
NSArray *sendTypes = [info objectForKey: @"NSSendTypes"];
// NSArray *returnTypes = [info objectForKey: @"NSReturnTypes"];
// unsigned i, j;
// unsigned es = [sendTypes count];
// unsigned er = [returnTypes count];
NSWindow *resp = (NSWindow *) [[NSApp keyWindow] firstResponder];
id obj = nil;

	NSLog(@"doService: called");

//	for (i = 0; i <= es; i++)
		{
//		NSString *sendType = (i < es) ? [sendTypes objectAtIndex: i] : nil;

//		for (j = 0; j <= er; j++)
			{
//			NSString *returnType;

//			returnType = (j < er) ? [returnTypes objectAtIndex: j] : nil;
//			obj = [resp validRequestorForSendType: sendType
//                                       returnType: returnType];
			obj = [resp validRequestorForSendType: NSStringPboardType
                                       returnType: NSStringPboardType];
			if (obj != nil)
            	{
				NSPasteboard *pb = [NSPasteboard pasteboardWithUniqueName];

				if ([obj writeSelectionToPasteboard: pb
					     types: sendTypes] == NO)
					{
					NSRunAlertPanel(nil,
									@"object failed to write to pasteboard",
									@"Continue", nil, nil);
					}
				else 
					if (NSPerformService(title, pb) == YES)
						{
		  				if ([obj readSelectionFromPasteboard: pb] == NO)
		    				{
		      				NSRunAlertPanel(nil,
									@"object failed to read from pasteboard",
									@"Continue", nil, nil);
						}
					}

				return;
				}
			}
		}
}

// Use tag in menu cell to identify
- (NSString*) item2title:(NSCell*)item		// slot in menu titles array that
{											// contains the full title of the
	unsigned p;									// service.  Return nil if this is
												// not one of our servicemenu cells
	if ([item target] != self || ((p = [item tag]) > [menuTitles count]))				
		return nil;
	
	return [menuTitles objectAtIndex: p];
}

- (void) loadServices
{
NSFileManager *mgr = [NSFileManager defaultManager];
NSDate *stamp = [NSDate date];
BOOL changed = NO;

	if ([mgr fileExistsAtPath: servicesPath])
    	{
		NSDictionary *attr;
		NSDate *mod;

		attr = [mgr fileAttributesAtPath: servicesPath traverseLink: YES];
		mod = [attr objectForKey: NSFileModificationDate];
		if (servicesStamp == nil || [servicesStamp laterDate: mod] == mod)
			{
			NSString *s = [NSString stringWithContentsOfFile: servicesPath];
			id plist = [s propertyList];

			if (plist)
				{
				stamp = mod;
				ASSIGN(allServices, plist);
				changed = YES;
				}
			else
				NSLog(@"unable to load mySTEP services dictionary file: %@", 
						servicesPath);
		}	}							// Track most recent version of file 
	ASSIGN(servicesStamp, stamp);		// loaded or last time we checked
	if (changed)
		[self rebuildServices];
}

- (NSDictionary*) menuServices
{
	if (allServices == nil)
		[self loadServices];

	return title2info;
}

- (void) rebuildServices
{
NSDictionary *services;
NSUserDefaults *defs;
NSMutableArray *newLang;
NSMutableSet *alreadyFound;
NSMutableDictionary *newServices;
unsigned pos;

	if (allServices == nil)
		return;

	defs = [NSUserDefaults standardUserDefaults];
	newLang = [[[defs arrayForKey: @"Languages"] mutableCopy] autorelease];
	if (newLang == nil)
		newLang = [NSMutableArray arrayWithCapacity: 1];

	if ([newLang containsObject:  @"default"] == NO)
		[newLang addObject: @"default"];

	ASSIGN(languages, newLang);
	services = [allServices objectForKey: @"NSServices"];
	newServices = [NSMutableDictionary dictionaryWithCapacity: 16];
	alreadyFound = [NSMutableSet setWithCapacity: 16];

			//  Build dictionary of services we can use.
			//  1. make dictionary keyed on preferred menu item language
			//  2. don't include entries for services already examined.
			//  3. don't include entries for menu items specifically disabled.
			//  4. don't include entries for which we have no registered types.
	for (pos = 0; pos < [languages count]; pos++)
		{
		NSString *lang = [languages objectAtIndex: pos];

//		byLanguage = [services objectForKey: [languages objectAtIndex: pos]];
//		if (byLanguage != nil)
			{
			NSEnumerator *enumerator = [services objectEnumerator];
			id service;

			while ((service = [enumerator nextObject]) != nil)
            	{
				NSDictionary *item = [service objectForKey: @"NSMenuItem"];
				NSString *menuItem = [item objectForKey: lang];

				NSDebugLog(@"rebuildServices found: '%@'", menuItem);
				if ([alreadyFound member: service] != nil)
					continue;

				[alreadyFound addObject: service];
										// See if this service item is disabled
//				if ([allDisabled member: menuItem] != nil)
//					continue;

				[newServices setObject: service forKey: menuItem];
		}	}	}

	if ([newServices isEqual: title2info] == NO)
		{
		NSArray *titles;

		ASSIGN(title2info, newServices);
		titles = [title2info allKeys];
		titles = [titles sortedArrayUsingSelector: @selector(compare:)];
		ASSIGN(menuTitles, titles);
		[self rebuildServicesMenu];
		}
}

- (void) rebuildServicesMenu
{
	if (servicesMenu)
		{
		NSMutableSet *keyEquivalents;
		unsigned loc0;
		unsigned loc1 = 0;
		SEL sel = @selector(doService:);
		NSMenu *submenu = nil;
		NSArray *itemArray = [[servicesMenu itemArray] retain];
		unsigned pos = [itemArray count];

		while (pos > 0)
			[servicesMenu removeItem: [itemArray objectAtIndex: --pos]];

		[itemArray release];
	
		keyEquivalents = [NSMutableSet setWithCapacity: 4];
		for (loc0 = pos = 0; pos < [menuTitles count]; pos++)
			{
			NSString *title = [menuTitles objectAtIndex: pos];
			NSString *equiv = @"";
			NSDictionary *info = [title2info objectForKey: title];
			NSRange r;
			unsigned lang;
			id item;	
			NSDictionary *titles = [info objectForKey: @"NSMenuItem"];
			NSDictionary *equivs = [info objectForKey: @"NSKeyEquivalent"];
									// Find the key equivalent corresponding to 
									// this menu title in service definition.
			for (lang = 0; lang < [languages count]; lang++)
				{
				NSString *language = [languages objectAtIndex: lang];
				NSString *t = [titles objectForKey: language];
	
				if ([t isEqual: title])
					equiv = [equivs objectForKey: language]; 
				}
									// Make a note that we are using the key 
			if (equiv)				// equivalent, or set to nil if we have
				{					// already used it in this menu.
				if ([keyEquivalents member: equiv] == nil)
					[keyEquivalents addObject: equiv];
				else
					equiv = @"";
				}
	
			r = [title rangeOfString: @"/"];
			if (r.length > 0)
				{
				NSString *subtitle = [title substringFromIndex: r.location+1];
				NSString *parentTitle = [title substringToIndex: r.location];
				NSMenu *menu;
	
				if ((item = [servicesMenu itemWithTitle: parentTitle]) == nil)
					{
					loc1 = 0;
					item = [servicesMenu insertItemWithTitle: parentTitle
										 action: 0
										 keyEquivalent: @""
										 atIndex: loc0++];
					menu = [[NSMenu alloc] initWithTitle: parentTitle];
					[servicesMenu setSubmenu: menu forItem: item];
					[menu release];
					}
				else
					menu = (NSMenu*)[item target];

				if (menu != submenu)
					{
					[submenu sizeToFit];
					submenu = menu;
					}
				item = [submenu insertItemWithTitle: subtitle
								action: sel
								keyEquivalent: equiv
								atIndex: loc1++];
				[item setTarget: self];
				[item setTag: pos];
				}
			else
				{
				item = [servicesMenu insertItemWithTitle: title
									 action: sel
									 keyEquivalent: equiv
									 atIndex: loc0++];
				[item setTarget: self];
				[item setTag: pos];
			}	}

		[submenu sizeToFit];
		[servicesMenu sizeToFit];
		[servicesMenu update];
		}
}
											// Set up connection to listen for 
- (void) registerAsServiceProvider			// incoming service requests.
{
	NSString *name = [[NSBundle mainBundle] bundleIdentifier];

	NS_DURING
		NSRegisterServicesProvider(self, name);
	NS_HANDLER
		NSLog(@"Warning: Could not register application due to exception: %@\n", [localException reason]);
	NS_ENDHANDLER
}			
			// Register send and return types that an object can handle - we
			// keep a note of all the possible combinations - 'returnInfo' is  
			// a set of all the return types that can be handled without a  
			// send.  'combinations' is a dictionary of all send types, with 
			// the assciated values being sets of possible return types.
- (void) registerSendTypes:(NSArray *)sendTypes
               returnTypes:(NSArray *)returnTypes
{
BOOL didChange = NO;
unsigned i;

	for (i = 0; i < [sendTypes count]; i++)
		{
		NSString *sendType = [sendTypes objectAtIndex: i];
		NSMutableSet *returnSet = [combinations objectForKey: sendType];

		if (returnSet == nil)
			{
			returnSet = [NSMutableSet setWithCapacity: [returnTypes count]];
			[combinations setObject: returnSet forKey: sendType];
			[returnSet addObjectsFromArray: returnTypes];
			didChange = YES;
        	}
		else
			{
          	unsigned count = [returnSet count];

			[returnSet addObjectsFromArray: returnTypes];
			if ([returnSet count] != count)
				didChange = YES;
        }	}

	i = [returnInfo count];
	[returnInfo addObjectsFromArray: returnTypes];
	if ([returnInfo count] != i)
		didChange = YES;

//	if (didChange)
//		[self rebuildServices];
}

- (NSMenu*) servicesMenu			{ return servicesMenu; }
- (id) servicesProvider				{ return NIMP; /* __servicesProvider; */ }

- (void) setServicesMenu:(NSMenu*)aMenu
{
	ASSIGN(servicesMenu, aMenu);
	[self rebuildServicesMenu];
}

- (int) setShowsServicesMenuItem:(NSString*)item to:(BOOL)enable
{
	// NSData *d;

	[self loadServices];
	if (allDisabled == nil)
		allDisabled = [[NSMutableSet setWithCapacity: 1] retain];
	if (enable)
		[allDisabled removeObject: item];
	else
		[allDisabled addObject: item];
//	d = [NSSerializer serializePropertyList: [allDisabled allObjects]];

//	return ([d writeToFile: disabledPath atomically: YES] == YES) ? 0 : -1;
	return  0;
}

- (BOOL) showsServicesMenuItem:(NSString*)item
{
	[self loadServices];

	return ([allDisabled member: item] == nil) ? YES : NO;
}

- (BOOL) validateMenuItem:(NSCell*)item
{
NSString *title = [self item2title: item];
NSDictionary *info = [title2info objectForKey: title];
NSArray *sendTypes = [info objectForKey: @"NSSendTypes"];
NSArray *returnTypes = [info objectForKey: @"NSReturnTypes"];
NSWindow *resp = (NSWindow *) [[NSApp keyWindow] firstResponder];
unsigned es = [sendTypes count];
unsigned er = [returnTypes count];
unsigned i, j;							// If the menu item is not in our map,
										// it must be the cell containing a  
	if (title == nil)					// sub-menu - so we see if any cell in 
		return YES;						// the submenu is valid.

	if (es == 0)						// The cell corresponds to one of our
		{								// services - check to see if there
		if (er == 0)					// is anything that can deal with it.
			{
			if ([resp validRequestorForSendType: nil returnType: nil] != nil)
				return YES;
			}
		else
			{
			for (j = 0; j < er; j++)
				{
				NSString *returnType = [returnTypes objectAtIndex: j];

				if ([resp validRequestorForSendType: nil
						  returnType: returnType] != nil)
					return YES;
		}	}	}
	else
		{
		for (i = 0; i < es; i++)
			{
			NSString *sendType = [sendTypes objectAtIndex: i];

			if (er == 0)
				{
				if ([resp validRequestorForSendType: sendType 
						  returnType: nil] != nil)
					return YES;
				}
			else
				{
				for (j = 0; j < er; j++)
					{
					NSString *returnType = [returnTypes objectAtIndex: j];

					if ([resp validRequestorForSendType: sendType
							  returnType: returnType] != nil)
						return YES;
		}	}	}	}

	return NO;
}

@end /* GSServices */


id GSContactApplication(NSString *appName, NSString *name, NSDate *expire)
{
id a;

	NS_DURING
		a = [NSConnection connectionWithRegisteredName:name host:@""];
		[a setRequestTimeout:1.0];	// should answer immediately
		[a setReplyTimeout:1.0];
		a = [a rootProxy];
	NS_HANDLER
		return nil;										// Fatal error in DO
	NS_ENDHANDLER

	if (a == nil)
		{
		if ([[NSWorkspace sharedWorkspace] launchApplication: appName] == NO)
			return nil;									// Unable to launch
		NS_DURING
			{
			a = [NSConnection connectionWithRegisteredName:name host:@""];
			[a setRequestTimeout:5.0];	// try again
			[a setReplyTimeout:5.0];
			a = [a rootProxy];
			}
		NS_HANDLER
			return nil;
		NS_ENDHANDLER
		}
	return [a retain];
}

BOOL
NSPerformService(NSString *serviceItem, NSPasteboard *pboard)
{
double seconds;
NSString *port, *timeout;
NSString *message, *selName, *userData, *appPath, *error = nil;
NSDictionary *service = [[__manager menuServices] objectForKey: serviceItem];
NSConnection *connection;
NSDate *finishBy;
id provider;
SEL msgSel;
// IMP msgImp;

	if (service == nil)
		{
		NSRunAlertPanel(nil, [NSString stringWithFormat: 
						@"No service matching '%@'", serviceItem],
						@"Continue", nil, nil);
		return NO;										// No matching service.
		}

	port = [service objectForKey: @"NSPortName"];
	timeout = [service objectForKey: @"NSTimeout"];
	if (timeout && [timeout floatValue] > 100)
		seconds = [timeout floatValue] / 1000.0;
	else
		seconds = 20.0;

	finishBy = [NSDate dateWithTimeIntervalSinceNow: seconds];
	appPath = [service objectForKey: @"ServicePath"];
	userData = [service objectForKey: @"NSUserData"];
	message = [service objectForKey: @"NSMessage"];
	selName = [message stringByAppendingString: @":userData:error:"];

	if ((NSSelectorFromString(selName)) == NULL)					
		{
#if QUESTIONABLE
		NSMethodSignature *sig;					// If there is no selector - we
		const char *name;						// need to generate one with
		const char *type;						// the appropriate types.

		sig = [NSMethodSignature _signatureWithObjCTypes: "v@:@@^@"];
		type = [sig _methodType];
		name = [selName cString];
		// FIXME
		msgSel = sel_register_typed_name(name, type);
#endif
		}
	if ((provider = GSContactApplication(appPath, port, finishBy)) == nil)
		{
		// FIXME: should this really be an alert panel?
		NSRunAlertPanel(nil, [NSString stringWithFormat:
				@"Failed to contact service provider for '%@'", serviceItem],
				@"Continue", nil, nil);
		return NO;
		}

	connection = [(NSDistantObject*)provider connectionForProxy];
	seconds = [finishBy timeIntervalSinceNow];
	[connection setRequestTimeout: seconds];
	[connection setReplyTimeout: seconds];

	NS_DURING
		{
		[provider performService: selName
				  withPasteboard: pboard
				  userData: userData
				  error: &error];
		}
	NS_HANDLER
		error = [NSString stringWithFormat: @"%@", [localException reason]];
	NS_ENDHANDLER

	if (error != nil)
		{
		NSLog(@" caught error: %@", error);
		NSRunAlertPanel(nil, [NSString stringWithFormat:
				@"Failed to contact service provider for '%@'", serviceItem],
				@"Continue", nil, nil);
		return NO;
		}

	return YES;
}

int NSSetShowsServicesMenuItem(NSString *name, BOOL enabled)
{
	return [[GSServices sharedManager] setShowsServicesMenuItem: name to: enabled];
}

BOOL NSShowsServicesMenuItem(NSString * name)
{
	return [[GSServices sharedManager] showsServicesMenuItem: name];
}
