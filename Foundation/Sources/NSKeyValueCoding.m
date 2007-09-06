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

@implementation NSObject (NSKeyValueCoding)

+ (BOOL) accessInstanceVariablesDirectly;
{
	return YES;
}

- (id) valueForKeyPath:(NSString *) str;
{
	id o=self;
	NSEnumerator *e=[[str componentsSeparatedByString:@"."] objectEnumerator];
	NSString *key;
	while(o && (key=[e nextObject]))
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

- (id) valueForKey:(NSString *) str;
{
	SEL s=NSSelectorFromString(str);
	// FIXME: should look for getters like str, _str, isStr, getStr etc.
	if(s && [self respondsToSelector:s])
		return [self performSelector:s];
	if([isa accessInstanceVariablesDirectly])
		{ // not disabled: try to access instance variable directly
		struct objc_class *class;
		const char *varName=[str UTF8String];
		for(class=isa; class != Nil; class = class_get_super_class(class))
			{ // walk upwards through class tree
			struct objc_ivar_list *ivars;
			if((ivars = class->ivars))
				{ // go through instance variables
				int i;
				for(i = 0; i < ivars->ivar_count; i++) 
					{
					struct objc_ivar ivar = ivars->ivar_list[i];
					if(!ivar.ivar_name)
						continue;	// no name - skip
					if(strcmp(ivar.ivar_name, varName) == 0 || (ivar.ivar_name[0]=='_' && strcmp(ivar.ivar_name+1, varName) == 0)) 
						{
						// FIXME: should take a look at ivar_type to be an id
						id *vp=(id *) (((char *)self) + ivar.ivar_offset);
						return *vp;	// get object
						}
					}
				}
			}
		}
	return [self valueForUndefinedKey:str];
}

- (void) setValue:(id) val forKey:(NSString *) str;
{
	NSString *ss=[NSString stringWithFormat:@"set%@%@:", [[str substringToIndex:1] capitalizedString], [str substringFromIndex:1]];
	SEL s=NSSelectorFromString(ss);
#if 0
	NSLog(@"setter = %@ (%@)", ss, NSStringFromSelector(s));
	NSLog(@"%@: setValue:forKeyPath:%@ to %@", self, str, val);
#endif
	if(s && [self respondsToSelector:s])
		{
		if(!val)
			[self setNilValueForKey:str];
		[self performSelector:s withObject:val];
		return;
		}
	if([isa accessInstanceVariablesDirectly])
		{
		struct objc_class *class;
		const char *varName=[str UTF8String];
		for(class=isa; class != Nil; class = class_get_super_class(class))
			{ // walk upwards through class tree
			struct objc_ivar_list *ivars;
			if((ivars = class->ivars))
				{ // go through instance variables
				int i;
				for(i = 0; i < ivars->ivar_count; i++) 
					{
					struct objc_ivar ivar = ivars->ivar_list[i];
					if(!ivar.ivar_name)
						continue;	// no name - skip
					if(strcmp(ivar.ivar_name, varName) == 0 || (ivar.ivar_name[0]=='_' && strcmp(ivar.ivar_name+1, varName) == 0)) 
						{
						// FIXME: should take a look at ivar_type to be an id
						id *vp=(id *) (((char *)self) + ivar.ivar_offset);
						[*vp autorelease];
						*vp=[val retain];
						NSDebugLog(@"found it!");
						return;
						}
					}
				}
			}
		}
	[self setValue:(id) val forUndefinedKey:str];
}

- (void) setValue:(id)value forUndefinedKey:(NSString *)key
{
	[NSException raise:NSUndefinedKeyException format:@"setValue:forKey:%@ is undefined: %@", key, self];
}

- (void) setNilValueForKey:(NSString *)key
{
	[NSException raise:NSInvalidArgumentException format:@"can't setNilValue: for key %@: %@", key, self];
}

- (id) valueForUndefinedKey:(NSString *)key
{
	[NSException raise:NSUndefinedKeyException format:@"value: for key %@ is undefined: %@", key, self];
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
- (id) valueForKey:(NSString *) key { return [self objectForKey:key]; }
@end

@implementation NSMutableDictionary (NSKeyValueCoding)
- (void) setValue:(id) value forKey:(NSString *) key { [self setObject:value forKey:key]; }
@end

