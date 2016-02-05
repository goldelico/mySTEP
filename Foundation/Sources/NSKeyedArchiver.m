/*
   NSKeyedArchiver.m

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:	Ovidiu Predescu <ovidiu@net-community.com>
   Date:	October 1997

   Complete rewrite based on GMArchiver code:
   Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: Jan 2006
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import "NSPrivate.h"

// Class variables
static NSMutableDictionary *_globalArchiverClassToAliasMappings = nil;
static NSMutableDictionary *_globalUnarchiverClassToAliasMappings = nil;

// constants
NSString *NSInvalidArchiveOperationException=@"NSInvalidArchiveOperationException";
NSString *NSInvalidUnarchiveOperationException=@"NSInvalidUnarchiveOperationException";

@implementation NSKeyedArchiver

+ (void) initialize
{
	_globalArchiverClassToAliasMappings = [NSMutableDictionary new];
}

+ (NSString *) classNameForClass:(Class)class;
{
	return [_globalArchiverClassToAliasMappings objectForKey:class];
}

+ (void) setClassName:(NSString *)codedName forClass:(Class)cls;
{
	if(codedName)
		[_globalArchiverClassToAliasMappings setObject:codedName forKey:cls];
	else
		[_globalArchiverClassToAliasMappings removeObjectForKey:cls];
}

+ (NSData *) archivedDataWithRootObject:(id)rootObject;
{
	NSMutableData *data=[NSMutableData dataWithCapacity:10000];
	NSKeyedArchiver *archiver = [[[self alloc] initForWritingWithMutableData:data] autorelease];
	[archiver setOutputFormat:NSPropertyListBinaryFormat_v1_0];
	[archiver encodeRootObject:rootObject];
	[archiver finishEncoding];	// any postprocessing
	return data;
}

+ (BOOL) archiveRootObject:(id)rootObject toFile:(NSString*)path
{
	return [[self archivedDataWithRootObject:rootObject] writeToFile:path atomically:YES];
}

- (NSString *) classNameForClass:(Class)class;
{
	return [_aliasToClassMappings objectForKey:class];
}

- (void) setClassName:(NSString *)codedName forClass:(Class)cls;
{
	if(codedName)
		{
		if(!_aliasToClassMappings)
			_aliasToClassMappings = [NSMutableDictionary new];
		[_aliasToClassMappings setObject:codedName forKey:cls];
		}
	else
		[_aliasToClassMappings removeObjectForKey:cls];
}

- (BOOL) allowsKeyedCoding; { return YES; }

- (void) finishEncoding;
{
	NSString *error;
	NSData *plist;
	if(_delegate && [_delegate respondsToSelector:@selector(archiverWillFinish:)])
		[_delegate archiverWillFinish:self];
	plist=[NSPropertyListSerialization dataFromPropertyList:_plist format:_outputFormat errorDescription:&error];
	if(!plist)
		; // error
	[_data setData:plist];
	if(_delegate && [_delegate respondsToSelector:@selector(archiverDidFinish:)])
		[_delegate archiverDidFinish:self];
}

- (NSPropertyListFormat) outputFormat; { return _outputFormat; }
- (void) setOutputFormat:(NSPropertyListFormat) format; { _outputFormat=format; }
- (id) delegate; { return _delegate; }
- (void) setDelegate:(id) delegate; { _delegate=delegate; }

- (id) initForWritingWithMutableData:(NSMutableData *) data
{
	if((self=[super init]))
		{
		_outputFormat=NSPropertyListBinaryFormat_v1_0;	// default to binary
		_data=[data retain];				// where to write to
		_plist=[NSMutableDictionary new];	// create root property list
		[_plist setObject:NSStringFromClass([self class]) forKey:@"$archiver"];
		[_plist setObject:[NSMutableArray arrayWithCapacity:100] forKey:@"$objects"];
		[_plist setObject:[NSMutableDictionary dictionaryWithCapacity:20] forKey:@"$top"];
		[_plist setObject:[NSNumber numberWithInt:100000] forKey:@"$version"];
#if OLD
	propertyList = [NSMutableDictionary new];
	topLevelObjects = [NSMutableArray new];
	[propertyList setObject:topLevelObjects forKey:@"TopLevelObjects"];
	lastObjectRepresentation = propertyList;
	
	objects = NSCreateMapTable (NSNonRetainedObjectMapKeyCallBacks,
								NSObjectMapValueCallBacks, 119);
	conditionals = NSCreateHashTable (NSNonRetainedObjectHashCallBacks, 19);
	classes = NSCreateMapTable (NSObjectMapKeyCallBacks,
								NSObjectMapValueCallBacks, 19);
	[propertyList setObject:@"1" forKey:@"Version"];
#endif
		}
	return self;
}

- (void) dealloc
{
	[_aliasToClassMappings release];
#if OLD
	[propertyList release];
	[topLevelObjects release];
	NSFreeMapTable(objects);
	NSFreeHashTable(conditionals);
	NSFreeMapTable(classes);
#endif
	[_data release];
	[super dealloc];
}

#if OLD
- (NSString*) newLabel
{
//	return [NSString stringWithFormat:@"Object%5d", ++counter];
	return [NSString stringWithFormat:@"%d", ++counter];	// use simple numerical strings to save space
}

- (NSDictionary *) propertyList
{
	return propertyList;
}

- (BOOL) writeToFile:(NSString*)path
{
	return [propertyList writeToFile:path atomically:YES];
}

#endif

#if NEEDS_POLISHING

- (id) encodeRootObject:(id)rootObject forKey:(NSString*)name
{
	id originalPList = propertyList;
	int oldCounter = counter;
	id label;

	if (writingRoot)
		[NSException raise: NSInvalidArgumentException
        			 format: @"Coder has already written root object."];

	writingRoot = YES;

/*
	Prepare for writing the graph objects for which `rootObject' is the root
	node. The algorithm consists of two passes. In the first pass it
	determines the nodes so-called 'conditionals' - the nodes encoded *only*
	with -encodeConditionalObject:. They represent nodes that are not
	related directly to the graph. In the second pass objects are encoded
	normally, except for the conditional objects which are encoded as nil.
*/

	findingConditionals = YES;								// First pass.
	lastObjectRepresentation = propertyList = nil;
	NSResetHashTable(conditionals);
	NSResetMapTable(objects);
	[self encodeObject:rootObject forKey:name];

	findingConditionals = NO;								// Second pass.
	counter = oldCounter;
	lastObjectRepresentation = propertyList = originalPList;
	NSResetMapTable(objects);
	label = [self encodeObject:rootObject forKey:name];
	
	writingRoot = NO;
	
	return label;
}

//
// conditional objects are encoded only when they are encoded as standard objects at least once
// otherwise they are left out of the encoding and each reference is replaced by nil
//

- (id) encodeConditionalObject:(id)anObject forKey:(NSString*)name
{
	if(anObject)
		anObject = [anObject replacementObjectForModelArchiver:self];   // there might be an replacement object to encode
	if (findingConditionals) 
		{			// This is the first pass in determining the conditionals
     	id value;	// algorithm. We traverse the graph and insert into the
					// `conditionals' set. In the second pass all objects that 
					// are still in this set will be encoded as nil when they 
					// receive -encodeConditionalObject:. An object is removed 
					// from this set when it receives -encodeObject:.
		if (!anObject)
			return nil;
					// Lookup anObject into the `conditionals' set. If it is 
					// then the object is still a conditional object.
		if ((value = (id)NSHashGet(conditionals, anObject)))
			return value;
										// Maybe it has received -encodeObject:
										// and now is in the `objects' set.
		if ((value = (id)NSMapGet(objects, anObject)))
			return value;
										// anObject was not written previously.
		NSHashInsert(conditionals, anObject);
		}
	else								// If anObject is in the `conditionals'
		{								// set, it is encoded as nil.
		if (!anObject || NSHashGet(conditionals, anObject))
			return [self encodeObject:nil forKey:name];

		return [self encodeObject:anObject forKey:name];
		}

	return nil;
}

- (void) encodeDataObject:(NSData *) data;
{
	[self encodeObject:data forKey:@"NS.data"];
}

- (id) encodeObject:(id)anObject forKey:(NSString*)name
{ // name is nil for array and dictionary entries
	id upperObjectRepresentation;
	id label;
#if 0
	NSLog(@"encodeObject  <%08x>%@ withName %@", (unsigned) anObject, anObject, name);
#endif
	
	if (!anObject) 
		{ // nil object - explicitly save nil in second pass and not for array/dictionary entries
		if (!findingConditionals && name)
			[lastObjectRepresentation setObject:@"nil" forKey:name];
		return @"nil";
		}

	anObject = [anObject replacementObjectForModelArchiver:self];   // there might be an replacement object to encode

	label = NSMapGet(objects, anObject);	// get object label - if already known
    if (!label)
		{ // not yet known - encode or create a reference
		Class archiveClass;
		if (findingConditionals) 
			{				// Look-up the object in the `conditionals' set. 
							// If the object is there, then remove it because 
							// it is no longer a conditional one.
			if ((label = NSHashGet(conditionals, anObject))) 
				{
				NSHashRemove(conditionals, anObject);
				NSMapInsert(objects, anObject, [self newLabel]);	// don't encode (again) but store the reference
				return label;
				}
			}
		
		if (!level)						// If object gets encoded on the top
			{							// level, set the label to be `name'
			if (!name)
				{
				NSLog (@"Can't encode top level object with a nil name!");
				return nil;
				}
			label = name;
			}
		else
			label = [self newLabel];	// assign new name
#if 0
		NSLog(@"object %@ not yet known - new label %@", key, label);
#endif
		
		NSMapInsert(objects, anObject, label);  // remember in the object map so that it does not get encoded twice
						// Temp save last object into upperObjectRepresentation 
						// so we can restore the stack of objects being encoded 
						// after anObject is encoded.
		upperObjectRepresentation = lastObjectRepresentation;

		archiveClass = [anObject classForModelArchiver];

		if (!findingConditionals)
			{ // fresh object - encode
			NSMutableDictionary *objectPList =[NSMutableDictionary dictionary];

							// If anObject is the first object in graph that
							// receives the -encodeObject:ForKey: message, 
			if (!level)		// save its label into the topLevelObjects array.
				[topLevelObjects addObject:(name ? name : label)];

			lastObjectRepresentation = objectPList; // store encoding here

			if (level)		// Encode 'name = label' in object's representation
				{			// and put the description of anObject on the top 
							// level like 'label = object'.
				if (name)
					[upperObjectRepresentation setObject:label forKey:name];
				[propertyList setObject:objectPList forKey:label];
				}
			else			// encoded object is on the top level so encode it
				{			// and put it under the key 'name'.
				if (name)
					label = name;
				[propertyList setObject:objectPList forKey:label];
				}

			[objectPList setObject:NSStringFromClass(archiveClass) 
						 forKey:@"isa"];		// encode class string
			}									// First pass in determining
		else									// conditional objs algorithm.
			NSHashRemove(conditionals,anObject);// Remove anObject from 
												// `conditionals' set if it is 
												// there and insert it into the 
		level++;								//`objects' set.
		[anObject encodeWithModelArchiver:self];	// now encode the object
		level--;

		lastObjectRepresentation = upperObjectRepresentation;
		}
	else
		{
#if 0
		NSLog(@"object %@ already known as %@", key, label);
#endif
		if (!findingConditionals && (name))
			[lastObjectRepresentation setObject:label forKey:name]; // store reference
		}
	return label;
}

- (id) encodeString:(NSString*)anObject forKey:(NSString*)name
{
	if (!findingConditionals)
		{
		if (!anObject)
			{
			if (name)
				[lastObjectRepresentation setObject:@"nil" forKey:name];
			}
		else
			{
			if (name)
				[lastObjectRepresentation setObject:anObject forKey:name];

			return anObject;
			}
		}

	return @"nil";
}

- (id) encodeData:(NSData*)anObject forKey:(NSString*)name
{
	if (!findingConditionals)
		{
		if (!anObject)
			{
			if (name)
				[lastObjectRepresentation setObject:@"nil" forKey:name];
			}
		else
			{
			if (name)
				[lastObjectRepresentation setObject:anObject forKey:name];

			return anObject;
		}	}

	return @"nil";
}

- (id) encodeArray:(NSArray*)array forKey:(NSString*)name
{
	if (array) 
		{
		int i, count = [array count];
		NSMutableArray *description = [NSMutableArray arrayWithCapacity:count];

		for (i = 0; i < count; i++) 
			{
			id object = [array objectAtIndex:i];
			[description addObject:[self encodeObject:object forKey:nil]];
			}

		if (name)
			[lastObjectRepresentation setObject:description forKey:name];

		return description;
		}

	if (name)
		[lastObjectRepresentation setObject:@"nil" forKey:name];

	return @"nil";
}

- (id) encodeDictionary:(NSDictionary*)dictionary forKey:(NSString*)name
{
	if (dictionary)
		{
		NSMutableDictionary *description = [NSMutableDictionary 
								dictionaryWithCapacity:[dictionary count]];
		id key, enumerator = [dictionary keyEnumerator];

		while ((key = [enumerator nextObject]))
			{
			id value = [dictionary objectForKey:key];
			id keyDesc = [self encodeObject:key forKey:nil];
			id valueDesc = [self encodeObject:value forKey:nil];

			[description setObject:valueDesc forKey:keyDesc];
			}

		if (name)
			[lastObjectRepresentation setObject:description forKey:name];

		return description;
		}

	if (name)
		[lastObjectRepresentation setObject:@"nil" forKey:name];

	return @"nil";
}

- (id) encodeClass:(Class)class forKey:(NSString*)name
{
	if (class)
		return [self encodeString:NSStringFromClass(class) forKey:name];

	return [self encodeString:nil forKey:name];
}

- (id) encodeSelector:(SEL)selector forKey:(NSString*)name
{
	if (selector)
	   return [self encodeString:NSStringFromSelector(selector) forKey:name];

	return [self encodeString:nil forKey:name];
}

- (void) encodeChar:(char)value forKey:(NSString*)name
{
	if (!findingConditionals && name)
		{
		id valueString = [NSString stringWithFormat:@"%c", value];

		[lastObjectRepresentation setObject:valueString forKey:name];
		}
}

- (void) encodeUnsignedChar:(unsigned char)value forKey:(NSString*)name
{
	if (!findingConditionals && name)
		{
		id valueString = [NSString stringWithFormat:@"%uc", value];

		[lastObjectRepresentation setObject:valueString forKey:name];
		}
}

- (void) encodeBOOL:(BOOL)value forKey:(NSString*)name
{
	if (!findingConditionals && name)
		[lastObjectRepresentation setObject:(value ? @"YES": @"NO") 
								  forKey:name];
}

- (void) encodeShort:(short)value forKey:(NSString*)name
{
	if (!findingConditionals && name)
		{
		id valueString = [NSString stringWithFormat:@"%s", value];

		[lastObjectRepresentation setObject:valueString forKey:name];
		}
}

- (void) encodeUnsignedShort:(unsigned short)value forKey:(NSString*)name
{
	if (!findingConditionals && name)
		{
		id valueString = [NSString stringWithFormat:@"%us", value];

		[lastObjectRepresentation setObject:valueString forKey:name];
		}
}

- (void) encodeInt:(int)value forKey:(NSString*)name
{
	if (!findingConditionals && name)
		{
		id valueString = [NSString stringWithFormat:@"%i", value];

		[lastObjectRepresentation setObject:valueString forKey:name];
		}
}

- (void) encodeUnsignedInt:(unsigned int)value forKey:(NSString*)name
{
	if (!findingConditionals && name)
		{
		id valueString = [NSString stringWithFormat:@"%u", value];

		[lastObjectRepresentation setObject:valueString forKey:name];
		}
}

- (void) encodeLong:(long)value forKey:(NSString*)name
{
	if (!findingConditionals && name)
		{
		id valueString = [NSString stringWithFormat:@"%l", value];

		[lastObjectRepresentation setObject:valueString forKey:name];
		}
}

- (void) encodeUnsignedLong:(unsigned long)value forKey:(NSString*)name
{
	if (!findingConditionals && name)
		{
		id valueString = [NSString stringWithFormat:@"%lu", value];

		[lastObjectRepresentation setObject:valueString forKey:name];
		}
}

- (void) encodeFloat:(float)value forKey:(NSString*)name
{
	if (!findingConditionals && name)
		{
		id valueString = [NSString stringWithFormat:@"%f", value];

		[lastObjectRepresentation setObject:valueString forKey:name];
		}
}

- (void) encodeDouble:(double)value forKey:(NSString*)name
{
	if (!findingConditionals && name)
		{
		id valueString = [NSString stringWithFormat:@"%f", value];

		[lastObjectRepresentation setObject:valueString forKey:name];
		}
}

- (void) encodePoint:(NSPoint)point forKey:(NSString*)name
{
	if (!findingConditionals && name)
		[lastObjectRepresentation setObject:[NSString stringWithFormat:@"{x=\"%f\"; y=\"%f\"}", 
			point.x, point.y] forKey:name]; // don't use NSStringFromPoint() here because it might be different on MacOS X for nib2mib
}

- (void) encodeSize:(NSSize)size forKey:(NSString*)name
{
	if (!findingConditionals && name)
		[lastObjectRepresentation setObject:[NSString stringWithFormat:@"{width=\"%f\"; height=\"%f\"}",
			size.width, size.height] forKey:name];
}

- (void) encodeRect:(NSRect)rect forKey:(NSString*)name
{
	if (!findingConditionals && name) 
		[lastObjectRepresentation setObject:[NSString stringWithFormat:
			@"{x=\"%f\"; y=\"%f\"; width=\"%f\"; height=\"%f\"}",
			NSMinX(rect), NSMinY(rect), 
			NSWidth(rect), NSHeight(rect)] forKey:name];
}

- (NSString*) classNameEncodedForTrueClassName:(NSString*)trueName
{
id archiveName = [(id)NSMapGet(classes, trueName) className];

	return archiveName ? archiveName : trueName;
}
			// In the following method the version of class named trueName is 
			// written as version for class named archiveName. Is this right? 
			// It is possible for the archiveName class that it could not be 
			// linked in the running process at the time the archive is written
- (void) encodeClassName:(NSString*)trueName
		   intoClassName:(NSString*)archiveName
{
id classInfo = [GMClassInfo classInfoWithClassName:archiveName
							version:[NSClassFromString(trueName) version]];

	NSMapInsert(classes, trueName, classInfo);
}

#endif // NEEDS_POLISHING

@end /* NSKeyedArchiver */

@interface NSObject (_NSNibLoadingSupportInFoundation)
- (id) nibInstantiate;	// swapper objects must support this to instantiate/return the real object
@end

@implementation NSKeyedUnarchiver

+ (void) initialize
{
	_globalUnarchiverClassToAliasMappings = [NSMutableDictionary new];
}

+ (Class) classForClassName:(NSString *)codedName;
{
	return [_globalUnarchiverClassToAliasMappings objectForKey:codedName];
}

+ (void) setClass:(Class)cls forClassName:(NSString *)codedName;
{
	if(cls)
		[_globalUnarchiverClassToAliasMappings setObject:cls forKey:codedName];
	else
		[_globalUnarchiverClassToAliasMappings removeObjectForKey:codedName];
}

+ (id) unarchiveObjectWithFile:(NSString *)path
{
#if 0
	NSLog(@"NSKeyedUnarchiver unarchiveObjectWithFile:%@", path);
#endif
	return [self unarchiveObjectWithData:[NSData dataWithContentsOfFile:path]];
}

+ (id) unarchiveObjectWithData:(NSData *)data
{
	NSKeyedUnarchiver *u=[[self alloc] initForReadingWithData:data];
	id root=[u decodeObjectForKey:@"$top"];
	[u finishDecoding];
	[u release];
	return root;
}

- (id) _initForReadingWithPropertyList:(NSDictionary *)plist
{
	if((self=[super init]))
		{
		if(!plist || ![[plist objectForKey:@"$archiver"] isEqualToString:@"NSKeyedArchiver"] || [[plist objectForKey:@"$version"] intValue] < 100000)
			{
#if 0
			// FIXME: should we raise exception?
			NSLog(@"can't unarchive keyed plist %@", plist);
			NSLog(@"$archiver %@", [plist objectForKey:@"$archiver"]);
			NSLog(@"$version %@", [plist objectForKey:@"$version"]);
#endif
			[self release];
			return nil;
			}
		_objects=[[plist objectForKey:@"$objects"] retain];				// array with all objects (or references)
		_objectRepresentation=[[plist objectForKey:@"$top"] retain];	// prepare to read out $top object
#if 0
		NSLog(@"$archiver %@", [plist objectForKey:@"$archiver"]);
		NSLog(@"$version %@", [plist objectForKey:@"$version"]);
		NSLog(@"$version %@", [plist objectForKey:@"$top"]);
#endif
		}
	return self;
}

- (id) initForReadingWithData:(NSData *) data;
{
	NSString *err;	// ignored
	NSPropertyListFormat fmt;
	NSAutoreleasePool *arp;
	id plist;
#if 0
	NSLog(@"NSKeyedUnarchiver initForReadingWithData %p[%d]", data, [data length]);
#endif
	if(!data)
		return nil; // can't open
	fmt=NSPropertyListBinaryFormat_v1_0;
	// NOTE: from stack traces we know that Apple's Foundation is directly decoding from a binary PLIST through _decodeObject and _decodeObjectBinary methods
	arp=[NSAutoreleasePool new];
	plist=[NSPropertyListSerialization propertyListFromData:data
										   mutabilityOption:NSPropertyListMutableContainers
													 format:&fmt
										   errorDescription:&err];
	[plist retain];	// save
#if 0
	NSLog(@"NSKeyedUnarchiver plist decoded");
#endif
	[arp release];	// throw away all no longer needed temporaries
	return [self _initForReadingWithPropertyList:[plist autorelease]];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ currentObject=%@", NSStringFromClass([self class]), _objectRepresentation];
}

- (void) dealloc;
{
	[_objectRepresentation release];
	[_objects release];
	[_classToAliasMappings release];
	// release local ARP
	[super dealloc];
}

- (BOOL) allowsKeyedCoding; { return YES; }

- (BOOL) containsValueForKey:(NSString *)key;
{
	return [_objectRepresentation objectForKey:key] != nil;	// if defined
}

- (id) delegate; { return _delegate; }

- (void) setDelegate:(id) delegate { _delegate=delegate; }

- (Class) classForClassName:(NSString *)codedName;
{
	return [_classToAliasMappings objectForKey:codedName];
}

- (void) setClass:(Class)cls forClassName:(NSString *)codedName;
{
	if(cls)
		{
		if(!_classToAliasMappings)
			_classToAliasMappings = [NSMutableDictionary new];
		[_classToAliasMappings setObject:cls forKey:codedName];
		}
	else
		[_classToAliasMappings removeObjectForKey:codedName];
}

/* excerpt of the $objects array

<string>System</string>
<string>controlColor</string>
<dict>
	<key>$class</key>
	<dict>	<- if decodeObjectForKey is a NSDict which itself has a CF$UID key
		<key>CF$UID</key>
		<integer>98</integer>
	</dict>
	<key>NSColorSpace</key>
		<integer>3</integer>	<- decodeObjectForKey is a plain object
	<key>NSWhite</key>
		<data>
MC42NjY2NjY2OQA=
		</data>
</dict>
<dict>
	<key>$classes</key>
		<array>
		<string>NSMatrix</string>
		<string>%NSMatrix</string>
		<string>NSControl</string>
		<string>NSView</string>
		<string>NSResponder</string>
		<string>NSObject</string>
		</array>
	<key>$classname</key>
		<string>NSMatrix</string>
</dict>
etc.
*/

- (id) _dereference:(unsigned int) idx
{ // handle indirect references through NSCFType/CF$UID - cache so that each object is instantiated only once
//	NSAutoreleasePool *arp;
	id obj, newObj;
	NSDictionary *savedRepresentation;
#if KEY_CHECK
	NSMutableArray *savedProcessedKeys;
#endif
	NSDictionary *classRecord;
	NSString *className;
	Class class;
	newObj=[_objects objectAtIndex:idx];	// get real object by number
	if([newObj isEqual:@"$null"])
		return nil;
#if 0
	NSLog(@"dereference objects[%u]=%@", idx, newObj);
#endif
	if(!([newObj isKindOfClass:[NSDictionary class]] && [(NSDictionary *) newObj objectForKey:@"$class"]))
		{
		if([newObj respondsToSelector:@selector(nibInstantiate)])
			{ // needs to return the replacement object
#if 0
			NSLog(@"object %u already stored:%@", idx, newObj);
			NSLog(@" nibInstantiate=%@", [newObj nibInstantiate]);
			// exit(1);
#endif
			return [newObj nibInstantiate];
			}
		return newObj; // has already been decoded and is not an instance representation record
		}
//	arp=[NSAutoreleasePool new];
	savedRepresentation=_objectRepresentation;	// save
	_objectRepresentation=newObj;	// switch over to representation record
	[_objectRepresentation retain];	// we still need it but will replace the description record in the _objects array by the allocated object
#if KEY_CHECK
	savedProcessedKeys=_unprocessedKeys;
	_unprocessedKeys=[[_objectRepresentation allKeys] mutableCopy];	// make a copy so that we can remove entries
#endif
	_sequentialKey=0;	// start over with $1, $2, ... for -decodeObject
	classRecord=[self decodeObjectForKey:@"$class"];	// may itself be a CFType!
	className=[classRecord objectForKey:@"$classname"];	// but should finally be a plain NSDictionary
#if 0
	NSLog(@"className=%@", className);
#endif
	class=[[self class] classForClassName:className];	// apply global translation table
	if(!class)
		class=[self classForClassName:className];	// apply local translation table
	if(!class)
		class=NSClassFromString(className);		// translate by loaded frameworks
	if(!class && [_delegate respondsToSelector:@selector(unarchiver:cannotDecodeObjectOfClassName:originalClasses:)])
		class=[_delegate unarchiver:self cannotDecodeObjectOfClassName:className originalClasses:[classRecord objectForKey:@"$classes"]];
	if(!class)
		[NSException raise:NSInvalidUnarchiveOperationException format:@"Can't unarchive object for class %@", className];
	obj=[class allocWithZone:[self zone]];					// allocate a fresh object
	[_objects replaceObjectAtIndex:idx withObject:obj];		// store a first reference to avoid endless recursion for self-references (note: this will [newObj release]!)
	newObj=[[obj initWithCoder:self] autorelease];			// initialize and decode (which might recursively ask to decode a reference to the current object, e.g. if an object is its own next responder or delegate!)
	if(newObj)
		{
		if(newObj != obj)
			[_objects replaceObjectAtIndex:idx withObject:newObj];	// store again, since it has been substituted
		if([_delegate respondsToSelector:@selector(unarchiver:didDecodeObject:)])
			newObj=[_delegate unarchiver:self didDecodeObject:newObj];
		if(newObj != obj && [_delegate respondsToSelector:@selector(unarchiver:willReplaceObject:withObject:)])
			[_delegate unarchiver:self willReplaceObject:obj withObject:newObj];	// has been changed between original call to initWithCoder
		}
#if KEY_CHECK
	if([_unprocessedKeys count] != 0)
		{
		NSLog(@"%@: does not decode these keys: %@ in %@", NSStringFromClass(class), _unprocessedKeys, _objectRepresentation);
		}
	[_unprocessedKeys release];
	_unprocessedKeys=savedProcessedKeys;
#endif
	[_objectRepresentation release];
	_objectRepresentation=savedRepresentation;	// restore
	[newObj retain];	// rescue over arp release
//	[arp release];
#if 0
	NSLog(@"obj=%p", newObj);
#endif
	return [newObj autorelease];
}

- (id) _decodeObjectForRepresentation:(id) obj
{
	id uid;
#if 0
	NSLog(@"decodeObjectForRepresentation %@", obj);
#endif
	if([obj isKindOfClass:[NSCFType class]])
		return [self _dereference:[obj uid]];	// indirect
	if([obj isKindOfClass:[NSArray class]])
		{ // dereference array
		int i, cnt=[obj count];
#if 0
		NSLog(@"decode %u NSArray components for %@", cnt, obj);
#endif
		for(i=0; i<cnt; i++)
			{
#if 0
			id rep=[_objects objectAtIndex:[[obj objectAtIndex:i] uid]];
#endif
			id n;
			n=[self _decodeObjectForRepresentation:[obj objectAtIndex:i]];
#if 0
			if([n isKindOfClass:NSClassFromString(@"NSClassSwapper")])
				{
				NSLog(@"did return class swapper object and not real object: %@", [obj objectAtIndex:i]);
				NSLog(@"  uid=%u", [[obj objectAtIndex:i] uid]);
				NSLog(@"  rep=%@", rep);
				NSLog(@"  obj=%@", n);
				exit(1);
				}
#endif
			if(!n)
				n=[NSNull null];	// replace by NSNull if we could not initialize
			if(![obj isKindOfClass:[NSMutableArray class]])
				obj=[[obj mutableCopy] autorelease];	// not yet mutable - force array to be mutable
			[obj replaceObjectAtIndex:i withObject:n];	// replace by dereferenced object
			}
		return obj;
		}
	if([obj isKindOfClass:[NSDictionary class]])
		{
		if((uid=[(NSDictionary *) obj objectForKey:@"CF$UID"]))
			{
#if 0
			NSLog(@"CF$UID = %@", uid);
#endif
			return [self _dereference:[uid intValue]];
			}
		// shouldn't we dereference dictionary components?
		}
	return obj;	// as is
}

- (id) decodeObjectForKey:(NSString*) name
{ // handle all special cases
	id obj=[_objectRepresentation objectForKey:name];
#if KEY_CHECK
#if 0
	if(!obj)
		{
		NSLog(@"does not contain key: %@ (%@)", name, obj);
		return nil;
		}
#endif
	[_unprocessedKeys removeObject:name];
#endif
	return [self _decodeObjectForRepresentation:obj];
}

- (id) decodeObject;
{
	return [self decodeObjectForKey:[NSString stringWithFormat:@"$%d", ++_sequentialKey]];
}

- (id) decodeDataObject;
{
	return [self decodeObjectForKey:@"NS.data"];
}

- (BOOL) decodeBoolForKey:(NSString *)key;
{
	id obj=[self decodeObjectForKey:key];
#if 0
	NSLog(@"boolForKey: %@ = %@", key, obj);
#endif
	if(!obj) return NO;	// default
	if(![obj isKindOfClass:[NSNumber class]])
		[NSException raise:NSInvalidUnarchiveOperationException format:@"Can't unarchive object for key %@ as BOOL (obj=%@)", key, obj];
#if 0
	NSLog(@"  -> %@", [obj boolValue]?@"YES":@"NO");
#endif
	return [obj boolValue];
}

- (const unsigned char *) decodeBytesForKey:(NSString *)key
							 returnedLength:(NSUInteger *)lengthp;
{
	id obj=[self decodeObjectForKey:key];
#if 0
	NSLog(@"decodeBytesForKey %@ -> %@ [%@] %@", key, obj, NSStringFromClass([obj class]), self);
#endif
	if(!obj)
		{ // no data
		*lengthp=0;
		return NULL;
		}
	if(![obj isKindOfClass:[NSData class]])
		[NSException raise:NSInvalidUnarchiveOperationException format:@"Can't unarchive object for key %@ as bytes (obj=%@)", key, obj];
	if(lengthp)
		*lengthp=[obj length];
#if 0
	NSLog(@"length=%d bytes=%p", [obj length], [obj bytes]);
#endif
	return [obj bytes];
}

- (double) decodeDoubleForKey:(NSString *)key;
{
	id obj=[self decodeObjectForKey:key];
	if(!obj) return 0.0;	// default
	if(![obj isKindOfClass:[NSNumber class]])
		[NSException raise:NSInvalidUnarchiveOperationException format:@"Can't unarchive object for key %@ as double (obj=%@)", key, obj];
	return [obj doubleValue];
}

- (float) decodeFloatForKey:(NSString *)key;
{
	id obj=[self decodeObjectForKey:key];
	if(!obj) return 0.0;	// default
	if(![obj isKindOfClass:[NSNumber class]])
		[NSException raise:NSInvalidUnarchiveOperationException format:@"Can't unarchive object for key %@ as float (obj=%@)", key, obj];
	return [obj floatValue];
}

- (int) decodeInt32ForKey:(NSString *)key;
{
	id obj=[self decodeObjectForKey:key];
	if(!obj) return 0;	// default
	if(![obj isKindOfClass:[NSNumber class]])
		[NSException raise:NSInvalidUnarchiveOperationException format:@"Can't unarchive object for key %@ as int32 (obj=%@)", key, obj];
	return [obj longValue];
}

- (long long) decodeInt64ForKey:(NSString *)key;
{
	id obj=[self decodeObjectForKey:key];
	if(!obj) return 0;	// default
	if(![obj isKindOfClass:[NSNumber class]])
		[NSException raise:NSInvalidUnarchiveOperationException format:@"Can't unarchive object for key %@ as int64 (obj=%@)", key, obj];
	return [obj longLongValue];
}

- (int) decodeIntForKey:(NSString *)key;
{
	id obj=[self decodeObjectForKey:key];
	if(!obj) return 0;	// default
	if(![obj isKindOfClass:[NSNumber class]])
		[NSException raise:NSInvalidUnarchiveOperationException format:@"Can't unarchive object for key %@ as int (obj=%@)", key, obj];
	return [obj intValue];
}

- (NSPoint) decodePointForKey:(NSString *)key;
{
	id obj=[self decodeObjectForKey:key];
	if(!obj) return NSZeroPoint;	// default
	if([obj isKindOfClass:[NSString class]])
		return NSPointFromString(obj);
	if(![obj isKindOfClass:[NSValue class]])
		[NSException raise:NSInvalidUnarchiveOperationException format:@"Can't unarchive object for key %@ as NSPoint (obj=%@)", key, obj];
	return [obj pointValue];
}

- (NSRect) decodeRectForKey:(NSString *)key;
{
	id obj=[self decodeObjectForKey:key];
	if(!obj) return NSZeroRect;	// default
	if([obj isKindOfClass:[NSString class]])
		{
#if 0
		NSRect r=NSRectFromString(obj);
		NSLog(@"decodeRectForKey: %@ -> NSString %@", key, obj);
		NSLog(@"string from rect: %@", NSStringFromRect(r));
#endif
		return NSRectFromString(obj);
		}
	if(![obj isKindOfClass:[NSValue class]])
		[NSException raise:NSInvalidUnarchiveOperationException format:@"Can't unarchive object for key %@ as NSRect (obj=%@)", key, obj];
	return [obj rectValue];
}

- (NSSize) decodeSizeForKey:(NSString *)key;
{
	id obj=[self decodeObjectForKey:key];
	if(!obj) return NSZeroSize;	// default
	if([obj isKindOfClass:[NSString class]])
		return NSSizeFromString(obj);
	if(![obj isKindOfClass:[NSValue class]])
		[NSException raise:NSInvalidUnarchiveOperationException format:@"Can't unarchive object for key %@ as NSSize (obj=%@)", key, obj];
	return [obj sizeValue];
}

- (void) finishDecoding;
{
#if 0
	NSLog(@"NSKeyedUnarchiver finishDecoding");
#endif
	if(_delegate && [_delegate respondsToSelector:@selector(unarchiverWillFinish:)])
		[_delegate unarchiverWillFinish:self];
	[_objectRepresentation release];
	_objectRepresentation=nil;
	[_objects release];
	_objects=nil;
	if(_delegate && [_delegate respondsToSelector:@selector(unarchiverDidFinish:)])
		[_delegate unarchiverDidFinish:self];
	// release local ARP
}

- (unsigned int) systemVersion			{ return 1; }

- (NSInteger) versionForClassName:(NSString*)className
{
	return 1;
}

#if 0
- (void) decodeValueOfObjCType:(const char*)type at:(void*)address;
{
	NSLog(@"!!! NSKeyedUnarchiver decodeValueOfObjCType: %s for %@", type, self);
}
#endif

@end /* NSKeyedArchiver */
