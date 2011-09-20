/* 
   NSUserDefaults.m

   Implementation for NSUserDefaults for mySTEP

   Copyright (C) 1995, 1996 Free Software Foundation, Inc.

   Author:  Georg Tuparev <Tuparev@EMBL-Heidelberg.de>
   Date:    1995
  
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.

   hns@computer.org: Adapted to use the MacOS X convention of ~/Library/Preferences/domain.plist
   July 2004 - reworked to be even more compatible in file formats and API
 
   FIXME: probably not thread safe!

*/ 

#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSArchiver.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSProcessInfo.h>
// #import <Foundation/NSDistributedLock.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSString.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSNull.h>

// Class variables

static NSString *__userDefaultsDB = @"Library/Preferences";
static NSUserDefaults *__sharedDefaults = nil;

#define NSGLOBALDOMAINFILE @".GlobalPreferences"

@implementation NSUserDefaults

- (NSDictionary *) _createArgumentDictionary
{ // allows to call us as application.app file -NSFlag -NSKey value etc. -> NSFlag="", NSKey=value
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	NSEnumerator *e = [args objectEnumerator];
	NSMutableDictionary *argDict = [NSMutableDictionary dictionaryWithCapacity:2];
	id key=nil, val;
	
	while (key || (key = [e nextObject]))
			{ // a leading '-' indicates a defaults key.
				if ([key hasPrefix:@"-"]) 
						{
							key = [key substringFromIndex: 1];			// strip '-'
							if (!(val = [e nextObject]))
									{ // No more args
										[argDict setObject:@"" forKey:key];		// arg is empty.
										break;
									}
							else if ([val hasPrefix:@"-"])
									{ // another argument follows directly
										[argDict setObject:@"" forKey:key];		// arg is empty.
										key = val;
										continue;	// inner loop
									}
							else
								[argDict setObject:val forKey:key];		// Real parameter
						}
				key=nil;	// fetch next one
			}

	return argDict;
}

- (void) _changePersistentDomain:(NSString *)domainName
{ // put on the list of domains to be written to disk on next sync
#if 0
	NSLog(@"_changePersistentDomain:%@", domainName);
#endif
	if (!_changedDomains)
		{
		_changedDomains = [[NSMutableArray arrayWithCapacity:5] retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: NSUserDefaultsDidChangeNotification 
							  object: nil];
		}
	
	if (!_timerActive)
		{
		_timerActive=[NSTimer scheduledTimerWithTimeInterval:30
				 target:self
				 selector:@selector(synchronize)
				 userInfo:nil
				 repeats:NO];
		}
	if(![_changedDomains containsObject:domainName])
		[_changedDomains addObject:domainName]; // only if not yet stored
#if 0
	NSLog(@"changedDomains=%@", _changedDomains);
#endif
}

- (NSString *) _filePathForDomain:(NSString *) domain;
{
	NSString *path;
	if([domain isEqualToString:NSGlobalDomain])
		domain=NSGLOBALDOMAINFILE;   // surrogate file name (invisible)
	path=[NSString stringWithFormat:@"%@/%@.plist", _defaultsDatabase, domain];
#if 1
	NSLog(@"path=%@", path);
#endif
	return path;
}

+ (NSUserDefaults *) standardUserDefaults
{
	if(!__sharedDefaults)
		{ // create
		NSString *NSApplicationDomain;
		NSMutableArray *sl=[NSMutableArray arrayWithCapacity:5];	// search list to be created
		NSBundle *b=[NSBundle mainBundle];
#if 0
		NSLog(@"create standardUserDefaults");
#endif
		if(!b)
			return nil; // can't initialize (yet)
		__sharedDefaults=[self new];	// create and save
		[sl addObject:NSArgumentDomain];		// NSArgumentDomain
		/*
		 * NOTE: the following code may recurse!
		 * e.g. through [NSBundle mainBundle] objectForInfoDictionaryKey
		 * uses the shared defaults to determine the user language resource to look at
		 * but as we already have set __sharedDefaults with an empty search list,
		 * all objectForKey: calls will return nil
		 */
		NSApplicationDomain = [b objectForInfoDictionaryKey:@"CFBundleIdentifier"];  // use if available (might be nil)
#if 0
		NSLog(@"mainBundle=%@", b);
		NSLog(@"  Info.plist=%@", [b infoDictionary]);
		NSLog(@"  NSApplicationDomain=%@", NSApplicationDomain);
#endif
		if(NSApplicationDomain)
			[sl addObject:NSApplicationDomain];		// Application is identified by Bundle Identifier
		[sl addObject:NSGlobalDomain];					// NSGlobalDomain
		// Preferred languages
		// note! this can become recursive if we want to retrieve the userLanguages from the UserDefaults...
		[sl addObjectsFromArray:[NSLocale availableLocaleIdentifiers]];
		[sl addObject:NSRegistrationDomain];	// NSRegistrationDomain
		[__sharedDefaults setSearchList:sl];	// and assign
		}
	return __sharedDefaults;	// already defined
}

+ (void) resetStandardUserDefaults
{
	[__sharedDefaults synchronize];
	[__sharedDefaults release];
	__sharedDefaults=nil;
}

- (id) init	{ return [self initWithUser:NSUserName()]; }

- (id) initWithUser:(NSString *)userName
{ // Initializes defaults for the specified user - empty search list unless we initialize the sharedDefaults
	NSString *home;
	if (!(home = NSHomeDirectoryForUser(userName)))
		{
		NSLog(@"NSUserDefaults: invalid user name'%@'", userName);
		[self release];
		return nil;
		}
	if (!_defaultsDatabase)
		{
		_defaultsDatabase = [[NSString stringWithFormat:@"%@/%@", home, __userDefaultsDB] retain];  // the defaults directory
		if(![[NSFileManager defaultManager] fileExistsAtPath:_defaultsDatabase] && 
		   ![[NSFileManager defaultManager] createDirectoryAtPath:_defaultsDatabase
									  withIntermediateDirectories:YES
													   attributes:nil
															error:NULL])	// try to create
			[NSException raise:NSGenericException format:@"NSUserDefaults: could not create user defaults database '%@'", _defaultsDatabase];
		}
	_searchList = [[NSMutableArray array] retain];	// start with an empty search list
	_tempDomains = [[NSMutableDictionary dictionaryWithCapacity:10] retain];	// set volatile domains
	[_tempDomains setObject:[NSMutableDictionary dictionaryWithCapacity:10] forKey:@"English"];
	[_tempDomains setObject:[self _createArgumentDictionary] forKey:NSArgumentDomain];
	[_tempDomains setObject:[NSMutableDictionary dictionaryWithCapacity:10] forKey:NSRegistrationDomain];	
	_persDomains = [[NSMutableDictionary dictionaryWithCapacity:10] retain];	// set persistent domains cache
	return self;
}

- (void) dealloc
{
	[_searchList release];
	[_persDomains release];
	[_tempDomains release];
	[_changedDomains release];
	[super dealloc];
}

- (NSString *) description
{
	NSString *s = [super description];
	NSMutableString *desc = [NSMutableString stringWithString:s];

	// append whatever extensions

	return desc;
}

- (NSArray *) arrayForKey:(NSString *)defaultName
{
	id obj = [self objectForKey:defaultName];	
	return obj && [obj isKindOfClass:[NSArray class]] ? obj : nil;
}

- (BOOL) boolForKey:(NSString *)defaultName
{
	id obj = [self stringForKey:defaultName];
	return ((obj) && ([obj isEqualToString:@"YES"] 
			|| [obj isEqualToString:@"yes"] || [obj intValue])) ? YES : NO;
}

- (NSData *) dataForKey:(NSString *)defaultName
{
	id obj = [self objectForKey:defaultName];
	return obj && [obj isKindOfClass:[NSData class]] ? obj : nil;
}

- (NSDictionary *) dictionaryForKey:(NSString *)defaultName
{
	id obj = [self objectForKey:defaultName];
	return obj && [obj isKindOfClass:[NSDictionary class]] ? obj : nil;
}

- (float) floatForKey:(NSString *)defaultName
{
	id obj = [self stringForKey:defaultName];
	return obj ? [obj floatValue] : 0.0;
}

- (int) integerForKey:(NSString *)defaultName
{
	id obj = [self stringForKey:defaultName];
	return obj ? [obj intValue] : 0;
}

- (id) objectForKey:(NSString *)defaultName
{
	NSEnumerator *e=[_searchList objectEnumerator];
	NSString *domain;
	NSDictionary *obj=nil;
#if 0
	NSLog(@"objectForKey:%@", defaultName);
#endif
	while((domain=[e nextObject]))
		{
#if 0
		NSLog(@"try domain:%@ for key:%@", domain, defaultName);
#endif
		obj = [_tempDomains objectForKey:domain];
		if(obj)
			{ // volatile domain exists
			obj=[obj objectForKey:defaultName]; // try in volatile domains
			if(obj)
				break;  // found
			continue;   // don't try as persistent domain!
			}
		obj = [self persistentDomainForName:domain];   // fetch persistent domain (if it exists)
		if(obj)
			{
			obj = [obj objectForKey:defaultName];
			if(obj)
				break; // found
			}
		}
#if 0
	NSLog(@"objectForKey:%@ = %@", defaultName, obj);
#endif
	return obj;
}

- (void) removeObjectForKey:(NSString *)defaultName
{
	NSString *domain;
	NSMutableDictionary *dict;
	NSDictionary *dom;
	id obj;
	if([_searchList count] < 2)
		return; // assume that NSApplicationDomain is the second entry
	domain=[_searchList objectAtIndex:1];  // get name of NSApplicationDomain
	dom=[_persDomains objectForKey:domain];
	if(![dom isKindOfClass:[NSDictionary class]])
		return;	// cached as non-existent
	obj=[dom objectForKey:defaultName];
	if(!obj)
		return; // not defined
	if ([obj isKindOfClass: [NSMutableDictionary class]] == YES)
		dict = obj;
	else
		{
		dict = [[obj mutableCopy] autorelease];
		[_persDomains setObject: dict forKey: domain];  // store in persistent domains
		}
	[dict removeObjectForKey:defaultName];
	[self _changePersistentDomain:domain];
}

- (void) setBool:(BOOL)value forKey:(NSString *)defaultName
{
	[self setObject:((value) ? @"YES" : @"NO") forKey:defaultName];
}

- (void) setFloat:(float)value forKey:(NSString *)defaultName
{	
	[self setObject:[NSString stringWithFormat:@"%g", value] forKey:defaultName];
}

- (void) setInteger:(int)value forKey:(NSString *)defaultName
{
	[self setObject:[NSString stringWithFormat:@"%d", value] forKey:defaultName];
}

- (void) setObject:(id)value forKey:(NSString *)defaultName
{
	NSString *domain;
	NSMutableDictionary *dict;
	if(!value || [defaultName length] == 0)
		return; // ignore
	if([_searchList count] < 2)
		return; // assume that NSApplicationDomain is the second entry
	domain=[_searchList objectAtIndex:1];  // get name of NSApplicationDomain
#if 0
	NSLog(@"setObject:forKey:%@ inDomain:%@ = %@", defaultName, domain, value);
#endif
	dict = (NSMutableDictionary *) [self persistentDomainForName:domain];   // fetch
	if(!dict)
		{
		dict=[NSMutableDictionary dictionaryWithCapacity:10];   // create fresh domain
		[_persDomains setObject: dict forKey: domain];  // save in cache
		}
	[dict setObject:value forKey:defaultName];  // change value
	[self _changePersistentDomain:domain];		// register for writing to permanent storage
}

- (NSArray *) stringArrayForKey:(NSString *)defaultName
{
	id obj, array = [self arrayForKey:defaultName];
	
	if (array)
		{
		NSEnumerator *e = [array objectEnumerator];
		
		while ((obj = [e nextObject]))
			if ( ! [obj isKindOfClass:[NSString class]])
				return nil;
		}

	return array;
}

- (NSString *) stringForKey:(NSString *)defaultName
{
	id obj = [self objectForKey:defaultName];
	if(!obj)
		return nil;
	return [obj description];
}

- (void) addSuiteNamed:(NSString *) domain;
{ // add to search path behind application identifier (if present)
	unsigned i=[_searchList count];
	if(i > 2)
		i=2;	// limit
	[_searchList insertObject:domain atIndex:i];	// add to search path behind Application domain (assuming its existence!)
}

- (void) removeSuiteNamed:(NSString *) domain;
{ // remove
	[_searchList removeObject:domain];	// remove from search path (might be any name!!!)
}

- (void) setSearchList:(NSArray*)newList
{
#if 0
	NSLog(@"setSearchList=%@", newList);
#endif
	[_searchList autorelease];
	_searchList = [newList mutableCopy];
}

- (NSMutableArray *) searchList			{ return _searchList; }
- (NSArray *) volatileDomainNames		{ return [_tempDomains allKeys]; }

- (NSArray *) persistentDomainNames	
{ // should return array of ALL domains, including @"NSGlobalDomain" all .plist files
	NSMutableArray *a=[NSMutableArray arrayWithCapacity:30];
	NSEnumerator *e=[[[NSFileManager defaultManager] directoryContentsAtPath:_defaultsDatabase] objectEnumerator];
	NSString *name;
	while((name=[e nextObject]))
		{
		if(![name hasSuffix:@".plist"])
			continue;   // property lists only
		name=[name stringByDeletingPathExtension];  // strip off
		if([name isEqualToString:NSGLOBALDOMAINFILE])
			name=NSGlobalDomain;	// substitute
		[a addObject:name]; // add to domain name list
		}
	return a;
}

// FIXME: this method appears to leak memory when loading a new domain from file

- (NSDictionary *) persistentDomainForName:(NSString *)domain
{ // try to load and cache this domain
	NSMutableDictionary *dict;
	static BOOL lock=NO;	// may be called recursively during initialization
#if 1
	NSLog(@"persistentDomainForName:%@ flag=%d", domain, lock);
#endif
	/*
	 * NOTE: avoid recursion
	 * through dictionaryWithContentsOfFile which tries to
	 * load a property list, which uses NSScanner, which uses NSCharacterSet, which uses NSBundle to load
	 * the character definition, which uses NSUserDefaults to locate a localized character set file,
	 * which again calls persistentDomainForName...
	 */
	if(lock)
		return [NSDictionary dictionary];	// return empty domain
	lock=YES;
	if([_tempDomains objectForKey:domain])
		[NSException raise:NSInvalidArgumentException format:@"Domain %@ already exists as volatile", domain];
	dict = [_persDomains objectForKey:domain]; // try in persistent domains cache
	if(!dict)
		{ // domain is not yet in cache - create & load - will be written back only if it is really changed
#if 1
		NSLog(@"load persistent domain from file %@", [self _filePathForDomain:domain]);
#endif
		NS_DURING
			dict=[NSMutableDictionary dictionaryWithContentsOfFile:[self _filePathForDomain:domain]];	// try to load
		NS_HANDLER
			// ignore exceptions - simply create a new dictionary
		NS_ENDHANDLER
		if(!dict || ![dict isKindOfClass:[NSDictionary class]])
			dict=(NSMutableDictionary *) [NSNull null];	// mark as non-existent (or corrupt)
#if 1
		NSLog(@"loaded %@", dict);
#endif
		[_persDomains setObject:dict forKey:domain]; // was able to load - replace in cache
		}
#if 1
	NSLog(@"found %@", dict);
#endif
	lock=NO;
	if([dict isKindOfClass:[NSNull class]])
		return nil;		// we know it doesn't exist
	return dict;
}

- (void) removePersistentDomainForName:(NSString *)domainName
{
	if ([_persDomains objectForKey:domainName])
		{
		[_persDomains removeObjectForKey:domainName];	// will also uncache a domain we know as non-existent
//		[self _changePersistentDomain:domainName];
		}
}

- (void) setPersistentDomain:(NSDictionary *)domain 
					forName:(NSString *)domainName
{
	if([_tempDomains objectForKey:domainName])
		[NSException raise:NSInvalidArgumentException format:@"Domain %@ already exists as volatile", domainName];
	[_persDomains setObject:domain forKey:domainName];  // save in cache (or replace NSNull entry)
	[self _changePersistentDomain:domainName];			// register for writing out
}

- (void) removeVolatileDomainForName:(NSString *)domainName
{
	[_tempDomains removeObjectForKey:domainName];
}

- (void) setVolatileDomain:(NSDictionary *)domain 
				   forName:(NSString *)domainName
{
	if([_persDomains objectForKey:domainName])
		[NSException raise:NSInvalidArgumentException format:@"Domain %@ already exists as persistent",domainName];
	[_tempDomains setObject:domain forKey:domainName];
}

- (NSDictionary *) volatileDomainForName:(NSString *)domainName
{
	return [_tempDomains objectForKey:domainName];
}

- (BOOL) synchronize
{
	NSEnumerator *e;
	NSString *domain;
#if 0
	NSLog(@"synchronize");
#endif
	[_timerActive invalidate];  // stop additional timer
	_timerActive=nil;
	e=[_changedDomains objectEnumerator]; // all changed domain names
	while((domain=[e nextObject]))
		{ // process this domain
#if 0
		NSLog(@"write to domain: %@", domain);
#endif
		if(![[_persDomains objectForKey:domain] writeToFile:[self _filePathForDomain:domain] atomically:YES])
			{ // write error
			NSLog(@"write error for %@", [self _filePathForDomain:domain]);
			return NO;
			}
		}
	[_changedDomains removeAllObjects];		// remove changes from list
	return YES;
}

- (NSDictionary *) dictionaryRepresentation
{
	NSEnumerator *e = [_searchList reverseObjectEnumerator];
	NSMutableDictionary *dictRep = [NSMutableDictionary dictionaryWithCapacity:10];
	id obj, dict;
	
	while ((obj = [e nextObject]))
		{ // merge all entries from domains in search list
		if ((dict = [_persDomains objectForKey:obj]) || (dict = [_tempDomains objectForKey:obj]))
			{
			if(![dict isKindOfClass:[NSNull class]])
				[dictRep addEntriesFromDictionary:dict];
			}
		}
	return dictRep;
}	

- (void) registerDefaults:(NSDictionary *)dictionary
{
	[_tempDomains setObject:dictionary forKey:NSRegistrationDomain];
}

- (BOOL) objectIsForcedForKey:(NSString *) key;
{
	return [self objectIsForcedForKey:key inDomain:NSRegistrationDomain];

}

- (BOOL) objectIsForcedForKey:(NSString *) key inDomain:(NSString *) domain;
{
	return NO;	// FIXME: we currently do not support this mechanism
}

@end
