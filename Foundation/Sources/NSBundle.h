/* 
   NSBundle.h

   Interface to NSBundle class

   Copyright (C) 1995, 1997 Free Software Foundation, Inc.

   Author:	Adam Fedor <fedor@boulder.colorado.edu>
   Date:	1995
   Author:	H. Nikolaus Schaller <hns@computer.org>
   Date:	2003

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	07. April 2008 - aligned with 10.5 

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSBundle
#define _mySTEP_H_NSBundle

#import <Foundation/NSObject.h>

#define NSLocalizedString(key, comment) \
	[[NSBundle mainBundle] localizedStringForKey:(key) value:(key) table:nil]
#define NSLocalizedStringFromTable(key, tbl, comment) \
	[[NSBundle mainBundle] localizedStringForKey:(key) value:(key) table:(tbl)]
#define NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment) \
	[bundle localizedStringForKey:(key) value:(key) table:(tbl)]
#define NSLocalizedStringWithDefaultValue(key, tbl, bundle, value, comment) \
	[bundle localizedStringForKey:(key) value:(value) table:(tbl)]

@class NSString;
@class NSArray;
@class NSDictionary;
@class NSError;
@class NSMutableArray;
@class NSMutableDictionary;
@class NSMutableSet;

extern NSString *NSBundleDidLoadNotification;
extern NSString *NSLoadedClasses;

enum {
	NSBundleExecutableArchitectureI386      = 0x00000007,
	NSBundleExecutableArchitecturePPC       = 0x00000012,
	NSBundleExecutableArchitectureX86_64    = 0x01000007,
	NSBundleExecutableArchitecturePPC64     = 0x01000012
};

@interface NSBundle : NSObject
{
    NSString *_path;
    NSString *_bundleContentPath;
    NSMutableSet *_bundleClasses;				// list of class names (if known)
    NSMutableDictionary *_searchPaths;			// cache
	NSMutableArray *_localizations;				// cache
	NSArray *_preferredLocalizations;	// cache
	Class _principalClass;
    NSDictionary *_infoDict;
	unsigned int _bundleType;
	BOOL _codeLoaded;
}

+ (NSArray *) allBundles;
+ (NSArray *) allFrameworks;
+ (NSBundle *) bundleForClass:(Class) aClass;
+ (NSBundle *) bundleWithIdentifier:(NSString *) ident;
+ (NSBundle *) bundleWithPath:(NSString *) path;
+ (NSBundle *) mainBundle;
+ (NSString *) pathForResource:(NSString *) name
						ofType:(NSString *) ext
				   inDirectory:(NSString *) bundlePath;
+ (NSArray *) pathsForResourcesOfType:(NSString *) ext
						  inDirectory:(NSString *) bundlePath;
+ (NSArray *) preferredLocalizationsFromArray:(NSArray *) array;
+ (NSArray *) preferredLocalizationsFromArray:(NSArray *) array
							   forPreferences:(NSArray *) pref;

- (NSString *) builtInPlugInsPath;
- (NSString *) bundleIdentifier;
- (NSString *) bundlePath;
- (Class) classNamed:(NSString *) className;
- (NSString *) developmentLocalization;
- (NSArray *) executableArchitectures;
- (NSString *) executablePath;
- (NSDictionary *) infoDictionary;
- (id) initWithPath:(NSString *) fullpath;
- (BOOL) isLoaded;
- (BOOL) load;
- (BOOL) loadAndReturnError:(NSError **) error;
- (NSArray *) localizations;
- (NSDictionary *) localizedInfoDictionary;
- (NSString *) localizedStringForKey:(NSString *) key	
							   value:(NSString *) value
							   table:(NSString *) tableName;
- (id) objectForInfoDictionaryKey:(NSString *) key;
- (NSString *) pathForAuxiliaryExecutable:(NSString *) name;
- (NSString *) pathForResource:(NSString *) name
						ofType:(NSString *) ext;
- (NSString *) pathForResource:(NSString *) name
						ofType:(NSString *) ext	
				   inDirectory:(NSString *) subpath;
- (NSString *) pathForResource:(NSString *) name
						ofType:(NSString *) ext	
				   inDirectory:(NSString *) subpath
			   forLocalization:(NSString *) locale;
- (NSArray *) pathsForResourcesOfType:(NSString *) extension
						  inDirectory:(NSString *) subpath;
- (NSArray *) pathsForResourcesOfType:(NSString *) extension
						  inDirectory:(NSString *) subpath
					  forLocalization:(NSString *) locale;
- (NSArray *) preferredLocalizations;
- (BOOL) preflightAndReturnError:(NSError **) error;
- (Class) principalClass;
- (NSString *) privateFrameworksPath;
- (NSString *) resourcePath;
- (NSString *) sharedFrameworksPath;
- (NSString *) sharedSupportPath;
- (BOOL) unload;

@end

#endif /* _mySTEP_H_NSBundle */
