//
//  NSKeyValueCoding.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Oct 05 2004.
//  Copyright (c) 2004 DSITRI.
//
//    This file is part of the mySTEP Library and is provided
//    under the terms of the GNU Library General Public License.
//

#import <Foundation/NSKeyValueCoding.h>

NSString *NSTargetObjectUserInfoKey=@"NSTargetObjectUserInfoKey";
NSString *NSUnknownUserInfoKey=@"NSUnknownUserInfoKey";

@implementation NSObject (NSKeyValueCoding)

+ (BOOL) accessInstanceVariablesDirectly;
{
	return YES;	// default is YES
}

- (id) valueForKeyPath:(NSString *) str;
{
	id o=self;
	NSEnumerator *e=[[str componentsSeparatedByString:@"."] objectEnumerator];
	NSString *key;
//	NSLog(@"path=%@", str);
	while(o && (key=[e nextObject]))
//		NSLog(@"key=%@", str);
		// raise exception if !o?
		o=[o valueForKey:key];	// go down key path
	return o;	// return result
}

- (void) setValue:(id) val forKeyPath:(NSString *) str;
{
	id o=self;
	NSArray *path=[str componentsSeparatedByString:@"."];
	NSEnumerator *e=[path objectEnumerator];
	NSString *key=[e nextObject];
	NSString *nextKey;
	while(o && key)
		{
		nextKey=[e nextObject];
		if(!nextKey)
			{ // is last component
			[o setValue:val forKey:key];	// recursive descent
			return;
			}
		o=[o valueForKey:key];	// go down key path
		key=nextKey;
		}
	// exception?
}

// FIXME: we should define a cache to map the key to the IMP/relative address and necessary type conversions
// NOTE: this is a primitive implementaion which only sometimes works correctly

- (id) valueForKey:(NSString *) str;
{
	SEL s;
	IMP msg=NULL;
	const char *type=NULL;
	void *addr;	// address of return value
	Class sc;
	// FIXME: should also try to look for getter methods like <key>, _<key>, is<Key>, get<Key> etc.
#if 1
	NSLog(@"valueForKey: %@", str);
#endif
	/* if(found in cache)
	 get msg, type, addr from cache
	 else {
	 ...
	 add to cache
	 -> handle valueForUndefinedKey key special case so that we don't search again if we know
	 }*/

	/* check for is+str and _str */

	if((s=NSSelectorFromString(str)) && [self respondsToSelector:s])
		{
#if 1
		NSLog(@"selector: %@", NSStringFromSelector(s));
#endif
#if 0
		NSMethodSignature *sig=[self methodSignatureForSelector:s];	// FIXME: this can be pretty slow!
		type=[sig methodReturnType];
		msg = objc_msg_lookup(self, s);
#else
#if FIXME
		imp = class_getMethodImplementation(self, s);
		sc=[self class];
		struct objc_protocol_list *protocols = sc?sc->protocols:NULL;
		msg=m?m->method_imp:NULL;
		type=m?m->method_types:NULL;	// default (if we have an implementation)
		if(protocols)
			// do we need to scan through protocols?
			NSLog(@"not scanning protocols for valueForKey:%@", str);
#endif
#endif
//		NSLog(@"IMP = %p", msg);
		if (!msg)
			return [self _error:"unknown getter %s", sel_getName(s)];
		}
	else if([(sc=[self class]) accessInstanceVariablesDirectly])
		{ // not disabled: try to access instance variable directly
			const char *varName=[str UTF8String];
			Ivar ivar = object_getInstanceVariable(self, varName, NULL);
			addr = ((char *) self) + ivar_getOffset(ivar);
			type = ivar_getTypeEncoding(ivar);
			// use object_getInstanceVariable(varName) or class_getInstanceVariable(varName)
		}
//	NSLog(@"valueForKey type %s", type?type:"not found");
	if(!type)
		return [self valueForUndefinedKey:str];	// was not found
	switch(*type)
		{
			case _C_ID:
			case _C_CLASS:
				return msg ? (*(id (*)(id, SEL)) msg)(self, s) : *(id *) addr;	// get object value
			case _C_CHR:
			case _C_UCHR:
				{
				char ret=msg ? (*(char (*)(id, SEL)) msg)(self, s) :  *(char *) addr;
#if 0
				NSLog(@"valueForKey boxing char");
#endif
				// FIXME: separate signed and unsigned
				return [NSNumber numberWithChar:ret];
				}
			case _C_INT:
			case _C_UINT:
				{
				int ret=msg ? (*(int (*)(id, SEL)) msg)(self, s) :  *(int *) addr;
#if 0
				NSLog(@"valueForKey boxing int");
#endif
				// FIXME: separate signed and unsigned
				return [NSNumber numberWithInt:ret];
				}
			// FIXME: handle other types
		}
	NSLog(@"valueForKey:%@ does not return an object that we can convert (type=%s)", str, type);
	return [self valueForUndefinedKey:str];	// was not found	
}

- (void) setValue:(id) val forKey:(NSString *) str;
{
	SEL s;
	IMP msg=NULL;
	const char *type=NULL;
	void *addr;	// address of return value
	Class sc;
	const char *varName=[str UTF8String];
	int len=3+strlen(varName)+1+1;	// check if a matching setter exists (incl. room for "set" or "_is" and a ":")
	char *selName;
	if(!val)
		{
		[self setNilValueForKey:str];
		return;
		}
	selName=objc_malloc(len);
	strcpy(selName, "set");
	strcpy(selName+3, varName);	// append
	selName[3]=toupper(selName[3]);	// capitalize the first letter following "set"
	strcat(selName+3, ":");	// append a :
	NSAssert(strlen(selName) < len, @"buffer overflow");
	s=sel_registerName(selName);
#if 1
	NSLog(@"%p %@: setValue:forKey:%@ val=%@", self, self, str, val);
	NSLog(@"setter = %@ (%s)", NSStringFromSelector(s), selName);
#endif
	if(s && [self respondsToSelector:s])
		{
		// get method signature
		// if necessary, use [val intValue] etc. to fetch the argument with the correct type
		objc_free(selName);
		if(!val)
			[self setNilValueForKey:str];
		else
			[self performSelector:s withObject:val];
		return;
		}
#if 0
	NSLog(@"object does not respond to setter");
#endif
	else if([(sc=[self class]) accessInstanceVariablesDirectly])
		{ // not disabled: try to access instance variable directly
			const char *varName=[str UTF8String];
			Ivar ivar = object_getInstanceVariable(self, varName, NULL);
			addr = ((char *) self) + ivar_getOffset(ivar);
			type = ivar_getTypeEncoding(ivar);
			// use object_getInstanceVariable(varName) or class_getInstanceVariable(varName)
		}
	//	NSLog(@"valueForKey type %s", type?type:"not found");
	if(!type)
		{
		objc_free(selName);
		return [self setValue:val forUndefinedKey:str];	// was not found
		}
	switch(*type)	// FIXME: check parameter type!!!
	{
		case _C_ID:
		case _C_CLASS:
			if(msg)
				(*(void (*)(id, SEL, id)) msg)(self, s, val);
			else
				{
				[*(id *) addr autorelease];
				*(id *) addr = [val retain];	// set object value
				}
			objc_free(selName);
			return;
		case _C_CHR:
		case _C_UCHR:
		{
			if(msg)
				(*(void (*)(id, SEL, char)) msg)(self, s, [val boolValue]);
			else
				*(char *) addr = [val boolValue];
			objc_free(selName);
			return;
		}
		case _C_INT:
		case _C_UINT:
			{
			if(msg)
				(*(void (*)(id, SEL, int)) msg)(self, s, [val intValue]);
			else
				*(int *) addr = [val intValue];
			objc_free(selName);
			return;
			}
		// FIXME: handle other types
	}
	objc_free(selName);
	NSLog(@"setValue:forKey:%@ does not address an object that we can convert (type=%s)", str, type);
	[self setValue:(id) val forUndefinedKey:str];
}

- (void) setValue:(id)value forUndefinedKey:(NSString *)key
{
	[[NSException exceptionWithName:NSUndefinedKeyException reason:[NSString stringWithFormat:@"setValue:%@ forKey:%@ is undefined: %@", value, key, self]
												 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self, NSTargetObjectUserInfoKey, key, NSUnknownUserInfoKey, nil]] raise];
}

- (void) setNilValueForKey:(NSString *)key
{
	[NSException raise:NSInvalidArgumentException format:@"%@ can't setNilValue: for key %@: %@", self, key, self];
}

- (id) valueForUndefinedKey:(NSString *)key
{
	[[NSException exceptionWithName:NSUndefinedKeyException reason:[NSString stringWithFormat:@"valueForKey:%@ is undefined: %@", key, self]
												 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self, NSTargetObjectUserInfoKey, key, NSUnknownUserInfoKey, nil]] raise];
	return nil;
}

- (NSDictionary *) dictionaryWithValuesForKeys:(NSArray *)keys
{
	NSMutableDictionary *r=[NSMutableDictionary dictionaryWithCapacity:[keys count]];
	NSEnumerator *e=[keys objectEnumerator];
	NSString *key;
	id val;
	while((key=[e nextObject]))
		{
		val=[self valueForKey:key];
		if(!val) val=[NSNull null];
		[r setObject:val forKey:key];
		}
	return r;
}

- (void) setValuesForKeysWithDictionary:(NSDictionary *)keyedValues
{
	NSEnumerator *e=[keyedValues keyEnumerator];
	NSString *key;
	id val;
	while((key=[e nextObject]))
		{
		val=[keyedValues objectForKey:key];
		if([val isKindOfClass:[NSNull class]])
			val=nil;
		[self setValue:val forKey:key];
		}
}

- (BOOL) validateValue:(id *) val forKey:(NSString *) str error:(NSError **) error; { NIMP; return NO; }
- (BOOL) validateValue:(id *) val forKeyPath:(NSString *) str error:(NSError **) error; { NIMP; return NO; }
- (NSMutableArray *) mutableArrayValueForKey:(NSString *) str; { return NIMP; }
- (NSMutableArray *) mutableArrayValueForKeyPath:(NSString *) str; { return NIMP; }
- (NSMutableSet *) mutableSetValueForKey:(NSString *) key; { return NIMP; }
- (NSMutableSet *) mutableSetValueForKeyPath:(NSString *) keyPath; { return NIMP; }

@end

@implementation NSDictionary (NSKeyValueCoding)
- (id) valueForKey:(NSString *) key;
{
	if([key hasPrefix:@"@"])
		return [super valueForKey:[key substringFromIndex:1]];
	return [self objectForKey:key];
}
@end

@implementation NSMutableDictionary (NSKeyValueCoding)
- (void) setValue:(id)anObject forKey:(NSString *)aKey
{ // Modifying a dictionary for KVC (allowing for deletion)
	if(!anObject)
		[self removeObjectForKey:aKey];
	else
		[self setObject:anObject forKey:aKey];
}
@end

