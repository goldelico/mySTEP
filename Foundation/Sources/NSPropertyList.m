//
//  NSPropertyList.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Jul 14 2003.
//  Copyright (c) 2003 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import "Foundation/NSPropertyList.h"
#import "Foundation/NSXMLParser.h"
#import "Foundation/NSValue.h"
#import "NSPrivate.h"

// make these classes known (should probably be part of NSPrivate.h)
@interface GSFloatNumber : NSNumber
@end
@interface GSDoubleNumber : NSNumber
@end
@interface GSBoolNumber : NSNumber
@end

// this can be used as a delegate to NSXMLParser

@interface _NSXMLPropertyList : NSObject
{
	NSMutableString *currentValue;	// current value string
	NSMutableDictionary *dict;	// if we represent a <dict>
	NSString *key;	// key for next setValue
	NSMutableArray *array;	// if we represent a <array>
	id plist;	// result object
	_NSXMLPropertyList *parent;
	NSPropertyListMutabilityOptions isMutable;
}

- (id) objectValue;
- (void) setKey:(NSString *) key;
- (void) setValue:(id) o;
- (void) setMutabilityOption:(NSPropertyListMutabilityOptions) flag;
- (id) initWithType:(NSString *) elementName withMutabilityOption:(NSPropertyListMutabilityOptions) flag andParent:(_NSXMLPropertyList *) p;
- (void) parser:(NSXMLParser *) parser foundCharacters:(NSString *) string;
- (void) parser:(NSXMLParser *) parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict;
- (void) parser:(NSXMLParser *) parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;

@end

@implementation _NSXMLPropertyList

- (id) objectValue; { return plist; }

- (void) setKey:(NSString *) k;
{
#if 0
	NSLog(@"setKey=%@", k);
#endif
	if(!dict || key)
		{
		NSLog(@"missing <dict> for <key> or duplicate <key>: dict=%@ key=%@", dict, key); // error
		[key release];	// previous
		}
	key=[k retain];
}

- (void) setValue:(id) o;
{
#if 0
	NSLog(@"setValue=%@ forKey: %@ (dict=%@, array=%@)", o, key, dict, array);
#endif
	if(dict)
		{
		if(!key)
			NSLog(@"missing <key> for <dict>");	// error
		else
			[dict setObject:o forKey:key];	// insert into parent dictionary
		[key release];	// has been used
		key=nil;
		}
	else if(array)
		[array addObject:o];	// append to parent array
	else
		plist=o;	// top-level node; not retained!
}

- (void) setMutabilityOption:(NSPropertyListMutabilityOptions) flag; { isMutable=flag; }

- (id) initWithType:(NSString *) elementName withMutabilityOption:(NSPropertyListMutabilityOptions) flag andParent:(_NSXMLPropertyList *) p;
{
	self=[super init];
#if 0
	NSLog(@"initWithType:%@", elementName);
#endif
	if(self)
		{
		parent=p;	// save link
		isMutable=flag;  // handle MutableContainers/Leaves
		if([elementName isEqualToString:@"dict"])
			dict=[[NSMutableDictionary alloc] initWithCapacity:10];
		else if([elementName isEqualToString:@"array"])
			array=[[NSMutableArray alloc] initWithCapacity:10];
		}
	return self;
}

- (void) dealloc
{
	[dict release];
	[array release];
	[super dealloc];
}

- (void) parser:(NSXMLParser *) parser foundCharacters:(NSString *) string
{
	if (!currentValue)
		currentValue = [[NSMutableString alloc] initWithCapacity:50];
	[currentValue appendString:string];    
}

- (void) parser:(NSXMLParser *) parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
#if 0
	NSLog(@"didStartElement: %@ <%@ %@>", currentValue, elementName, attributeDict);
#endif
//	if(isLeaf)
//		;	// nesting error
    if([elementName isEqualToString:@"plist"] ||
	   [elementName isEqualToString:@"dict"] ||
	   [elementName isEqualToString:@"array"])
		{ // nested elements
		_NSXMLPropertyList *subelement;
		// can we check here for nesting error, e.g. <string> xxx <dict> yyy </dict> zzz </string> ???
		subelement=[[[_NSXMLPropertyList alloc] initWithType:elementName
										   withMutabilityOption:isMutable
													  andParent:self] autorelease];
		// should we not release here but in didEndElement?
		[parser setDelegate:subelement];
		}
	else
		{ // leaf elements
		// isLeaf=YES;
		// could check for other valid entries
		// but NSXMLParser already checks nesting
		}
 	[currentValue release];  
 	currentValue=nil;
}

- (void) parser:(NSXMLParser *) parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
#if 0
	NSLog(@"didEndElement: %@ </%@>", currentValue, elementName);
#endif
	// nested elements
	if([elementName isEqualToString:@"dict"])
		{
		[parent setValue:dict];		// pass up to parent
		[parser setDelegate:parent];
		}
	else if([elementName isEqualToString:@"array"])
		{
		[parent setValue:array];	// pass up to parent
		[parser setDelegate:parent];
		}
	else if([elementName isEqualToString:@"plist"])
		{
		[parent setValue:plist];	// pass up root object
		[parser setDelegate:parent];
		}
	// leaf elements
	else if([elementName isEqualToString:@"key"])
// FIXME: handle currentValue == nil
		[self setKey:currentValue];	// pass key to parent
	else if([elementName isEqualToString:@"data"])
		{
		NSData *d=[[NSData alloc] _initWithBase64String:currentValue?(NSString *) currentValue:@""];
		if(!d)
			{
#if 0
			NSLog(@"invalid base64 data for <%@>", elementName);
#endif
			[parser abortParsing];
			return;
			}
		[self setValue:d];
		[d release];
		}
	else if([elementName isEqualToString:@"date"])
		{
		// FIXME: decode date
		NSLog(@"<DATE>%@", currentValue);
		[self setValue:currentValue];
		}
	else if([elementName isEqualToString:@"string"])
		[self setValue:currentValue?(id)currentValue:(id)@""];
	else if([elementName isEqualToString:@"integer"])
		[self setValue:[NSNumber numberWithInt:[currentValue intValue]]];
	else if([elementName isEqualToString:@"real"])
		{
		double val=[currentValue doubleValue];
		NSNumber *num=[NSNumber numberWithDouble:val];
		[self setValue:num];
#if 0
		NSLog(@"<real> %@", currentValue);
		NSLog(@"-> %lf", val);
		NSLog(@"-> %@", num);
#endif
		}
	else if([elementName isEqualToString:@"true"])
		[self setValue:[NSNumber numberWithBool:YES]];
	else if([elementName isEqualToString:@"false"])
		[self setValue:[NSNumber numberWithBool:NO]];
	else // invalid tag
		{
#if 1
		NSLog(@"unrecognized tag <%@>", elementName);
#endif
		[currentValue release];  
		currentValue=nil;
		[parser abortParsing];
		return;
		}
	// isLeaf=NO;
 	[currentValue release];  
 	currentValue=nil;
}

@end

@interface NSScanner (NSPropertyList)
- (void) propertyListSkipSpace;
- (void) propertyListSkipSpaceAndComments;
- (NSString *) propertyListScanQuotedString;
- (NSString *) propertyListScanUnquotedString;
- (id) propertyListScanPropertyListDictionary:(NSPropertyListMutabilityOptions) opt errorDescription:(NSString **) err withBrace:(BOOL) flag;
- (id) propertyListScanPropertyListElement:(NSPropertyListMutabilityOptions) opt errorDescription:(NSString **) err;
- (id) propertyListScanJSONElement:(NSPropertyListMutabilityOptions) opt errorDescription:(NSString **) err;
@end

@implementation NSScanner (NSPropertyList)

static NSCharacterSet *spaces;		// @" \t\n\r"
static NSCharacterSet *unquoted;	// @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz$./_"

- (void) propertyListSkipSpace;
{ // skip whitespace and newlines
	if(!spaces)
		spaces=[[NSCharacterSet characterSetWithCharactersInString:@" \t\r"] retain];
	while(YES)
		{
		//	NS_TIME_START(VAR);
		[self scanCharactersFromSet:spaces intoString:NULL];
		//	NS_TIME_END(VAR, "propertyListSkipSpace 1");	// ca. 1-2 �s
		if([self scanString:@"\n" intoString:NULL])
			{
			// line++;	// count line numbers
			continue;
			}
		return;
		}
}

- (void) propertyListSkipSpaceAndComments;
{ // skip space and C and C++ style comments
	while(YES)
		{
		[self propertyListSkipSpace];
		if([self scanString:@"//" intoString:NULL])
			{ // C++ style comment
				[self scanUpToString:@"\n" intoString:NULL];	// ignore until end of line
				continue;
			}
		if([self scanString:@"/*" intoString:NULL])
			{ // C style comment
				[self scanUpToString:@"*/" intoString:NULL];	// ignore until closing */
				[self scanString:@"*/" intoString:NULL];	// eat */
				continue;
			}
		return;
		}
}

- (NSString *) propertyListScanQuotedString;
{ // first quote aready absorbed - scan until second quote; handle \n etc. - return nil on unexpected isAtEnd
	NSMutableString *str=[NSMutableString stringWithCapacity:10];
	static NSCharacterSet *stopChars;
#if 0
	NSLog(@"propertyListScanQuotedString");
#endif
	if(!stopChars)
		stopChars=[[NSCharacterSet characterSetWithCharactersInString:@"\\\""] retain];	// backslash for escape or ending quote
	while(![self isAtEnd])
		{
		NSString *chunk;
		int val;
		if(![self scanUpToCharactersFromSet:stopChars intoString:&chunk])	// until closing quote or intermediate backslash
			chunk=@"";
		[str appendString:chunk];	// splice together
		if([self scanString:@"\"" intoString:NULL])
			return str;	// end of string
		[self scanString:@"\\" intoString:NULL];	// must be the backslash
		if([self scanString:@"U" intoString:NULL])
			{ // hex Unicode
			unichar chr=0x00a4;
				// FIXME:
			[str appendFormat:@"%C", chr];	// splice together
			}
		else if([self scanString:@"0" intoString:NULL])
			{ // octal
			  // FIXME:
			}
		else if([self scanString:@"\n" intoString:NULL])
			{ // \ + newline
			continue;	// ignore (i.e. continuation line)
			}
		else if([self scanString:@"n" intoString:NULL])
			{ // \n
			[str appendString:@"\n"];
			}
		else if([self scanString:@"r" intoString:NULL])
			{ // \r
			[str appendString:@"\r"];
			}
		// more escape characters...
		else if([self scanString:@"\\" intoString:NULL])
			{ // escaped backslash
				[str appendString:@"\\"];
			}
		else if([self scanInt:&val])
			{ // \ddd
			[str appendFormat:@"%c", val];	// splice together
			}
		}
	return nil;	// unterminated!
}

- (NSString *) propertyListScanUnquotedString;
{ // scan unquoted string meaning all characters not requiring being quoted
	NSString *str;
	if(!unquoted)
		unquoted=[[[NSCharacterSet characterSetWithCharactersInString:@",;={}()[] \"\n"] invertedSet] retain];
#if 0
	NSLog(@"propertyListScanUnquotedString");
#endif
	if([self scanCharactersFromSet:unquoted intoString:&str])
		return str;	// at least one
	return @"";		// empty!
}

- (id) propertyListScanPropertyListDictionary:(NSPropertyListMutabilityOptions) opt errorDescription:(NSString **) err withBrace:(BOOL) flag;
{
	id key, val;
	NSMutableDictionary *d=[NSMutableDictionary dictionaryWithCapacity:10];
#if 0
	NSLog(@"propertyListScanPropertyListDictionary withBrace:%d", flag);
#endif
	while(![self isAtEnd])
		{
		[self propertyListSkipSpaceAndComments];
		if(flag && [self scanString:@"}" intoString:NULL])
			break;  // { }
		key=[self propertyListScanPropertyListElement:opt errorDescription:err];
		if(!key)
			{
#if 1
			NSLog(@"nil key %@", *err);
#endif
			return nil;
			}
		[self propertyListSkipSpaceAndComments];
		if(![self scanString:@"=" intoString:NULL])
			{
			*err=[NSString stringWithFormat:@"missing = for key: %@ (%@ found)", key, [[self string] substringFromIndex:[self scanLocation]]];
			return nil;
			}
		val=[self propertyListScanPropertyListElement:opt errorDescription:err];
		if(!val)
			{
#if 1
				NSLog(@"nil value %@", *err);
#endif
				return nil;
			}
#if 0
		NSLog(@"%@:=%@", key, val);
#endif
		[d setObject:val forKey:key];
		[self propertyListSkipSpaceAndComments];
		if(flag)
			{
			if([self scanString:@"}" intoString:NULL])	// ; might be missing before last element
				break;
			if(![self scanString:@";" intoString:NULL])
				{ // must have closing ;
				*err=[NSString stringWithFormat:@"missing ; for key %@", key];
				return nil;
				}
			}
		else
			[self scanString:@";" intoString:NULL];	// may have a closing ;
		[self propertyListSkipSpaceAndComments];
		}
	// process opt types here and make unmutable copy if requested
	return d;
}

- (id) propertyListScanPropertyListElement:(NSPropertyListMutabilityOptions) opt errorDescription:(NSString **) err;
{ // parse ASCII style element
	id val;
	[self propertyListSkipSpaceAndComments];
	if([self isAtEnd])
		return nil;
#if 0
	NSLog(@"propertyListScanPropertyListElement %@", [[self string] substringFromIndex:[self scanLocation]]);
#endif
	if([self scanString:@"{" intoString:NULL])
		{ // { key=value; ... [;] } - NSDictionary
		return [self propertyListScanPropertyListDictionary:opt errorDescription:err withBrace:YES];
		}
	if([self scanString:@"(" intoString:NULL])
		{ // ( value, value, ...) - NSArray
		NSMutableArray *a=[NSMutableArray arrayWithCapacity:10];
//		NSLog(@"( - NSArray");
		[self propertyListSkipSpaceAndComments];
		if(![self scanString:@")" intoString:NULL])
			{ // array is not empty
			while(YES)
				{
				val=[self propertyListScanPropertyListElement:opt errorDescription:err];
				if(!val)
					return nil;
				[a addObject:val];
				[self propertyListSkipSpaceAndComments];
				if([self scanString:@")" intoString:NULL])
					break;
				if(![self scanString:@"," intoString:NULL])
					{
					*err=[NSString stringWithFormat:@"missing ) or , after object %@", val];
					return nil;
					}
				[self propertyListSkipSpaceAndComments];
				if([self scanString:@")" intoString:NULL])
					break;  // (value, )
				}
			}
		// process opt types here and make unmutable copy if requested
		return a;
		}
	if([self scanString:@"<" intoString:NULL])
		{ // <xxxxxx> (hex data) - NSData - may also be the beginning of <?xml !!
		NSMutableData *a=[NSMutableData dataWithCapacity:100];
		BOOL second=NO;
		char value;
//		NSLog(@"< - NSData");
		while([self propertyListSkipSpaceAndComments], ![self scanString:@">" intoString:NULL])
			{
			unsigned int scl;
			unichar hc;
			if([self isAtEnd])
				{ // not a hex character!
				*err=@"unexpected end of file in <xx>";
				return nil;
				}
			hc=[[self string] characterAtIndex:(scl=[self scanLocation])];	// get hex character
			if(!((hc >= '0' && hc <='9') || (hc >= 'a' && hc <='f') || (hc >= 'A' && hc <='F')))
				{ // not a hex character!
				*err=[NSString stringWithFormat:@"invalid hex character: %C", hc];
				return nil;
				}
			if(hc <= '9')
				value=(value<<4) + ((hc-'0')&0x0f);
			else
				value=(value<<4) + ((hc-'a'+10)&0x0f);
			if(second)	// was second character
				[a appendBytes:&value length:1];
			second=!second;
			[self setScanLocation:scl+1];	// point to next character
			}
		return a;
		}
	if([self scanString:@"\"" intoString:NULL])
		val=[self propertyListScanQuotedString];
	else
		val=[self propertyListScanUnquotedString];
	if(!val)
		{
		*err=@"error in reading string - unexpected EOF";
		return nil;
		}
	return val;
}

- (id) propertyListScanJSONElement:(NSPropertyListMutabilityOptions) opt errorDescription:(NSString **) err;
{ // parse JSON elements
	id val=nil;
	double dval;
	//NS_TIME_START(VAR);
	[self propertyListSkipSpaceAndComments];
	//NS_TIME_END(VAR, "propertyListSkipSpaceAndComments");
	//NS_TIME_START(VAR);
	while([self scanString:@";" intoString:NULL])
		[self propertyListSkipSpaceAndComments];	// skip ignorable ;
	//NS_TIME_END(VAR, "skip ;");
	if([self isAtEnd])
		{
		*err=@"unexpected EOF";
		return nil;
		}
#if 0
	NSRange range=NSMakeRange([self scanLocation], 15);
	if(NSMaxRange(range) > [[self string] length])
		range.length=[[self string] length]-range.location;	// limit
	NSString *next=[[self string] substringWithRange:range];
	NSLog(@"propertyListScanJSONElement %@", next);
#endif
	if([self scanString:@"\"" intoString:NULL])
		{ // string
		  //NS_TIME_START(VAR);
			val=[self propertyListScanQuotedString];
			//NS_TIME_END(VAR, "propertyListScanQuotedString");
			if(!val)
				{
				*err=@"invalid string";
				return nil;
				}
		}
	else if([self scanString:@"{" intoString:NULL])
		{ // { key:value, key:value } - NSDictionary
			val=[NSMutableDictionary dictionaryWithCapacity:10];
			[self propertyListSkipSpaceAndComments];
			if(![self scanString:@"}" intoString:NULL])
				{
				while(YES)
					{ // parse elements until }
						id key;
						id value;
						//NS_TIME_START(VAR);
						key=[self propertyListScanJSONElement:opt errorDescription:err];
						//NS_TIME_END(VAR, "key");
#if 0
						NSLog(@"key = %@", key);
#endif
						if(!key)
							return nil;
						[self propertyListSkipSpaceAndComments];
						if(![self scanString:@":" intoString:NULL])
							{
							*err=[NSString stringWithFormat:@"missing : after key %@", val];
							return nil;
							}
						//NS_TIME_START(VAR);
						value=[self propertyListScanJSONElement:opt errorDescription:err];
						//NS_TIME_END(VAR, "value");
#if 0
						NSLog(@"value = %@", value);
#endif
						if(!value)
							return nil;
						[val setObject:value forKey:key];
						[self propertyListSkipSpaceAndComments];
						if([self scanString:@"}" intoString:NULL])
							break;
						if(![self scanString:@"," intoString:NULL])
							{
							*err=[NSString stringWithFormat:@"missing } or , after object %@", val];
							return nil;
							}
					}
				}
		}
	else if([self scanString:@"[" intoString:NULL])
		{ // [ value, value, ...] - NSArray
			val=[NSMutableArray arrayWithCapacity:10];
			[self propertyListSkipSpaceAndComments];
			if(![self scanString:@"]" intoString:NULL])
				{
				while(YES)
					{ // parse elements until ]
						id value;
						value=[self propertyListScanJSONElement:opt errorDescription:err];
						if(!value)
							return nil;
						[val addObject:value];
						[self propertyListSkipSpaceAndComments];
						if([self scanString:@"]" intoString:NULL])
							break;
						if(![self scanString:@"," intoString:NULL])
							{
							*err=[NSString stringWithFormat:@"missing ] or , after object %@", val];
							return nil;
							}
					}
				}
		}
	// these keywords are case sensitive
	else if([self scanString:@"null" intoString:NULL])
		val=[NSNull null];
	else if([self scanString:@"true" intoString:NULL])
		val=[NSNumber numberWithBool:YES];
	else if([self scanString:@"false" intoString:NULL])
		val=[NSNumber numberWithBool:NO];
	else if([self scanDouble:&dval])
		{
		if(dval <= INT_MAX && dval >= INT_MIN && dval == (double)(int) dval)	// seems to have precise int representation
			val=[NSNumber numberWithInt:(int) dval];
		else
			val=[NSNumber numberWithDouble:dval];
		}
	else
		{
		NSString *next=[[self string] substringFromIndex:[self scanLocation]];
		next=[next stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
		*err=[NSString stringWithFormat:@"unknown JSON element: %@", [next substringToIndex:MIN(15, [next length])]];
		}
#if 0
	NSLog(@"JSON parsed: %@ %@", val, *err);
#endif
	return val;
}

@end

@implementation NSCFType

// used to pass CF$UID values from (binary) keyedarchived property list

+ (id) CFUIDwithValue:(NSUInteger) val;
{
	NSCFType *c=[[self new] autorelease];
	if(c)
		c->value=val;
	return c;
}

- (NSUInteger) uid; { return value; }

- (NSString *) description; { return [NSString stringWithFormat:@"NSCFType (%u)", value]; }

@end

struct magic
{
	char magic[6];
	char version[2];
};

#define BPMAGIC "bplist00"

struct trailer
{
	char unused[6];
	unsigned char offsetSize;	// size of offsets in offset table
	unsigned char refSize;		// size of references in arrays and dicts
	long long objectCount;		// total number of objects
	long long topObject;		// number of top object
	long long objectsOffset;	// offset of objectTable
};

@interface _NSBinaryPropertyList : NSObject
{
	NSPropertyListMutabilityOptions isMutable;
	NSMutableData *data;			// for writing
	NSMutableArray *objects;		// all objects to generate Index
	struct trailer trailer;
	unsigned long *offtable;		// offset table
	unsigned long offtablealloc;	// how much allocated
	unsigned char *bytes;			// bytes
	unsigned char *bp;				// byte scanning pointer
	unsigned int length;			// length of data
}

+ (id) _plistFromBinaryData:(NSData *) data mutabilityOption:(NSPropertyListMutabilityOptions) opt;
- (id) initWithData:(NSData *) d mutabilityOption:(NSPropertyListMutabilityOptions) opt;
- (id) _parse;

- (BOOL) _addObject:(id) obj;
- (void) _addChar:(char) c;
- (void) _addInt:(long) integer withLen:(int) len;
- (void) _addTag:(int) tag withLen:(int) len;

@end

@implementation _NSBinaryPropertyList

/* compatible to NSPropertyListBinaryFormat_v1_0

Here is a full description: http://darwinsource.opendarwin.org/10.3/CF-299/Parsing.subproj/CFBinaryPList.c
Header
bplist00	Version 0.0

Encoded objects
00		nil
08		false
09		true
0f		fill	
1n	(1=I) integer with 2^n bytes
10xx
11xxxx
12xxxxxxxx
13xxxxxxxxxxxxxxxx
2n		float (real) with 2^n bytes
22ffffffff
3n		NSDate with 2^n bytes float
33		normally used
4n		n encoded bytes/NSData (incl. 00)
4f10nn	n encoded bytes/NSData
5n	(5=S) ASCII string with n bytes
5f10nn	ASCII string with n bytes (10=integer with 1 byte)
6n		Unicode string
7n		%
8n		CF$UID with n+1 bytes integer
9n		%
an	(a=A) NSArray with n entries
af10nn	NSArray with n entries
af11nnnn	NSArray with n entries (11=integer with 2 bytes)
bn		%
cn		%
dn	(d=D) NSDictionary with n entries - note, the keys references come first and then all object references
df1nnn	NSDictionary with n entries
en		%
fn		%

Offset table 
		list of ints, byte size of which is given in trailer
 -- these are the byte offsets into the file
 -- number of these entries is in the trailer 

Trailer
000000		fill
   n		byte size of offset ints in offset table
   n		byte size of object refs in arrays and dicts
nnnn		number of offsets in offset table (the same as the number of objects)
nnnn		element # in offset table which is top level object 

there is plutil to convert formats
see also: http://rixstep.com/2/20050503,01.shtml about plutil 

*/

#if 1
+ (void) initialize
{ // test byte swapping methods for correctness
	float flt=M_PI;
	double dbl=M_PI;
#if 0
		{
			float want, have;
			float dwant, dhave;
			NSLog(@"host is %@", NSHostByteOrder() == NS_BigEndian?@"BigEndian":@"LittleEndian");
			NSLog(@"%.30g", NSSwapBigFloatToHost(*((NSSwappedFloat *)&flt)));
			have=NSSwapBigFloatToHost(*((NSSwappedFloat *)&flt));
			want=-4.033146e+16;
			NSLog(@"%08x %08x", *(long *)&have, *(long *)&want);
			NSLog(@"%.30g", NSSwapLittleFloatToHost(*((NSSwappedFloat *)&flt)));
			have=NSSwapLittleFloatToHost(*((NSSwappedFloat *)&flt));
			want=M_PI;
			NSLog(@"%08x %08x", *(long *)&have, *(long *)&want);
			NSLog(@"%.30g", NSSwapBigDoubleToHost(*((NSSwappedDouble *)&dbl)));
			dhave=NSSwapBigDoubleToHost(*((NSSwappedDouble *)&dbl));
			dwant=3.20737563067636581208678536384e-192;
			NSLog(@"%016llx %016llx", *(long long *)&have, *(long long *)&want);
			NSLog(@"%.30g", NSSwapLittleDoubleToHost(*((NSSwappedDouble *)&dbl)));
		}
#endif
	NSAssert(NSSwapShort(0x1234) == 0x3412, @"NSSwapShort failed");
	NSAssert(NSSwapLong(0x12345678L) == 0x78563412L, @"NSSwapLong failed");
	NSAssert(NSSwapLongLong(0x123456789abcdef0LL) == 0xf0debc9a78563412LL, @"NSSwapLongLong failed");
	NSAssert(NSSwapBigFloatToHost(*((NSSwappedFloat *)&flt)) == ((NSHostByteOrder() == NS_LittleEndian)?(float)-40331460896358400.0:(float)M_PI), @"NSSwapBigFloatToHost failed");
	NSAssert(NSSwapLittleFloatToHost(*((NSSwappedFloat *)&flt)) == ((NSHostByteOrder() == NS_BigEndian)?(float)-40331460896358400.0:(float)M_PI), @"NSSwapLittleFloatToHost failed");
	NSAssert(NSSwapBigDoubleToHost(*((NSSwappedDouble *)&dbl)) == ((NSHostByteOrder() == NS_LittleEndian)?3.20737563067636581208678536384e-192:M_PI), @"NSSwapBigDoubleToHost failed");
	NSAssert(NSSwapLittleDoubleToHost(*((NSSwappedDouble *)&dbl)) == ((NSHostByteOrder() == NS_BigEndian)?3.20737563067636581208678536384e-192:M_PI), @"NSSwapLittleDoubleToHost failed");
#if 0
	NSLog(@"all tests passed!");
#endif
}
#endif

// decoding

inline static unsigned int _binaryObjectPos(_NSBinaryPropertyList *self, unsigned int oid);
inline static long _binaryInt(_NSBinaryPropertyList *self);
inline static unsigned _binaryLen(_NSBinaryPropertyList *self);

inline static unsigned int _binaryObjectPos(_NSBinaryPropertyList *self, unsigned int oid)
{ // get relative position of object
	int cnt;
	unsigned char *op;
	unsigned long off;
	if(oid >= self->trailer.objectCount)
		{
		NSLog(@"oid=%u >= object count %u", oid, (unsigned) self->trailer.objectCount);
		return 0;	// invalid index
		}
	cnt=self->trailer.offsetSize;
	op=self->bytes+((unsigned long)self->trailer.objectsOffset)+cnt*oid;	// reference index
	off=0;
	while(cnt-- > 0)
		off=(off<<8)+(*op++);	// get offset
	return off;
}

inline static long _binaryInt(_NSBinaryPropertyList *self)
{ // read integer
	int len=(1<<_binaryLen(self));
	long value=0;
#if 0
	NSLog(@"_binaryInt len=%d", len);
#endif
	while(len-- > 0)
		value=(value<<8)+(*self->bp++);	// collect bytes MSB first (bigendian)
#if 0
	NSLog(@"_binaryInt value=%d", value);
#endif
	return value;
}

inline static unsigned _binaryLen(_NSBinaryPropertyList *self)
{
	int len=*self->bp++&0x0f;
	if(len != 0x0f)
		return len;
	if((*self->bp&0xf0) != 0x10)
		return 0;	// error! - not followed by integer
	return _binaryInt(self);
}

static id _binaryObject(_NSBinaryPropertyList *self, unsigned long off)
{ // read object
	unsigned char byte;
	NSInteger len;
#if 0
	NSLog(@"_binaryObject offset=%lu", off);
#endif
	if(off < sizeof(BPMAGIC)-1 || off >= self->length)
		{ // not precise but clearly invalid
		NSLog(@"_binaryObject(..., invalid off=%lu) length=%u", off, self->length);
		return nil;	// some error
		}
	// here, we should check if we already have loaded this object and don't need to create a new instance
	// but this would require a cache for all loaded objects: NSMapTable(int offset, id object)
	self->bp=self->bytes+off;
next:
	byte=*self->bp;
#if 0
	NSLog(@"byte=%02x", byte);
#endif
	switch(byte&0xf0)
		{
		case 0x00:
			{
			switch(byte)
				{
				case 0x00:	return [NSNull null];
				case 0x08:	return [NSNumber numberWithBool:NO];
				case 0x09:	return [NSNumber numberWithBool:YES];
				case 0x0f:	self->bp++; goto next;	// skip fill byte
				}
			break;
			}
		case 0x10:	// integer
			return [NSNumber numberWithInt:_binaryInt(self)];
		case 0x20:	// float/double
		case 0x30:	// NSDate
			{
			unsigned char bytes[8];
			len=(1<<_binaryLen(self));	// bytes to fetch
#if 0
			NSLog(@"float len=%d", len);
#endif
			if(len > sizeof(bytes)) len=sizeof(bytes);	// limit
			memcpy(bytes, self->bp, len);
//			self->bp+=len;
#if 0
			NSLog(@"bytes=%@", [NSData dataWithBytesNoCopy:bytes length:len freeWhenDone:NO]);
#endif
			if((byte&0xf0) == 0x30)
				return [NSDate dateWithTimeIntervalSinceReferenceDate:NSSwapBigDoubleToHost(*((NSSwappedDouble *) bytes))];
			if(len == 4)
				{
#if 0
				NSLog(@"decoded float=%le", NSSwapBigFloatToHost(*((NSSwappedFloat *) bytes)));
#endif
				return [NSNumber numberWithFloat:NSSwapBigFloatToHost(*((NSSwappedFloat *) bytes))];
				}
			if(len == 8)
				{
#if 0
				NSLog(@"decoded double=%le", NSSwapBigDoubleToHost(*((NSSwappedDouble *) bytes)));
#endif
				return [NSNumber numberWithDouble:NSSwapBigDoubleToHost(*((NSSwappedDouble *) bytes))];
				}
			return nil;	// raise exception?
			}
		case 0x40:	// NSData
			{
				len=_binaryLen(self);
				if(self->isMutable&NSPropertyListMutableContainersAndLeaves)
					return [NSMutableData dataWithBytes:(void *) self->bp length:len];	// return a mutable copy
				return [NSData dataWithBytes:(void *) self->bp length:len];	// return a copy
			}
		case 0x50:	// ASCII NSString
			{
				len=_binaryLen(self);
				if(self->isMutable&NSPropertyListMutableContainersAndLeaves)
					return [NSMutableString stringWithCString:(char *) self->bp length:len];	// return a copy
				return [NSString stringWithCString:(char *) self->bp length:len];	// return a copy
			}
		case 0x60:	// UNICODE NSString
			{
#if 0
				NSLog(@"offset=%lu", off);
				NSLog(@"byte=%02x", byte);
				NSLog(@"record: %@", [NSData dataWithBytes:self->bp length:20]);
#endif
				len=_binaryLen(self);
#if 0
				NSLog(@"unicode len=%d", len);
				NSLog(@"NS_BigEndian =%d", NS_BigEndian);
				NSLog(@"NS_LittleEndian =%d", NS_LittleEndian);
				NSLog(@"hostbyteorder =%d", NSHostByteOrder());
#endif
				if(NSHostByteOrder() != NS_BigEndian)
					{ // we need to swap bytes
					int i;
					unichar *bfr=(unichar *) objc_malloc(len*sizeof(bfr));
#if 0
						NSLog(@"swapping bytes: %@", [NSData dataWithBytes:self->bp length:MIN(2*len, 10)]);
#endif
					for(i=0; i<len; i++)
						bfr[i]=NSSwapShort(((unichar *)(self->bp))[i]);	// swap bytes
#if 0
						NSLog(@"result: %@", [[[NSString alloc] initWithCharactersNoCopy:bfr length:len freeWhenDone:YES] autorelease]);
#endif
						if(self->isMutable&NSPropertyListMutableContainersAndLeaves)
						return [[[NSMutableString alloc] initWithCharactersNoCopy:bfr length:len freeWhenDone:YES] autorelease];	// take ownership
					return [[[NSString alloc] initWithCharactersNoCopy:bfr length:len freeWhenDone:YES] autorelease];	// take ownership
					}
				if(self->isMutable&NSPropertyListMutableContainersAndLeaves)
					return [NSMutableString stringWithCharacters:(unichar *) self->bp length:len];	// return a copy
				return [NSString stringWithCharacters:(unichar *) self->bp length:len];	// return a copy
			}
		case 0x80:	// CF$UID
			{
			unsigned int uid=0;
			len=(byte&0x0f)+1;
			self->bp++;
			while(len-->0)
				uid=(uid<<8)+(*self->bp++);	// collect bytes
			return [NSCFType CFUIDwithValue:uid];
			}
		case 0xa0:	// NSArray
			{
			NSMutableArray *a;
			unsigned char *savedbp;
			len=_binaryLen(self);
			a=[NSMutableArray arrayWithCapacity:len];
			while(len-- > 0)
				{
				unsigned int onum=0;
				id obj;
				int i;
				for(i=0; i<self->trailer.refSize; i++)
					onum=(onum<<8)+(*self->bp++);
				savedbp=self->bp;
				obj=_binaryObject(self, _binaryObjectPos(self, onum));
				[a addObject:obj];
				self->bp=savedbp;
				}
			if((self->isMutable&(NSPropertyListMutableContainersAndLeaves|NSPropertyListMutableContainers)) == 0)
				; // make immutable
			return a;
			}
		case 0xd0:	// NSDictionary
			{
			NSMutableDictionary *d;
				unsigned char *savedbp;
			unsigned int delta;
			len=_binaryLen(self);
			delta=len*self->trailer.refSize;
#if 0
			NSLog(@"delta=%lu", delta);
#endif
			d=[NSMutableDictionary dictionaryWithCapacity:len];
			while(len-- > 0)
				{
				id key;
				id obj;
				unsigned int knum=0;
				unsigned int onum=0;
				int i;
				for(i=0; i<self->trailer.refSize; i++)
					{
					knum=(knum<<8)+(self->bp[0]);
					onum=(onum<<8)+(self->bp[delta]);
					self->bp++;
					}
#if 0
				NSLog(@"knum=%lu onum=%lu", knum, onum);
#endif				
				savedbp=self->bp;
				key=_binaryObject(self, _binaryObjectPos(self, knum));
				obj=_binaryObject(self, _binaryObjectPos(self, onum));
#if 0
				NSLog(@"<key>%@</key>: %@", key, obj);
#endif
				[d setObject:obj forKey:key];
				self->bp=savedbp;
				}
			if((self->isMutable&(NSPropertyListMutableContainersAndLeaves|NSPropertyListMutableContainers)) == 0)
				; // make immutable
			return d;
			}
		}
	return nil;	// unknown
}

- (id) initWithData:(NSData *) d mutabilityOption:(NSPropertyListMutabilityOptions) opt;
{
	if((self=[super init]))
		{
		bytes=(unsigned char *) [d bytes];
		length=[d length];
		isMutable=opt;
		}
	return self;
}

- (id) _parse;
{
	unsigned long objectTableSize;
#if 0
	NSLog(@"BinaryPlist _parse");
#endif
	if(length > sizeof(BPMAGIC)-1 && memcmp(bytes, BPMAGIC, sizeof(BPMAGIC)-1) != 0)
		return nil;	// bad header
	if(length < sizeof(trailer) + sizeof(BPMAGIC) + 1)
		return nil;	// missing trailer
#if 0
	NSLog(@"header, length=%lu, and trailer ok", length);
#endif
	memcpy(&trailer, bytes + length - sizeof(trailer), sizeof(trailer));
#if 0
	NSLog(@"byte order = %@", NSHostByteOrder() == NS_BigEndian?@"Host is Big Endian":@"Host is Little Endian");
	NSLog(@"object count =%lu", (unsigned long) trailer.objectCount);
	NSLog(@"top object =%lu", (unsigned long) trailer.topObject);
	{
		int i;
		for(i=0; i<sizeof(trailer); i++)
			printf("%02x", ((unsigned char *)&trailer)[i]);
		printf("\n");
	}
#endif
	trailer.objectCount=NSSwapBigLongLongToHost(trailer.objectCount);	// number of objects
	trailer.topObject=NSSwapBigLongLongToHost(trailer.topObject);
#if 0
	NSLog(@"swapped");
	NSLog(@"object count =%lu", (unsigned long) trailer.objectCount);
	NSLog(@"top object =%lu", (unsigned long) trailer.topObject);
	{
		int i;
		for(i=0; i<sizeof(trailer); i++)
			printf("%02x", ((unsigned char *)&trailer)[i]);
		printf("\n");
	}
#endif
	if(trailer.topObject >= trailer.objectCount)
		return nil;	// bad
#if 0
	NSLog(@"top object ok");
#endif
	trailer.objectsOffset=NSSwapBigLongLongToHost(trailer.objectsOffset);
	objectTableSize=((unsigned long) trailer.objectCount)*trailer.offsetSize;	// don't need to do a long long multiply on a 32 bit processor...
#if 0
	NSLog(@"offsetSize=%lu", trailer.offsetSize);
	NSLog(@"objectTableSize=%lu", objectTableSize);
	NSLog(@"objectsOffset=%lu", (unsigned long) trailer.objectsOffset);
	NSLog(@"refSize =%lu", (unsigned long) trailer.refSize);
#endif
	if(trailer.objectsOffset+objectTableSize+sizeof(trailer) != length)
		return nil;	// bad offset table size
#if 0
	NSLog(@"object table ok");
#endif
	return _binaryObject(self, _binaryObjectPos(self, trailer.topObject));
}

+ (id) _plistFromBinaryData:(NSData *) d mutabilityOption:(NSPropertyListMutabilityOptions) opt;
{
	_NSBinaryPropertyList *pl=[[[self alloc] initWithData:d mutabilityOption:opt] autorelease];
	return [pl _parse];
}

// encoding

- (void) _addIndexOf:(id) obj;
{ // write index of this object encoded by as much bytes as defined by current refSize
	unsigned long idx=[objects indexOfObjectIdenticalTo:obj];
	if(trailer.refSize == 1)
		{
		unsigned char cidx=idx;
		[data appendBytes:&cidx length:sizeof(cidx)];
		}
	else if(trailer.refSize == 2)
		{
		unsigned short sidx=NSSwapHostShortToBig(idx);
		[data appendBytes:&sidx length:sizeof(sidx)];
		}
	else
		{
		unsigned long lidx=NSSwapHostLongToBig(idx);
		[data appendBytes:&lidx length:sizeof(lidx)];
		}
}

// FIXME: make [NSDictionary class] statically cached references to gain some more speed

- (BOOL) _addObject:(id) obj;
{ // try to write with given index length - if that fails, return NO and we will start over with a larger one
	unsigned long idx;
#if 0
	NSLog(@"_addObject: %@", obj);
#endif
	if([objects indexOfObjectIdenticalTo:obj] != NSNotFound)
		return YES;	// has already been encoded and its index can be found - used to break recursion
	idx=[objects count];		// object index
	[objects addObject:obj];	// add to list of known objects
	if(idx > (1<<(8*trailer.refSize))-1)
		return NO;	// out of range of index size
	if(idx*sizeof(offtable[0]) >= offtablealloc)	// we need more space to store this index
		{
		offtable=objc_realloc(offtable, offtablealloc=2*offtablealloc+8*sizeof(offtable[0]));	// increase allocation of offset table
#if 0
		NSLog(@"larger: %08x %lu of %lu", offtable, idx, offtablealloc);
#endif
		}
	if([obj isKindOfClass:[NSDictionary class]])
		{ // we need 4 passes - the first two write out all referenced objects and their keys, i.e. go depth first
		NSEnumerator *e;
		id o;
		e=[obj keyEnumerator];	// keys
		while((o=[e nextObject]))
			{ // write keys
			if(![self _addObject:o])
				return NO;	// failed
			}
		e=[obj objectEnumerator];	// objects
		while((o=[e nextObject]))
			{ // write contents first
			if(![self _addObject:o])
				return NO;	// failed
			}
		}
	else if([obj isKindOfClass:[NSArray class]])
		{ // we need 2 passes - the second writes references only (all objects must already exist!)
		NSEnumerator *e;
		id o;
		e=[obj objectEnumerator];	// objects
		while((o=[e nextObject]))
			{ // write contents first
			if(![self _addObject:o])
				return NO;	// failed
			}
		}
	offtable[idx]=[data length];	// finally store file offset
	if([obj isKindOfClass:[NSDictionary class]])
		{ // we need 4 passes - last two write references only (all objects must already exist!)
		NSEnumerator *e;
		id o;
		[self _addTag:0xd0 withLen:[obj count]];
		e=[obj keyEnumerator];		// keys first
		while((o=[e nextObject]))
			{ // write key indexes
			[self _addIndexOf:o];
			}
		e=[obj objectEnumerator];	// objects
		while((o=[e nextObject]))
			{ // write content indexes
			[self _addIndexOf:o];
			}
		}
	else if([obj isKindOfClass:[NSArray class]])
		{
		NSEnumerator *e;
		id o;
		[self _addTag:0xa0 withLen:[obj count]];
		e=[obj objectEnumerator];	// objects
		while((o=[e nextObject]))
			{ // write content indexes
			[self _addIndexOf:o];
			}
		}
	else if([obj isKindOfClass:[NSString class]])
		{
		NSAutoreleasePool *arp=[NSAutoreleasePool new];
		NSData *s=[obj dataUsingEncoding:NSASCIIStringEncoding];	// try as ASCII first...
		int len;
		if(s)
			{ // we can encode as ASCII
			len=[s length];
			[self _addTag:0x50 withLen:len];
			}
		else
			{ // encode Unicode
			s=[obj dataUsingEncoding:NSUnicodeStringEncoding];
			len=[s length];
			if(NSHostByteOrder() != NS_BigEndian)
					{ // swap for little endian encoding
						unichar *b;
						int i;
#if 0
						NSLog(@"swap on write: %@", obj);
#endif
						s=[[s mutableCopy] autorelease];
						b=[(NSMutableData *) s mutableBytes];
						for(i=0; i<len/2; i++)
							b[i]=NSSwapShort(b[i]);
					}
			[self _addTag:0x60 withLen:len];
			}
		[data appendData:s];
		[arp release];
		}
	else if([obj isKindOfClass:[NSNull class]])
		{
		[self _addTag:0x00 withLen:0];
		}
	else if([obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSDate class]])
		{
		if([obj isKindOfClass:[GSFloatNumber class]])
			{
			NSSwappedFloat f=NSSwapHostFloatToBig([obj floatValue]);
			[self _addTag:0x20 withLen:2];
			[data appendBytes:&f length:sizeof(f)];
			}
		else if([obj isKindOfClass:[GSDoubleNumber class]])
			{
			// CHECKME - this might fail on Linux-ARM due to strange byte swapping for long long!
			NSSwappedDouble f=NSSwapHostDoubleToBig([obj doubleValue]);
			[self _addTag:0x20 withLen:3];
			[data appendBytes:&f length:sizeof(f)];
			}
		else if([obj isKindOfClass:[NSDate class]])
			{
			// CHECKME - this might fail on Linux-ARM due to strange byte swapping for long long!
			NSSwappedDouble f=NSSwapHostDoubleToBig([obj timeIntervalSinceReferenceDate]);
			[self _addTag:0x30 withLen:3];
			[data appendBytes:&f length:sizeof(f)];
			}
		else if([obj isKindOfClass:[GSBoolNumber class]])
			{
			if([obj boolValue])
				[self _addTag:0x09 withLen:0];
			else
				[self _addTag:0x08 withLen:0];
			}
		else
			{ // other integer
			// FIXME: should use longLongValue and check for required size
			long val=[obj longValue];
			int len;
			if(val < 128 || val >= -128)
				len=0;	// byte
			else if(val < 32768 || val >= -32768)
				len=1;	// 2 byte
			else
				len=2;
			[self _addInt:val withLen:len];
			}
		}
	else if([obj isKindOfClass:[NSData class]])
		{
		[self _addTag:0x40 withLen:[obj length]];
		[data appendData:obj];
		}
	else if([obj isKindOfClass:[NSCFType class]])
		{
		short f=NSSwapHostShortToBig([obj uid]);
		[self _addTag:0x80 withLen:0];
		[data appendBytes:&f length:sizeof(f)];
		}
	else
		[NSException raise:@"BinaryPlist" format:@"can't archive objects of class %@", NSStringFromClass([obj class])];
	return YES;
}

- (void) _addChar:(char) c;
{
	[data appendBytes:&c length:sizeof(c)];
}

- (void) _addInt:(long) integer withLen:(int) len;
{ // MSB first with specified length
	switch(len)
		{
		case 2:
			{
				long f=NSSwapHostLongToBig(integer);
				[self _addChar:0x12];
				[data appendBytes:&f length:sizeof(f)];
				break;
			}
		case 1:
			{
				short f=NSSwapHostShortToBig(integer);
				[self _addChar:0x11];
				[data appendBytes:&f length:sizeof(f)];
				break;
			}
		case 0:
			{
				char f=integer;	// nothing to swap...
				[self _addChar:0x10];
				[data appendBytes:&f length:sizeof(f)];
				break;
			}
		default:
			[NSException raise:@"BinaryPlist" format:@"can't save integer of size 2^%d", len];
		}
}

- (void) _addTag:(int) tag withLen:(int) len;
{
#if 0
	NSLog(@"_addTag:%02x withLen:%d", tag, len);
#endif
	if(len<15)
		{ // short length
		[self _addChar:tag+len];
		return;
		}
	[self _addChar:tag+15];	// long length
	if(len <= 255)
		[self _addInt:len withLen:0];
	else if(len <= 65535)
		[self _addInt:len withLen:1];
	else
		[self _addInt:len withLen:2];
}

- (NSData *) dataFromPlist:(id) plist errorString:(NSString **) errorString;
{ // generate binary property list
	data=[NSMutableData dataWithCapacity:10000];	// best first guess
	[data appendBytes:BPMAGIC length:sizeof(BPMAGIC)-1];
	for(trailer.refSize=1; trailer.refSize<3; trailer.refSize++)
		{ // try to write with increasing index length
		NSAutoreleasePool *arp=[NSAutoreleasePool new];
		unsigned long maxindex=(1<<(8*trailer.refSize))-1;
		objects=[[NSMutableArray alloc] initWithCapacity:256];
#if 0
		NSLog(@"try writing refSize=%d bytes maxindex=%lu", trailer.refSize, maxindex);
#endif
		if([self _addObject:plist])	// write tree
			{ // ok
			unsigned int i;
			[arp release];
#if 0
			NSLog(@"writing trailer");
#endif
			trailer.objectCount=[objects count];
			trailer.objectsOffset=[data length];	// offset of objectTable
			trailer.topObject=[objects indexOfObject:plist];
			if(trailer.objectsOffset < 65536)
				{ // can reduce offsets to words
				if(trailer.objectsOffset < 256)
					{ // can reduce offset table to bytes
						trailer.offsetSize=1;
					for(i=0; i<trailer.objectCount; i++)
						((unsigned char *)offtable)[i]=offtable[i];
					}
				else
					{ // reduce to words
						trailer.offsetSize=2;
					 if(NSHostByteOrder() != NS_BigEndian)
							 {
								 for(i=0; i<trailer.objectCount; i++)
									 ((unsigned short *)offtable)[i]=NSSwapHostShortToBig((unsigned short) offtable[i]);
							 }
						else
								{
									for(i=0; i<trailer.objectCount; i++)
										((unsigned short *)offtable)[i]=offtable[i];
								}
					}
				}
			else if(NSHostByteOrder() != NS_BigEndian)
				{ // convert to bigendian
					trailer.offsetSize=4;
				for(i=0; i<trailer.objectCount; i++)
					offtable[i]=NSSwapHostLongToBig(offtable[i]);
				}
			[data appendBytes:offtable length:[objects count]*trailer.offsetSize];	// append complete offset table
			objc_free(offtable);
			trailer.objectsOffset=NSSwapHostLongLongToBig(trailer.objectsOffset);
			trailer.objectCount=NSSwapHostLongLongToBig(trailer.objectCount);
			trailer.topObject=NSSwapHostLongLongToBig(trailer.topObject);
			[data appendBytes:&trailer length:sizeof(trailer)];	// append trailer
			[objects release];
#if 0
			NSLog(@"data=%@", data);
			NSLog(@"decoded=%@", [[self class] _plistFromBinaryData:data mutabilityOption:NSPropertyListImmutable]);	// parse back
#endif
			return data;
			}
		[arp release];
		if([objects count] <= maxindex)
			{
#if 1
			NSLog(@"other error");
#endif
			[objects release];
			return nil;	// other error
			}
#if 0
		NSLog(@"start over");
#endif
		[objects release];	// there wasn't enough room here
		[data setLength:sizeof(BPMAGIC)-1];	// start over
		}
	return nil;	// can't write in any index length
}

@end

@implementation NSPropertyListSerialization

+ (NSData *) dataFromPropertyList:(id) plist format:(NSPropertyListFormat) format errorDescription:(NSString **) errorString;
{
	if(format == NSPropertyListBinaryFormat_v1_0)
		return [[[_NSBinaryPropertyList new] autorelease] dataFromPlist:plist errorString:errorString];
	return [[self _stringFromPropertyList:plist format:format errorDescription:errorString] dataUsingEncoding:NSUTF8StringEncoding]; 
}

+ (void) _appendStringTo:(NSMutableString *) str fromXMLEscapedValue:(NSString *) value tag:(NSString *) tag;
{
	// escape characters: " & ; < > and encode UNICODE characters
	[str appendFormat:@"<%@>%@</%@>\n", [tag _stringByExpandingXMLEntities], [value _stringByExpandingXMLEntities], [tag _stringByExpandingXMLEntities]];
}

// FIXME: make this private methods for all relevant object classes and error for NSObject
// to get rid of isKindOfClass ladder

+ (BOOL) _appendStringTo:(NSMutableString *) str fromXMLPropertyListElement:(id) plist errorDescription:(NSString **) errorString;
{ // encode element as XML
	if(!plist)
		{
		if(errorString)
			*errorString=@"Can't encode nil object";
		return NO;
		}
	if([plist isKindOfClass:[NSDictionary class]])
		{
		NSEnumerator *enumerator=[plist keyEnumerator];
		id key;
		[str appendString:@"<dict>\n"];
		while((key=[enumerator nextObject]))
			{
			if([key isKindOfClass:[NSString class]])
				[self _appendStringTo:str fromXMLEscapedValue:key tag:@"key"];
			else
				{
				if(![self _appendStringTo:str fromXMLPropertyListElement:key errorDescription:errorString])
					return NO;
				}
			if(![self _appendStringTo:str fromXMLPropertyListElement:[(NSDictionary *) plist objectForKey:key] errorDescription:errorString])
				return NO;
			}
		[str appendString:@"</dict>\n"];
		}
	else if([plist isKindOfClass:[NSArray class]])
		{
		NSEnumerator *enumerator=[plist objectEnumerator];
		id o;
		[str appendString:@"<array>\n"];
		while((o=[enumerator nextObject]))
			{
			if(![self _appendStringTo:str fromXMLPropertyListElement:o errorDescription:errorString])
				return NO;
			}
		[str appendString:@"</array>\n"];
		}
	else if([plist isKindOfClass:[NSString class]])	// what about attributed strings??
		{
		[self _appendStringTo:str fromXMLEscapedValue:plist tag:@"string"];
		}
	else if([plist isKindOfClass:[NSNumber class]])
		{
		if([plist isKindOfClass:[GSFloatNumber class]] || [plist isKindOfClass:[GSDoubleNumber class]])
			[str appendFormat:@"<real>%@</real>\n", plist];
		else if([plist isKindOfClass:[GSBoolNumber class]])
			[str appendString:[plist boolValue]?@"<true/>":@"<false/>"];
		else
			[str appendFormat:@"<integer>%@</integer>\n", plist];
		}
	else if([plist isKindOfClass:[NSData class]])
		{
			[str appendString:@"<data>\n"];
			[str appendString:[(NSData *) plist _base64String]];
			[str appendString:@"</data>\n"];
		}
	else if([plist isKindOfClass:[NSDate class]])
		{
			[str appendFormat:@"<date>%@</date>\n", [(NSDate *) plist description]];
		}
	else
		{
		if(errorString)
			*errorString=[NSString stringWithFormat:@"Can't encode object of class %@ as property list", NSStringFromClass([plist class])];
		return NO;
		}
	return YES;
}

+ (BOOL) _appendStringTo:(NSMutableString *) str fromJSONPropertyListElement:(id) plist level:(NSInteger) level errorDescription:(NSString **) errorString;
{ // encode element as JSON
	NSInteger l=level;
	while(l > 0)
		{ // indent as requested
			[str appendString:@"  "];
			l--;
		}
	if(!plist)
		{
		if(errorString)
			*errorString=@"Can't encode nil object";
		return NO;
		}
	else if([plist isKindOfClass:[NSDictionary class]])
		{
		NSEnumerator *enumerator=[plist keyEnumerator];
		id key;
		BOOL first=YES;
		[str appendString:level>=0?@"{\n":@"{"];
		while((key=[enumerator nextObject]))
			{
			if(!first)
				[str appendString:level >= 0?@",\n":@","];
			if(![self _appendStringTo:str fromJSONPropertyListElement:key level:level+1 errorDescription:errorString])
				return NO;
			if(level >= 0)
				[str appendString:@" : "];
			else
				[str appendString:@":"];
			if(![self _appendStringTo:str fromJSONPropertyListElement:[(NSDictionary *) plist objectForKey:key] level:level errorDescription:errorString])
				return NO;
			first=NO;
			}
		[str appendString:level>=0?@"\n}":@"}"];
		}
	else if([plist isKindOfClass:[NSArray class]])
		{
		NSEnumerator *enumerator=[plist objectEnumerator];
		id o;
		BOOL first=YES;
		[str appendString:@"["];
		while((o=[enumerator nextObject]))
			{
			if(!first)
				[str appendString:level >= 0?@",\n":@","];
			if(![self _appendStringTo:str fromJSONPropertyListElement:o level:level+1 errorDescription:errorString])
				return NO;
			first=NO;
			}
		[str appendString:level>=0?@"\n]":@"]"];
		}
	else if([plist isKindOfClass:[NSString class]])	// what about attributed strings??
		{
		plist=[plist stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];	// double esacpe
		plist=[plist stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];	// esacpe quote
		[str appendFormat:@"\"%@\"", plist];
		}
	else if([plist isKindOfClass:[NSNumber class]])
		{
		if([plist isKindOfClass:[GSBoolNumber class]])
			[str appendString:[plist boolValue]?@"true":@"false"];
		else
			[str appendFormat:@"%@", plist];
		}
	else if([plist isKindOfClass:[NSNull class]])
		{
		[str appendString:@"null"];
		}
#if 0		// can we really encode NSData as JSON?
	else if([plist isKindOfClass:[NSData class]])
		{
		// well, we should convert to Unicode and quote
		[str appendString:@"<data>\n"];
		[str appendString:[(NSData *) plist _base64String]];
		[str appendString:@"</data>\n"];
		}
#endif
	else if([plist isKindOfClass:[NSDate class]])
		{
		// encode as  ISO-8601 string (quoted?)
		[str appendFormat:@"<date>%@</date>\n", [(NSDate *) plist description]];
		}
	else
		{ // unknown object trype (e.g. NSURL)
		if(errorString)
			*errorString=[NSString stringWithFormat:@"Can't encode object of class %@ as JSON list", NSStringFromClass([plist class])];
		// seems to raise an exception on Cocoa
		return NO;
		}
	if(level >= 0)
		[str appendString:@"\n"];
	return YES;
}

+ (NSString *) _stringFromPropertyList:(id) plist format:(NSPropertyListFormat) format errorDescription:(NSString **) errorString;
{ // encode as string
	NSInteger level=0;
	switch(format) {
		case NSPropertyListXMLFormat_v1_0: {
			NSMutableString *s=[NSMutableString stringWithCapacity:300];
			[s appendFormat:@"<?xml %@?>\n", @"version=\"1.0\" ecnoding=\"UTF-8\""];
			[s appendFormat:@"<!DOCTYPE %@>\n", @"plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\""];
			[s appendFormat:@"<plist version=\"%@\">\n", @"1.0"];
			if(![self _appendStringTo:s fromXMLPropertyListElement:plist errorDescription:errorString])
				return nil;
			[s appendString:@"</plist>\n"];
			return s;
		}
		case NSPropertyListJSONFormat: level=INT_MIN;
		case NSPropertyListJSONPrettyPrintedFormat: {
			NSMutableString *s=[NSMutableString stringWithCapacity:300];
			if(![self _appendStringTo:s fromJSONPropertyListElement:plist level:level errorDescription:errorString])
				return nil;
			return s;
		}
		default:
			break;
	}
	if(errorString)
		*errorString=@"Invalid format";
	return nil;
}

+ (BOOL) propertyList:(id) plist isValidForFormat:(NSPropertyListFormat) format;
{
	NSString *err;
	id o;
	NSPropertyListFormat fmt=format;	// copy
	NSAutoreleasePool *arp=[NSAutoreleasePool new];	// creates any temporary objects
	// could also/better check first handful characteres...
	o=[self propertyListFromData:plist mutabilityOption:NSPropertyListImmutable format:&fmt errorDescription:&err];
	[err autorelease];
	[arp release];	// and release
	if(!o)
		return NO;  // no - does not load
	// check if fmt == format!
	return YES;
}

+ (id) propertyListFromData:(NSData *) data
		   mutabilityOption:(NSPropertyListMutabilityOptions) opt
					 format:(NSPropertyListFormat *) format
		   errorDescription:(NSString **) errorString;
{
	NSPropertyListFormat fmt;
	NSString *dummy;
	NSXMLParser *p;
	_NSXMLPropertyList *root;
	id plist=nil;
	char *bytes;
	unsigned short bom;
	unsigned len;
	NSString *str;
	NSScanner *sc;
	unsigned int loc;
#if 0
	NSLog(@"propertyListFromData %u bytes", [data length]);
#endif
	if(data == nil || ![data isKindOfClass:[NSData class]])
		{
		*errorString=@"nil data or not kind of NSData";
		return nil;
		}
	if(!format) format=&fmt;	// dummy return
	if(!errorString) errorString=&dummy;
	*errorString=nil;   // default to being successful
	bytes=(char *) [data bytes];
	len=[data length];
	if(len > 6 && strncmp(bytes, "bplist", 6) == 0)
		{ // should be a binary property list
#if 0
		NSLog(@"propertyListFromData try binary format");
#endif
		NS_DURING
			plist=[_NSBinaryPropertyList _plistFromBinaryData:data mutabilityOption:opt];	// decode
#if 0
			NSLog(@"propertyListFromData found binary format: %@", plist);
#endif
		NS_HANDLER
#if 1
			NSLog(@"Exception while reading binary Plist: %@ - %@", [localException name], [localException reason]);
#endif
			*errorString=@"NSData is not a binary Property List";
			return nil; // some error occurred - can't unarchive
		NS_ENDHANDLER
		if(plist)
			{
			*format=NSPropertyListBinaryFormat_v1_0;
			return plist;	// binary list decoded
			}
		}
	if(len > 6 && strncmp(bytes, "<?xml ", 6) == 0)
		{ // can be an XML property list
#if 0
		NSLog(@"propertyListFromData try XML format");
#endif
		p=[[NSXMLParser alloc] initWithData:data];	// will not be needed any more when done
		root=[_NSXMLPropertyList new];
		[root setMutabilityOption:opt];	// will be passed down to sub-elements
		[p setDelegate:root];
		if([p parse])
			{ // ok, was XML
			*format=NSPropertyListXMLFormat_v1_0;
#if 0
			NSLog(@"propertyListFromData found XML format: %@", [root objectValue]);
#endif
			[p release];
			[root autorelease];
#if 0
				// TEST to check if we can read this data into a NSXMLDocument
				NSError *err=nil;
				NS_DURING
				NSLog(@"NSXMLDocument = %@ err = %@", [[[NSXMLDocument	alloc] initWithData:data options:0 error:&err] autorelease], err);
				NS_HANDLER
				NSLog(@"NSXMLDocument exception %@", localException);
				NS_ENDHANDLER
				abort();
#endif
			return [root objectValue];
			}
		[p release];
		[root release];
		}
#if 0
	NSLog(@"propertyListFromData try OpenStep/StringsFile format: %@", data);
#endif
	if([data length] >= 2 && ([data getBytes:&bom length:sizeof(bom)], (bom == 0xfeff || bom == 0xfffe)))
		str=[[[NSString alloc] initWithData:data encoding:NSUnicodeStringEncoding] autorelease];
	else
		str=[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
#if 0
	NSLog(@"OpenStep/StringsFile str %@", str);
#endif
	sc=[NSScanner scannerWithString:str];
	[sc setCharactersToBeSkipped:nil];	// skip nothing
	[sc setCaseSensitive:YES];	// makes string compares a little faster
	[sc propertyListSkipSpaceAndComments];
	loc=[sc scanLocation];
	if([sc scanString:@"[" intoString:NULL] || [sc scanString:@"{" intoString:NULL])
		{ // try JSON array / object on top level
		[sc setScanLocation:loc];
		plist=[sc propertyListScanJSONElement:opt errorDescription:errorString];
#if 0
		if(!plist)
			NSLog(@"JSON error: %@ %@", *errorString, [[sc string] substringFromIndex:[sc scanLocation]]);
#endif
		// FIXME: should we accept a trailing ";" ?
		fmt=NSPropertyListJSONFormat;
		}
	if(!plist && [sc scanString:@"(" intoString:NULL])
		{ // try array on top level
			fmt=NSPropertyListOpenStepFormat;
			[sc setScanLocation:loc];
			plist=[sc propertyListScanPropertyListElement:opt errorDescription:errorString];
		}
	// can/should we allow <data> on top level?
	if(!plist)
		{ // try top level dictionary with or without braces
			fmt=NSPropertyListOpenStepFormat;
			plist=[sc propertyListScanPropertyListDictionary:opt errorDescription:errorString withBrace:[sc scanString:@"{" intoString:NULL]];
		}
	if(plist)
		{ // has parsed something
		[sc propertyListSkipSpaceAndComments];
		if(![sc isAtEnd])
			{
			*errorString=[NSString stringWithFormat:@"found extra elements before end of file: %@", plist];
			return nil;
			}
#if 0
		NSLog(@"propertyListFromData found OpenStep format: %@", plist);
#endif
		if(plist)
			*format=fmt;
		return plist;
		}
#if 0
	NSLog(@"openstep error %@", *errorString);
#endif
	if(!*errorString)
		*errorString=@"unknown file format";
	return nil;	// can't determine format / is not an OpenStep or StingsFile format
}

// should we swap the roles to avoid converting string to data and back again?

+ (id) _propertyListFromString:(NSString *) string mutabilityOption:(NSPropertyListMutabilityOptions) opt
						format:(NSPropertyListFormat *) format errorDescription:(NSString **) errorString;
{ // non-standard function for convenience
	return [self propertyListFromData:[string dataUsingEncoding:NSUTF8StringEncoding]
					 mutabilityOption:opt
							   format:format
					 errorDescription:errorString];
}

@end
