/*
 NSString.m

 Implementation of string class.

 Copyright (C) 1995, 1996, 1997, 1998 Free Software Foundation, Inc.

 Author:	Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	January 1995
 Unicode: Stevo Crvenkovski <stevo@btinternet.com>
 Date:	February 1997
 Update:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
 Date:	October 1998
 mySTEP:	Felipe A. Rodriguez <far@pcmagic.net>
 Date:	Mar 1999
 mySTEP:	H. Nikolaus Schaller <hns@computer.org>
 Date:	Aug 2003, Feb 2004

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSData.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSPropertyList.h>

#import "NSPrivate.h"
#import "Unicode.h"

extern int vasprintf(char **__ptr, const char *__f, va_list __arg);

#ifdef __APPLE__
// this makes it compile - but not work on a Mac
void *_NXConstantStringClassReference;

@implementation NSSimpleCString
@end

//@implementation NXConstantString
//@end

#endif

#define MAXDEC 18	// used for decompose and hash

NSString *NSParseErrorException=@"NSParseErrorException";

//*****************************************************************************
//
// 		GSSequence
//
//*****************************************************************************

@interface GSSequence : NSObject
{
	unichar *_uniChars;
@public
	int _count;
	BOOL _normalized;
}

+ (GSSequence*) sequenceWithString:(NSString*)aString range:(NSRange)aRange;
- (id) initWithString:(NSString*)string range:(NSRange)aRange;

- (NSString *) description;
- (NSString *) string;
- (GSSequence *) decompose;
- (GSSequence *) order;
- (unsigned int) hash;
- (GSSequence *) lowercase;
- (GSSequence *) uppercase;
- (BOOL) isEqual:(GSSequence *)aSequence;
- (NSComparisonResult) compare:(GSSequence *)aSequence;

@end

@implementation GSSequence

+ (GSSequence *) sequenceWithString:(NSString*)aString range:(NSRange)aRange
{
	return [[[self allocWithZone:NSDefaultMallocZone()] initWithString: aString range: aRange] autorelease];
}

- (id) initWithString:(NSString*)string range:(NSRange)aRange
{
	int stringLength = [string length];
	if(aRange.location > stringLength)
		[NSException raise: NSRangeException format:@"Invalid location."];
	_count = aRange.length;
	if(_count > (stringLength - aRange.location))
		[NSException raise:NSRangeException format:@"Invalid location+length"];
	OBJC_MALLOC(_uniChars, unichar, _count+1);
	[string getCharacters:_uniChars range:aRange];
	_uniChars[_count] = (unichar)0;	// 0-terminate
	return self;
}

- (void) dealloc
{
	if(_uniChars)
		OBJC_FREE(_uniChars);
	[super dealloc];
}

- (NSString *) description											// debug
{
#if 0
	unichar *point = _uniChars;

	while(*point)
		printf("%X ",*point++);
	printf("\n");

	return @"";
#endif
	return @"GSSequence";
}

- (NSString *) string
{
	return [NSString stringWithCharacters:_uniChars length:_count];
}

- (GSSequence *) decompose
{
	unichar *buffer[2], *sbuf;
	unichar *spoint, *tpoint;
	BOOL done;
	int slen;
	int tBuf=0;

	if (_count == 0)
		return self;	// nothing to decompose
						// FIXME: we could make the decomposition buffers static and resize if needed
	// to avoid alloc/dealloc
	OBJC_MALLOC(buffer[0], unichar, _count * MAXDEC);
	OBJC_MALLOC(buffer[1], unichar, _count * MAXDEC);
	spoint = sbuf = _uniChars;
	slen = _count;	// source length
	tpoint = buffer[tBuf];

	while(YES) { // copy until we have nothing more to decompose
		unichar *send = sbuf + slen;
		done = YES;
		while(spoint < send)
			{
			unichar *dpoint = uni_is_decomp(*spoint);
			if(!dpoint)
				*tpoint++ = *spoint;	// can't decompose
			else
				{ // replace by decomposed sequence
					while(*dpoint)
						*tpoint++ = *dpoint++;
					done = NO;
				}
			spoint++;
			}
		slen = tpoint - buffer[tBuf];	// how much did we write?
		if(done)
			break;
		spoint = sbuf = buffer[tBuf];	// take current target buffer as new source
		tBuf = 1-tBuf;	// swap buffers
		tpoint = buffer[tBuf];	// and write to new target buffer
	}

	if(sbuf != _uniChars)
		{ // did decompose anything
			OBJC_REALLOC(_uniChars, unichar, slen+1);	// reallocate to real length
			_count = slen;
			memcpy(_uniChars, buffer[tBuf], sizeof(unichar)*_count);
			_uniChars[_count] = (unichar)0;
		}
	OBJC_FREE(buffer[0]);
	OBJC_FREE(buffer[1]);
	return self;
}

- (GSSequence *) order
{
	unichar *first, *second,tmp;
	int count;
	BOOL notdone;

	if(_count > 1)
		do
			{
			notdone = NO;
			first = _uniChars;
			second = first+1;
			for(count = 1; count < _count; count++)
				{
				if(uni_cop(*second))
					{
					if(uni_cop(*first) > uni_cop(*second))
						{
						tmp = *first;
						*first = *second;
						*second = tmp;
						notdone = YES;
						}
					if(uni_cop(*first) == uni_cop(*second))
						{
						if(*first > *second)
							{
							tmp = *first;
							*first = *second;
							*second = tmp;
							notdone = YES;
							}
						}
					}
				first++;
				second++;
				}
			}
	while(notdone);

	return self;
}

- (unsigned int) hash
{
	int count;
	unsigned int ret=0;
	for(count=0; count<_count; count++)
		ret = (ret << 5) + ret + _uniChars[count];
	return ret;
}

- (GSSequence *) lowercase
{
	unichar *s;
	int count;
	GSSequence *seq = [GSSequence alloc];

	OBJC_MALLOC(s, unichar, _count+1);
	for(count = 0; count < _count; count++)
		s[count] = uni_tolower(_uniChars[count]);
	s[_count] = (unichar)0;

	seq->_count = _count;
	seq->_uniChars = s;

	return [seq autorelease];
}

- (GSSequence *) uppercase
{
	unichar *s;
	int count;
	GSSequence *seq = [GSSequence alloc];

	OBJC_MALLOC(s, unichar, _count+1);
	for(count = 0; count < _count; count++)
		s[count] = uni_toupper(_uniChars[count]);
	s[_count] = (unichar)0;

	seq->_count = _count;
	seq->_uniChars = s;

	return [seq autorelease];
}

- (BOOL) isEqual:(GSSequence*)aSequence
{
	return [self compare:aSequence] == NSOrderedSame;
}

- (NSComparisonResult) compare:(GSSequence*)aSequence
{
	int i, end;													// Inefficient

	if(!_normalized)
		{
		[[self decompose] order];
		_normalized = YES;
		}
	if(!aSequence->_normalized)
		{
		[[aSequence decompose] order];
		aSequence->_normalized = YES;
		}												// determine shortest
														// sequence's end
	end = (_count < aSequence->_count) ? _count : aSequence->_count;

	for (i = 0; i < end; i ++)
		{
		if (_uniChars[i] < aSequence->_uniChars[i])
			return NSOrderedAscending;
		if (_uniChars[i] > aSequence->_uniChars[i])
			return NSOrderedDescending;
		}

	if(_count < aSequence->_count)
		return NSOrderedAscending;

	return (_count > aSequence->_count) ? NSOrderedDescending : NSOrderedSame;
}

@end

//*****************************************************************************
//
// 		NSString
//
//*****************************************************************************

@implementation NSString

// Class global variables
static Class _nsStringClass;							// Abstract superclass.
static Class _constantStringClass;
static Class _strClass;									// For unichar strings.
static Class _mutableStringClass;
static Class _cStringClass;								// For cString's
static NSStringEncoding __cStringEncoding=NSASCIIStringEncoding;	// default encoding

static unsigned (*_strHashImp)();
static SEL csInitSel;
static SEL msInitSel;
static IMP csInitImp;					// designated initialiser for cString

//	Cache commonly used character sets along with methods to check membership.
static NSString *pathSepString = @"/";
static NSCharacterSet *pathSeps = nil;

SEL __charIsMem;
NSCharacterSet *__hexDgts = nil;
NSCharacterSet *__quotes = nil;
NSCharacterSet *__whitespce = nil;

BOOL (*__hexDgtsIMP)(id, SEL, unichar) = 0;
BOOL (*__whitespceIMP)(id, SEL, unichar) = 0;
BOOL (*__quotesIMP)(id, SEL, unichar) = 0;

+ (void) initialize
{
#if 0
	fprintf(stderr, "NSString +initialize\n");
#endif
	if (self == [NSString class])
		{
		NSCharacterSet *s;

		__cStringEncoding = GSDefaultCStringEncoding();
		__charIsMem = @selector(characterIsMember:);
		_nsStringClass = self;
		_constantStringClass = [@"" class];
		_strClass = [GSString class];
		_cStringClass = [GSCString class];
		_mutableStringClass = [GSMutableString class];

		// Cache some method implementations for quick access later.
		_strHashImp = (unsigned (*)())
		[_nsStringClass instanceMethodForSelector: @selector(hash)];
		if(!_strHashImp)
			NSLog(@"_strHashImp not defined");
		csInitSel = @selector(initWithCStringNoCopy:length:freeWhenDone:);
		msInitSel = @selector(initWithCapacity:);
		csInitImp = [GSCString instanceMethodForSelector: csInitSel];

		__hexDgts = [NSCharacterSet characterSetWithCharactersInString:
					 @"0123456789abcdef"];
		[__hexDgts retain];
		__hexDgtsIMP = (BOOL(*)(id,SEL,unichar)) [__hexDgts methodForSelector:
												  __charIsMem];
		if(!__hexDgtsIMP)
			NSLog(@"__hexDgtsIMP not defined");

		s = [NSMutableCharacterSet characterSetWithCharactersInString:
			 @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz$./_"];
		[(NSMutableCharacterSet *)s invert];
		__quotes = [s copy];
		__quotesIMP = (BOOL(*)(id,SEL,unichar))
		[__quotes methodForSelector: __charIsMem];
		if(!__quotesIMP)
			NSLog(@"__quotesIMP not defined");
#if 0
		__whitespce = [NSCharacterSet whitespaceAndNewlineCharacterSet];
#else
		__whitespce =[NSMutableCharacterSet characterSetWithCharactersInString:
					  @" \t\r\n\f\b"];
#endif
		[__whitespce retain];
		__whitespceIMP = (BOOL(*)(id,SEL,unichar))
		[__whitespce methodForSelector: __charIsMem];
		if(!__whitespceIMP)
			NSLog(@"__whitespceIMP not defined");
#if defined(__WIN32__) || defined(_WIN32)
		pathSeps = [NSCharacterSet characterSetWithCharactersInString: @"/\\"];
#else
		pathSeps = [NSCharacterSet characterSetWithCharactersInString: @"/"];
#endif
		[pathSeps retain];
		}
}

+ (id) allocWithZone:(NSZone *) z
{
	return (NSString *) NSAllocateObject(_strClass, 0, z);
}

+ (id) string		{ return [[self new] autorelease]; }

+ (id) stringWithString:(NSString*)aString
{
	return [[[self alloc] initWithString: aString] autorelease];
}

+ (id) stringWithCharacters:(const unichar*)chars length:(NSUInteger)length
{
#if 0
	NSLog(@"%@ stringWithCharacters:%p length:%u", NSStringFromClass([self class]), chars, length);
#endif
	return [[[self alloc] initWithCharacters:chars length:length] autorelease];
}

+ (id) stringWithCString:(const char*)bytes
{
	return [[[GSCString alloc] initWithCString:bytes] autorelease];
}

+ (id) stringWithCString:(const char*)bytes length:(unsigned int)len
{
	return [[[GSCString alloc] initWithCString:bytes length:len] autorelease];
}

+ (id) stringWithContentsOfFile:(NSString *)path
{
	return [[[self alloc] initWithContentsOfFile: path] autorelease];
}

+ (id) stringWithContentsOfURL:(NSURL *)url
{
	return [[[self alloc] initWithContentsOfURL: url] autorelease];
}

+ (id) stringWithCString:(const char *)cString
				encoding:(NSStringEncoding)enc;
{
	return [[[self alloc] initWithCString:cString encoding:enc] autorelease];
}

+ (id) stringWithContentsOfFile:(NSString *)path
					   encoding:(NSStringEncoding)enc
						  error:(NSError **)error;
{
	return [[[self alloc] initWithContentsOfFile:path encoding:enc error:error] autorelease];
}

+ (id) stringWithContentsOfFile:(NSString *)path
				   usedEncoding:(NSStringEncoding *)enc
						  error:(NSError **)error;
{
	return [[[self alloc] initWithContentsOfFile:path usedEncoding:enc error:error] autorelease];
}

+ (id) stringWithContentsOfURL:(NSURL *)url
					  encoding:(NSStringEncoding)enc
						 error:(NSError **)error;
{
	return [[[self alloc] initWithContentsOfURL:url encoding:enc error:error] autorelease];
}

+ (id) stringWithContentsOfURL:(NSURL *)url
				  usedEncoding:(NSStringEncoding *)enc
						 error:(NSError **)error;
{
	return [[[self alloc] initWithContentsOfURL:url usedEncoding:enc error:error] autorelease];
}


+ (id) stringWithFormat:(NSString*)format,...
{
	va_list ap;
	id ret;
	va_start(ap, format);
	ret = [[[self alloc] initWithFormat:format arguments:ap] autorelease];
	va_end(ap);
	return ret;
}

+ (NSString *) localizedStringWithFormat:(NSString *)format, ...
{
	va_list ap;
	id ret;
	va_start(ap, format);
	ret = [[[self alloc] initWithFormat:format locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] arguments:ap] autorelease];
	va_end(ap);
	return ret;
}

+ (NSString *) _stringWithUTF8String:(const char *) bytes length:(NSUInteger) len;
{
	return [[[self alloc] _initWithUTF8String:bytes length:len] autorelease];
}

+ (id) stringWithUTF8String:(const char *) bytes;
{
	return [[[self alloc] _initWithUTF8String:bytes length:strlen(bytes)] autorelease];
}

+ (NSString*) localizedNameOfStringEncoding:(NSStringEncoding)encoding
{
	id ourbundle = [NSBundle bundleForClass:[self class]];
	id ourname = GSGetEncodingName(encoding);
	return [ourbundle localizedStringForKey:ourname value:ourname table:nil];
}

+ (NSStringEncoding) defaultCStringEncoding { return __cStringEncoding; }
+ (const NSStringEncoding *) availableStringEncodings	{ return _availableEncodings(); }

- (id) initWithCharactersNoCopy:(unichar*)chars
						 length:(unsigned int)length
				   freeWhenDone:(BOOL)flag		{ return SUBCLASS }

- (id) initWithCStringNoCopy:(char*)byteString
					  length:(unsigned int)length
				freeWhenDone:(BOOL)flag			{ return SUBCLASS }

- (id) initWithCharacters:(const unichar*)chars length:(NSUInteger)length
{
	unichar	*s = objc_malloc(sizeof(unichar)*length);
	if(!s)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	if(chars)
		memcpy(s, chars, sizeof(unichar)*length);
#if 0
	NSLog(@"%@ initWithCharacters:%p length:%u (s=%p)", NSStringFromClass([self class]), chars, length, s);
#endif
	return [self initWithCharactersNoCopy:s length:length freeWhenDone:YES];
}

- (id) initWithCString:(const char *)cstring
			  encoding:(NSStringEncoding)enc;
{
	return [self initWithData:[NSData dataWithBytes:cstring length:strlen(cstring)] encoding:enc];
}

- (id) initWithBytes:(const void *)bytes
			  length:(NSUInteger)length
			encoding:(NSStringEncoding)enc;
{
	return [self initWithData:[NSData dataWithBytes:bytes length:length] encoding:enc];
}

- (id) initWithBytesNoCopy:(void *)bytes
					length:(NSUInteger)length
				  encoding:(NSStringEncoding)enc
			  freeWhenDone:(BOOL)flag;
{
	return [self initWithData:[NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:flag] encoding:enc];
}

- (id) initWithCString:(const char*) byteString length:(unsigned int) length
{
	char *s = objc_malloc(length + 1);
	if(!s)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	if(byteString)
		memcpy(s, byteString, length);
	s[length] = '\0';
	return [self initWithCStringNoCopy:s length:length freeWhenDone:YES];
}

- (id) initWithCString:(const char*) byteString
{
	int length = (byteString ? strlen(byteString) : 0);
	char *s = objc_malloc(length + 1);
	if(!s)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	if(byteString)
		memcpy(s, byteString, length);
	s[length] = '\0';
	return [self initWithCStringNoCopy:s length:length freeWhenDone:YES];
}

- (id) _initWithUTF8String:(const char *) bytes length:(unsigned) len;
{
	return [self initWithData:[NSData dataWithBytesNoCopy:(char *) bytes length:len freeWhenDone:NO] encoding:NSUTF8StringEncoding];
}

- (id) initWithUTF8String:(const char *) bytes;
{
	return [self _initWithUTF8String:bytes length:strlen(bytes)];
}

// - (id) init; { SUPERCLASS; }

- (id) initWithString:(NSString *) string
{
	unsigned l = [string length];
	unichar	*s = objc_malloc(sizeof(unichar) * l);
	if(!s)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	[string getCharacters:s];
	return [self initWithCharactersNoCopy:s length:l freeWhenDone:YES];
}

- (id) initWithFormat:(NSString*)format, ...
{
	va_list ap;
	va_start(ap, format);
	self = [self initWithFormat:format locale:nil arguments:ap];
	va_end(ap);
	return self;
}

- (id) initWithFormat:(NSString *) format arguments:(va_list) arg_list
{
	return [self initWithFormat:format locale:nil arguments:arg_list];
}

- (id) initWithFormat:(NSString*)format
			   locale:(NSDictionary*)locale, ...
{
	va_list ap;
	va_start(ap, locale);
	self = [self initWithFormat:format locale:locale arguments:ap];
	va_end(ap);
	return self;
}

- (id) initWithFormat:(NSString*)format
			   locale:(NSDictionary*)locale
			arguments:(va_list)arg_list
{
	const char *format_cp = [format UTF8String];
	int format_len = strlen (format_cp);
	char *format_cp_copy = objc_malloc(format_len+1);	// buffer for a mutable copy of the format string
	char *format_to_go = format_cp_copy;				// pointer into the format string while processing
	NSMutableString *result=[[NSMutableString alloc] initWithCapacity:2*format_len+20];	// this assumes some minimum result size
	[self release];	// we return a (mutable!) replacement object - to be really correct, we should autorelease the result and return [self initWithString:result];
	if(!format_cp_copy)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	strcpy(format_cp_copy, format_cp);		// make local copy for tmp editing
											//	fprintf(stderr, "fmtcopy=%p\n", format_cp_copy);
											//	fprintf(stderr, "result=%p\n", result);

	// FIXME: somehow handle %S and other specifiers!

	while(YES)
		{ // Loop once for each `%@' in the format string
			char *atsign_pos;				// points to a location of an %@ inside format_cp_copy
			char *formatter_pos;			// a position for formatter
			char *buffer;					// vasprintf() buffer return
			int len;						// length of vasprintf() result
			id arg;
			int mode=0;
			for(atsign_pos=format_to_go; *atsign_pos != 0; atsign_pos++)
				{ // scan for special formatters that can't be handled by vsfprint
					if(atsign_pos[0] == '%')
						{
						switch(atsign_pos[1]) {
							case '@':
							case 'C':
								mode=atsign_pos[1];
								*atsign_pos = '\0';		// tmp terminate the string before the next `%@'
								break;
							default:
								continue;
						}
						break;
						}
				}
#if 0
			fprintf(stderr, "fmt2go=%s\n", format_to_go);
#endif
			if(*format_to_go)
				{ // if there is anything to print...
					len=vasprintf(&buffer, format_to_go, arg_list);	// Print the part before the '%@' - will be malloc'ed
																	//			fprintf(stderr, "buffer=%p\n", buffer);
					if(len > 0)
						[result appendString:[NSString _stringWithUTF8String:buffer length:len]];
					else if(len < 0)
						{ // error
							free(buffer);
							objc_free(format_cp_copy);
							[result release];
							return nil;
						}
					free(buffer);
				}
			if(!mode)
				return result;	// we return a (mutable!) replacement object - to be correct, autorelease the result and return [self initWithString:result];
			while((formatter_pos = strchr(format_to_go, '%')))
				{ // Skip arguments already processed by last vasprintf().
					char *spec_pos; 			// Position of conversion specifier.
					if(*(formatter_pos+1) == '%')
						{
						format_to_go = formatter_pos+2;
						continue;	// skip %%
						}
					// FIXME: somehow handle %C, %S and other new specifiers!
					spec_pos = strpbrk(formatter_pos+1, "dioxXucsfeEgGpn");	// Specifiers from K&R C 2nd ed.
					if(*(spec_pos - 1) == '*')
						{
#if 0
						fprintf(stderr, " -initWithFormat: %%* specifier found\n");
#endif
						(void) va_arg(arg_list, int);	// handle %*s, %.*f etc.
						}
					// FIXME: handle %*.*s, %*.123s
#if 0
					fprintf(stderr, "spec=%c\n", *spec_pos);
#endif
					switch (*spec_pos) {
						case 'd': case 'i': case 'o':
						case 'x': case 'X': case 'u': case 'c':
							(void) va_arg(arg_list, int);
							break;
						case 's':
							(void) va_arg(arg_list, char *);
							break;
						case 'f': case 'e': case 'E': case 'g': case 'G':
							(void) va_arg(arg_list, double);
							break;
						case 'p':
							(void) va_arg(arg_list, void *);
							break;
						case 'n':
							(void) va_arg(arg_list, int *);
							break;
						case '\0':							// Make sure loop exits on
							spec_pos--;						// next iteration
							break;
						default:
							fprintf(stderr, "NSString -initWithFormat:... unknown format specifier %%%c\n", *spec_pos);
					}
					format_to_go = spec_pos+1;
				}
			switch(mode) {
				case '@': {
					arg=(id) va_arg(arg_list, id);
#if 0
					fprintf(stderr, "arg.1=%p\n", arg);
#endif
					if(arg && ![arg isKindOfClass:[NSString class]])
						{ // not yet a string
#if 0
							fprintf(stderr, " class=%s\n", [NSStringFromClass([arg class]) UTF8String]);
#endif
							if(locale && [arg respondsToSelector:@selector(descriptionWithLocale:)])
								arg=[arg descriptionWithLocale:locale];
							else
								arg=[arg description];
#if 0
							fprintf(stderr, " new class=%s\n", [NSStringFromClass([arg class]) UTF8String]);
#endif
						}
					if(!arg)
						arg=@"<nil>";	// nil object or description
					break;
				}
				case 'C': {
					unichar c=va_arg(arg_list, int);
					arg=[NSString stringWithCharacters:&c length:1];	// single character
					break;
				}
				default:
					arg=@"formatter error";
			}
#if 0
			fprintf(stderr, "arg.2=%p\n", arg);
#endif
			[result appendString:arg];
			format_to_go = atsign_pos + 2;				// Skip over this `%@', and look for another one.
		}
}

- (id) _initWithData:(NSData *)data;
{ // deduct encoding from data
	NSStringEncoding e;
	const unsigned char *t = [data bytes];
	static char xml[]="<?xml version=\"1.0\" encoding=\"UTF-8\"";
	if(t == NULL)
		return nil;
	if((t[0]==0xFF) && (t[1]==0xFE))
		e = NSUnicodeStringEncoding;
	else if((t[1]==0xFF) && (t[0]==0xFE))
		e = NSUnicodeStringEncoding;
	else if(memcmp(t, xml, sizeof(xml)-1) == 0) // check for verbatim header
		{
#if 0
		NSLog(@"assume UTF-8 for xml header: %s", xml);
#endif
		e = NSUTF8StringEncoding;
		}
	else
		e = __cStringEncoding;
#if 0
	NSLog(@"enc=%d data=%@", e, data);
#endif
	return [self initWithData:data encoding:e];
}

- (id) initWithData:(NSData *)data encoding:(NSStringEncoding)encoding
{
	unidecoder d;
	int len;
	unichar *s, *sp;
	unsigned char *b, *end;
	len=[data length];
	sp=s=objc_malloc(sizeof(*s)*len);	// assume that as max. length
	if(!s)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	b=(unsigned char *) [data bytes];
	end=b+len;
	if(encoding == NSUnicodeStringEncoding)
		{ // check for byte order marker
			if((b[0] == 0xFF) & (b[1] == 0xFE))
				encoding=NSSwappedUnicodeStringEncoding, b+=2;
			else if((b[0] == 0xFE) & (b[1] == 0xFF))
				b+=2;	// standard unicode
		}
	d=decodeuni(encoding);		// get appropriate decoder function
	if(!d)
		{
		objc_free(s);
		NSLog(@"initWithData:encoding: encoding %lu undefined", (unsigned long)encoding);
		[self release];
		return nil;
		}
	while(b < end)
		*sp++=(*d)(&b);	// get characters
	NSAssert(sp-s <= sizeof(*s)*len, @"buffer overflow");
	return [self initWithCharactersNoCopy:s length:sp-s freeWhenDone:YES];
}

- (NSUInteger) maximumLengthOfBytesUsingEncoding:(NSStringEncoding)enc;
{ // estimate depending on encoding (make it long enough for all cases) in O(1) time
	if(enc == NSUnicodeStringEncoding)
		return 2*[self length]+2+1;
	if(enc == NSUTF8StringEncoding)
		return 6*[self length];
	return [self length];
}

- (NSData *) dataUsingEncoding:(NSStringEncoding)encoding allowLossyConversion:(BOOL)flag
{ // FIXME: incomplete
	uniencoder e=encodeuni(encoding);		// get appropriate encoder function
	unsigned long len;
	unsigned char *buff, *bp;
	int i;
	if(!e)
		return nil;
	if(_count == 0)
		return [NSData data];	// encode empty string
#if 0 && defined(__mySTEP__)
	free(malloc(8192));
#endif
	len=[self maximumLengthOfBytesUsingEncoding:encoding];
#if 0 && defined(__mySTEP__)
	free(malloc(8192));
#endif
	bp=buff=(unsigned char*) objc_malloc(len);
	if(!buff)
		[NSException raise: NSMallocException format: @"Unable to allocate buffer"];
	if(encoding == NSUnicodeStringEncoding)
		{ // write our default byte order mark
			*bp++=0xFE;
			*bp++=0xFF;
		}
	for(i = 0; i < _count; i++)
		{
		if(!(*e)([self characterAtIndex:i], &bp) && !flag)
			{ // conversion error
				objc_free(buff);
				[NSException raise:NSCharacterConversionException format:@"can't convert due to unconvertible characters: %@", self];	// conversion error
				return nil;
			}
		}
	NSAssert(bp <= buff+len, @"buffer overflow");
#if 0 && defined(__mySTEP__)
	free(malloc(8192));
#endif
	return [NSData dataWithBytesNoCopy:buff length:bp-buff];	// become owner
}

- (NSData*) dataUsingEncoding:(NSStringEncoding)encoding
{
	return [self dataUsingEncoding:encoding allowLossyConversion:NO];
}

- (BOOL) canBeConvertedToEncoding:(NSStringEncoding)encoding
{
	return [self dataUsingEncoding:encoding allowLossyConversion:NO] ? YES: NO;
}

- (NSStringEncoding) fastestEncoding			{ SUBCLASS return 0; }
- (NSStringEncoding) smallestEncoding			{ SUBCLASS return 0; }

- (const char *) cStringUsingEncoding:(NSStringEncoding)enc;
{
	return [[self dataUsingEncoding:enc allowLossyConversion:NO] _autoFreeBytesWith0:YES];	// convert and return 0-terminated string
}

- (BOOL) getCString:(char *)buffer maxLength:(NSUInteger)maxLength encoding:(NSStringEncoding)enc;
{ // encode to buffer
	uniencoder e=encodeuni(enc);		// get appropriate encoder function
	unsigned char *bp;
	int i;
	if(!e)
		return NO;
	bp=(unsigned char *) buffer;
	for(i = 0; i < _count; i++)
		{
		unsigned char *end=(unsigned char *) buffer+MIN(maxLength, 6*_count)-(enc==NSUTF8StringEncoding?6:1);
		if(bp >= end)
			return NO;	// not enough room
		if(!(*e)([self characterAtIndex:i], &bp))
			return NO;	// conversion error
		}
	return YES;	// ok
}

- (id) initWithContentsOfFile:(NSString*)path
{
	return [self _initWithData:[NSData dataWithContentsOfFile: path]];	// deduct encoding from contents
}

- (id) initWithContentsOfFile:(NSString *)path
					 encoding:(NSStringEncoding)enc
						error:(NSError **)error;
{
	// load if specified encoding fits
	return NIMP;
}

- (id) initWithContentsOfFile:(NSString *)path
				 usedEncoding:(NSStringEncoding *)enc
						error:(NSError **)error;
{
	// try different encodings
	return NIMP;
}

- (id) initWithContentsOfURL:(NSURL*)url
{
	return [self _initWithData:[NSData dataWithContentsOfURL: url]];	// deduct encoding from contents
}

- (id) initWithContentsOfURL:(NSURL *)url
					encoding:(NSStringEncoding)enc
					   error:(NSError **)error;
{
	if(error)
		*error=nil;
	return [self initWithData:[NSData dataWithContentsOfURL: url] encoding:enc];	// take encoding from arguments
}

- (id) initWithContentsOfURL:(NSURL *)url
				usedEncoding:(NSStringEncoding *)enc
					   error:(NSError **)error;
{
	NSURLRequest *request=[NSURLRequest requestWithURL:url];
	NSURLResponse *response;
	NSData *data=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
	// analyse response for content-type, content-encoding...
	return [self initWithData:data encoding:*enc];	// deduct encoding from content header
}

- (id) mutableCopyWithZone:(NSZone *) z
{
	return [[_mutableStringClass alloc] initWithString:self];
}

- (id) copyWithZone:(NSZone *) z					{ return [self retain]; }
- (NSUInteger) length								{ return _count; }
- (NSString*) description							{ return self; }
- (const char *) cString							{ SUBCLASS return 0; }
- (NSUInteger) cStringLength						{ SUBCLASS return 0; }
- (unichar) characterAtIndex:(NSUInteger)index	{ SUBCLASS return 0; }
- (void) getCharacters:(unichar*)buffer				{ SUBCLASS }
- (void) getCharacters:(unichar*)buffer
				 range:(NSRange)aRange				{ SUBCLASS }

- (void) getCString:(char*)buffer
{
	[self getCString:buffer
		   maxLength:NSMaximumStringLength
			   range:((NSRange){0, _count})
	  remainingRange:NULL];
}

- (void) getCString:(char*)buffer maxLength:(NSUInteger)maxLength
{
	[self getCString:buffer
		   maxLength:maxLength
			   range:((NSRange){0, _count})
	  remainingRange:NULL];
}

- (void) getCString:(char *) buffer
		  maxLength:(NSUInteger) maxLength
			  range:(NSRange) aRange
	 remainingRange:(NSRange *)leftoverRange
{ // FIX ME adjust range for composite sequence
	uniencoder e;
	unsigned char *bp;
	NSUInteger i = aRange.location;
#if OLD
	if(aRange.location > len)
		[NSException raise: NSRangeException format:@"Invalid location."];
	if (aRange.length > (len - aRange.location))
		[NSException raise:NSRangeException format:@"Invalid location+length"];
#endif
	e=encodeuni(__cStringEncoding);		// get appropriate encoder function
#if 0
	NSLog(@"getCString:%p maxLength:%u range:%@ - length=%d, e=%p, %@", buffer, maxLength, NSStringFromRange(aRange), [self length], e, self);
#endif
	if(e)
		{
		unsigned char *end=(unsigned char *) buffer+MIN(maxLength, 6*aRange.length)-(__cStringEncoding==NSUTF8StringEncoding?6:1);	// shouldn't be UTF8!
		bp=(unsigned char *) buffer;
#if 0
		NSLog(@"max %u", end-bp);
#endif
		while(i < NSMaxRange(aRange))
			{
			if(bp >= end)
				[NSException raise:NSCharacterConversionException format:@"can't convert due to missing buffer space: %@", self];	// conversion error
			if(!(*e)([self characterAtIndex:i++], &bp))
				[NSException raise:NSCharacterConversionException format:@"can't getCString due to non-ASCII characters: %@", self];	// conversion error
			}
		}
	else
		[NSException raise:NSCharacterConversionException format:@"invalid default encoding (%d)", __cStringEncoding];	// conversion error
	if(leftoverRange)
		{
		leftoverRange->location=i;
		leftoverRange->length=NSMaxRange(aRange)-i;
		}
}

- (NSUInteger) lengthOfBytesUsingEncoding:(NSStringEncoding)enc;
{ // determine exact length in O(n) time
	uniencoder e=encodeuni(enc);		// get appropriate encoder function
	NSUInteger len=0;
	NSUInteger i;
	unsigned char buf[8], *bp;
	if(!e)
		return 0;	// unknown encoding
	if(enc == NSUnicodeStringEncoding)
		len=2;   // count for room for byte order mark
	for(i = 0; i < _count; i++)
		{
		bp=buf;
		(*e)([self characterAtIndex:i], &bp);
		len+=bp-buf;	// number of characters
		}
	return len;
}

// a little slow because we malloc and copy twice

- (const char *) UTF8String;	{
#if 0 && defined(__mySTEP__)
	free(malloc(8192));
#endif
	return [[self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] _autoFreeBytesWith0:YES]; }
- (const char *) lossyCString;	{ return [[self dataUsingEncoding:__cStringEncoding allowLossyConversion:YES] _autoFreeBytesWith0:YES]; }

- (NSString*) stringByAppendingFormat:(NSString*)format,...
{
	va_list ap;
	NSString *a, *s;
	va_start(ap, format);
	a = [[NSString alloc] initWithFormat:format arguments:ap];
	s = [self stringByAppendingString:a];
	[a release];
	va_end(ap);
	return s;
}

- (NSString *) _unicharString { return self; }	// default

- (NSString*) stringByAppendingString:(NSString*)aString
{
	unsigned otherLength = [aString length];
	unichar *s = objc_malloc((_count + otherLength) * sizeof(unichar));
	if(!s)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	[self getCharacters:s];
	[aString getCharacters: s + _count];
	return [[[[self class] alloc] initWithCharactersNoCopy: s
										   length: _count + otherLength
											  freeWhenDone: YES] autorelease];
}

- (NSArray*) componentsSeparatedByString:(NSString*)separator
{														// Dividing a String
	NSRange search = {0, _count};							// into Substrings
	NSMutableArray *array = [NSMutableArray array];
	NSRange found = [self rangeOfString:separator options:NSLiteralSearch range:search];
	if (!separator)
		[NSException raise: NSInvalidArgumentException format: @"separator is nil"];

	while (found.length)
		{
		search.length = found.location - search.location;
		[array addObject: [self substringWithRange: search]];
		search.location = NSMaxRange(found);
		search.length = _count - search.location;
		found = [self rangeOfString:separator options:0 range:search];
		}

	[array addObject: [self substringWithRange: search]];	// Add the last fragment

	return array;
}

- (NSArray*) componentsSeparatedByCharactersInSet:(NSCharacterSet*)separator
{														// Dividing a String
	NSRange search = {0, _count};							// into Substrings
	NSMutableArray *array = [NSMutableArray array];
	NSRange found = [self rangeOfCharacterFromSet:separator options:NSLiteralSearch range:search];
	if (!separator)
		[NSException raise: NSInvalidArgumentException format: @"separator is nil"];

	while (found.length)
		{
		search.length = found.location - search.location;
		[array addObject: [self substringWithRange: search]];
		search.location = NSMaxRange(found);
		search.length = _count - search.location;
		found = [self rangeOfCharacterFromSet:separator options:0 range:search];
		}
	[array addObject: [self substringWithRange: search]];

	return array;
}

- (NSString*) substringFromIndex:(NSUInteger)index
{
	return [self substringWithRange:((NSRange){index, _count - index})];
}

- (NSString*) substringWithRange:(NSRange)aRange
{
	unichar *buf;

	if (NSMaxRange(aRange) > _count)
		[NSException raise:NSRangeException format:@"Invalid location+length"];
	if (aRange.length == 0)
		return @"";

	buf = objc_malloc(sizeof(unichar) * aRange.length);
	if(!buf)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	[self getCharacters:buf range:aRange];

	return [[[[self class] alloc] initWithCharactersNoCopy: buf
										   length: aRange.length
											  freeWhenDone: YES] autorelease];
}

- (NSString*) substringToIndex:(NSUInteger)index
{
	return [self substringWithRange:((NSRange){0, index})];;
}

- (NSRange) rangeOfCharacterFromSet:(NSCharacterSet*)aSet
{
	return [self rangeOfCharacterFromSet:aSet
								 options:0
								   range:(NSRange){0, _count}];
}

- (NSRange) rangeOfCharacterFromSet:(NSCharacterSet*)aSet
							options:(unsigned int)mask
{
	return [self rangeOfCharacterFromSet:aSet
								 options:mask
								   range:(NSRange){0, _count}];
}

- (NSRange) rangeOfCharacterFromSet:(NSCharacterSet*)aSet
							options:(unsigned int)mask
							  range:(NSRange)aRange
{
	int i = _count, start, stop, step;
	NSRange range;
	unichar (*cImp)(id, SEL, unsigned);
	BOOL (*mImp)(id, SEL, unichar);

	if (aRange.location > i)
		[NSException raise: NSRangeException format:@"Invalid location."];
	if (aRange.length > (i - aRange.location))
		[NSException raise:NSRangeException format:@"Invalid location+length"];

	if ((mask & NSBackwardsSearch) == NSBackwardsSearch)
		{
		start = NSMaxRange(aRange) - 1;
		stop = aRange.location - 1;
		step = -1;
		}
	else
		{
		start = aRange.location;
		stop = NSMaxRange(aRange);
		step = 1;
		}

	range = (NSRange){NSNotFound, 0};
	cImp = (unichar(*)(id,SEL,unsigned))
	[self methodForSelector: @selector(characterAtIndex:)];
	mImp = (BOOL(*)(id,SEL,unichar)) [aSet methodForSelector: __charIsMem];

	for (i = start; i != stop; i += step)
		{
		unichar letter = (unichar)(*cImp)(self,@selector(characterAtIndex:),i);

		if ((*mImp)(aSet, __charIsMem, letter))
			{
			range = (NSRange){i, 1};
			break;
			}	}

	return range;
}

- (NSRange) rangeOfString:(NSString*)string
{
	return [self rangeOfString:string options:NSLiteralSearch range:(NSRange){0, _count}];
}

- (NSRange) rangeOfString:(NSString*)string options:(unsigned int)mask
{
	return [self rangeOfString:string options:mask range:(NSRange){0, _count}];
}

// this method my allocate large amounts of memory!!! => allocates many autoreleased GSSequence objects

- (NSRange) rangeOfString:(NSString *) aString
				  options:(unsigned int) mask
					range:(NSRange) aRange
{
	unsigned int strLength, maxRange = NSMaxRange(aRange);
	unsigned int myIndex;
	unsigned int myEndIndex;
	unichar strFirstCharacter;

	if (maxRange > _count)
		[NSException raise:NSRangeException format:@"Invalid location+length"];
	// Ensure the string
	strLength = [aString length];						// can be found
	if (strLength > aRange.length || strLength == 0)
		return (NSRange){NSNotFound, 0};

	// NSCaseInsensitiveSearch = 1,
	//	NSLiteralSearch			= 2,
	//	NSBackwardsSearch		= 4,
	//	NSAnchoredSearch		= 8

	switch (mask)
	{ //  evaluate lowest 4 bits - others must be 0
		case NSLiteralSearch+NSCaseInsensitiveSearch:
		case NSAnchoredSearch+NSLiteralSearch+NSCaseInsensitiveSearch:
		{						// search forward case insensitive literal
			myIndex = aRange.location;
			myEndIndex = maxRange - strLength;
			strFirstCharacter = [aString characterAtIndex:0];

			if (mask & NSAnchoredSearch)
				myEndIndex = myIndex;

			for (;;)
				{
				unsigned int i = 1;
				unichar myChar = [self characterAtIndex:myIndex];
				unichar strChar = strFirstCharacter;

				for (;;)
					{
					if((myChar != strChar)
					   && (uni_tolower(myChar) != uni_tolower (strChar)))
						break;
					if (i == strLength)
						return (NSRange){myIndex, strLength};
					myChar = [self characterAtIndex:myIndex + i];
					strChar = [aString characterAtIndex:i];
					i++;
					}
				if (myIndex == myEndIndex)
					break;
				myIndex ++;
				}	}
			break;

		case NSBackwardsSearch+NSLiteralSearch+NSCaseInsensitiveSearch:
		case NSAnchoredSearch+NSBackwardsSearch+NSLiteralSearch+NSCaseInsensitiveSearch:
		{						// search backward case insensitive literal
			myIndex = maxRange - strLength;
			myEndIndex = aRange.location;
			strFirstCharacter = [aString characterAtIndex:0];

			if (mask & NSAnchoredSearch)
				myEndIndex = myIndex;

			for (;;)
				{
				unsigned int i = 1;
				unichar myChar = [self characterAtIndex:myIndex];
				unichar strChar = strFirstCharacter;

				for (;;)
					{
					if ((myChar != strChar)
						&& ((uni_tolower (myChar)
							 != uni_tolower (strChar))))
						break;
					if (i == strLength)
						return (NSRange){myIndex, strLength};
					myChar = [self characterAtIndex:myIndex + i];
					strChar = [aString characterAtIndex:i];
					i++;
					}
				if (myIndex == myEndIndex)
					break;
				myIndex --;
				}	}
			break;

		case NSLiteralSearch:
		case NSAnchoredSearch+NSLiteralSearch:
		{										// search forward literal
			SEL charAtIndexSEL = @selector(characterAtIndex:);
			unichar (*aStringIMP)(id, SEL, unsigned);
			unichar (*selfIMP)(id, SEL, unsigned);

			aStringIMP = (unichar(*)(id,SEL,unsigned))
			[aString methodForSelector: charAtIndexSEL];
			selfIMP = (unichar(*)(id,SEL,unsigned))
			[self methodForSelector: charAtIndexSEL];

			myIndex = aRange.location;
			myEndIndex = maxRange - strLength;
			strFirstCharacter = (*aStringIMP)(aString, charAtIndexSEL, 0);

			if (mask & NSAnchoredSearch)
				myEndIndex = myIndex;

			for (;;)
				{
				unsigned int i = 1;
				unichar myChar = (*selfIMP)(self, charAtIndexSEL,myIndex);
				unichar strChar = strFirstCharacter;

				for (;;)
					{
					if (myChar != strChar)
						break;
					if (i == strLength)
						return (NSRange){myIndex, strLength};
					myChar = (*selfIMP)(self, charAtIndexSEL,myIndex + i);
					strChar = (*aStringIMP)(aString, charAtIndexSEL, i);
					i++;
					}
				if (myIndex == myEndIndex)
					break;
				myIndex ++;
				}	}
			break;

		case NSBackwardsSearch+NSLiteralSearch:
		case NSAnchoredSearch+NSBackwardsSearch+NSLiteralSearch:
		{										// search backward literal
			myEndIndex = aRange.location;
			myIndex = maxRange - strLength;
			strFirstCharacter = [aString characterAtIndex:0];

			if (mask & NSAnchoredSearch)
				myEndIndex = myIndex;

			for (;;)
				{
				unsigned int i = 1;
				unichar myChar = [self characterAtIndex:myIndex];
				unichar strChar = strFirstCharacter;

				for (;;)
					{
					if (myChar != strChar)
						break;
					if (i == strLength)
						return (NSRange){myIndex, strLength};
					myChar = [self characterAtIndex:myIndex + i];
					strChar = [aString characterAtIndex:i];
					i++;
					}
				if (myIndex == myEndIndex)
					break;
				myIndex --;
				}	}
			break;

		case NSCaseInsensitiveSearch:
		case NSAnchoredSearch+NSCaseInsensitiveSearch:
		{								// search forward case insensitive
										// temporary cure for a memory issue: the following method allocates autoreleased objects!
			NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
			unsigned int strBaseLength = [aString _baseLength];
			id strFirstCharacterSeq;

			myIndex = aRange.location;
			myEndIndex = maxRange - strBaseLength;

			if (mask & NSAnchoredSearch)
				myEndIndex = myIndex;

			strFirstCharacterSeq = [GSSequence sequenceWithString: aString
															range: [aString rangeOfComposedCharacterSequenceAtIndex: 0]];

			for (;;)
				{
				NSRange m, s;
				NSRange mainRange;
				unsigned int myCount = 1;
				unsigned int sCnt = 1;
				id myChar, strChar = strFirstCharacterSeq;

				m = [self rangeOfComposedCharacterSequenceAtIndex:myIndex];
				myChar = [GSSequence sequenceWithString:self range:m];

				for (;;)
					{
					if (!([myChar compare:strChar] == NSOrderedSame)
						&& !([[myChar lowercase] compare:
							  [strChar lowercase]] == NSOrderedSame))
						break;
					if (sCnt >= strLength)
						{
						[pool release];
						return (NSRange){myIndex, myCount};
						}
					m = [self rangeOfComposedCharacterSequenceAtIndex:
						 myIndex + myCount];
					myChar = [GSSequence sequenceWithString: self
													  range: m];
					s = [aString rangeOfComposedCharacterSequenceAtIndex:sCnt];
					strChar = [GSSequence sequenceWithString:aString range:s];
					myCount += m.length;
					sCnt += s.length;
					}
				if (myIndex >= myEndIndex)
					break;
				mainRange = [self rangeOfComposedCharacterSequenceAtIndex:
							 myIndex];
				myIndex += mainRange.length;
				}
			[pool release];
		}
			break;

		case NSBackwardsSearch+NSCaseInsensitiveSearch:
		case NSAnchoredSearch+NSBackwardsSearch+NSCaseInsensitiveSearch:
		{								// search backward case insensitive
										// teporary cure for a memory issue: the following method allocates autoreleased objects!
			NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
			unsigned int strBaseLength = [aString _baseLength];
			id strFirstCharacterSeq;

			myEndIndex = aRange.location;
			myIndex = maxRange - strBaseLength;

			if (mask & NSAnchoredSearch)
				myEndIndex = myIndex;

			strFirstCharacterSeq = [GSSequence sequenceWithString: aString
															range: [aString rangeOfComposedCharacterSequenceAtIndex: 0]];

			for (;;)
				{
				NSRange m, s;
				unsigned int myCount = 1, sCnt = 1;
				id myChar, strChar = strFirstCharacterSeq;

				m = [self rangeOfComposedCharacterSequenceAtIndex:myIndex];
				myChar = [GSSequence sequenceWithString:self range:m];

				for (;;)
					{
					if (!([myChar compare:strChar] == NSOrderedSame)
						&& !([[myChar lowercase] compare:
							  [strChar lowercase]] == NSOrderedSame))
						break;
					if (sCnt >= strLength)
						{
						[pool release];
						return (NSRange){myIndex, myCount};
						}
					myChar = [GSSequence sequenceWithString: self
													  range: [self rangeOfComposedCharacterSequenceAtIndex:
															  myIndex + myCount]];
					m = [self rangeOfComposedCharacterSequenceAtIndex:
						 myIndex + myCount];
					strChar = [GSSequence sequenceWithString: aString
													   range: [aString
															   rangeOfComposedCharacterSequenceAtIndex: sCnt]];
					s = [aString rangeOfComposedCharacterSequenceAtIndex:sCnt];
					myCount += m.length;
					sCnt += s.length;
					}
				if (myIndex <= myEndIndex)
					break;
				myIndex--;
				while(uni_isnonsp([self characterAtIndex:myIndex])
					  && (myIndex>0))
					myIndex--;
				}
			[pool release];
		}
			break;

		case NSBackwardsSearch:
		case NSAnchoredSearch+NSBackwardsSearch:
		{												// search backward
														// teporary cure for a memory issue: the following method allocates autoreleased objects!
			NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
			unsigned int strBaseLength = [aString _baseLength];
			id strFirstCharacterSeq;

			myEndIndex = aRange.location;
			myIndex = maxRange - strBaseLength;

			if (mask & NSAnchoredSearch)
				myEndIndex = myIndex;

			strFirstCharacterSeq = [GSSequence sequenceWithString: aString
															range: [aString rangeOfComposedCharacterSequenceAtIndex: 0]];

			for (;;)
				{
				NSRange m, s;
				unsigned int myCount = 1, sCnt = 1;
				id strChar = strFirstCharacterSeq;
				id myChar = [GSSequence sequenceWithString: self
													 range:[self rangeOfComposedCharacterSequenceAtIndex:myIndex]];

				for (;;)
					{
					if (!([myChar compare:strChar] == NSOrderedSame))
						break;
					if (sCnt >= strLength)
						{
						[pool release];
						return (NSRange){myIndex, myCount};
						}
					myChar = [GSSequence sequenceWithString:self range:
							  [self rangeOfComposedCharacterSequenceAtIndex:
							   myIndex + myCount]];
					m = [self rangeOfComposedCharacterSequenceAtIndex:
						 myIndex + myCount];
					strChar = [GSSequence sequenceWithString: aString
													   range: [aString rangeOfComposedCharacterSequenceAtIndex:
															   sCnt]];
					s = [aString rangeOfComposedCharacterSequenceAtIndex:sCnt];
					myCount += m.length;
					sCnt += s.length;
					}
				if (myIndex <= myEndIndex)
					break;
				myIndex--;
				while(uni_isnonsp([self characterAtIndex: myIndex])
					  && (myIndex > 0))
					myIndex--;
				}
			[pool release];
		}
			break;

		case 0:
		case NSAnchoredSearch:
		default:
		{												// search forward
														// teporary cure for a memory issue: the following method allocates autoreleased objects!
			NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
			unsigned int strBaseLength = [aString _baseLength];
			GSSequence *strFirstCharacterSeq;

			myIndex = aRange.location;
			myEndIndex = maxRange - strBaseLength;

			if (mask & NSAnchoredSearch)
				myEndIndex = myIndex;

			strFirstCharacterSeq = [GSSequence sequenceWithString: aString
															range:[aString rangeOfComposedCharacterSequenceAtIndex:0]];

			for (;;)
				{
				NSRange m, s;
				NSRange mainRange;
				unsigned int myCount = 1, sCnt = 1;
				GSSequence *strChar = strFirstCharacterSeq;
				GSSequence *myChar = [GSSequence sequenceWithString: self
															  range:[self rangeOfComposedCharacterSequenceAtIndex:myIndex]];

				for (;;)
					{
					if (!([myChar compare:strChar] == NSOrderedSame))
						break;
					if (sCnt >= strLength)
						{
						[pool release];
						return (NSRange){myIndex, myCount};
						}
					m = [self rangeOfComposedCharacterSequenceAtIndex:
						 myIndex + myCount];
					myChar = [GSSequence sequenceWithString: self range: m];
					s = [aString rangeOfComposedCharacterSequenceAtIndex:sCnt];
					strChar = [GSSequence sequenceWithString:aString range:s];
					myCount += m.length;
					sCnt += s.length;
					}
				if (myIndex >= myEndIndex)
					break;
				mainRange = [self rangeOfComposedCharacterSequenceAtIndex:
							 myIndex];
				myIndex += mainRange.length;
				}
			[pool release];
		}
			break;
	}

	return (NSRange){NSNotFound, 0};
}

- (NSRange) rangeOfComposedCharacterSequenceAtIndex:(NSUInteger)anIndex
{
	unsigned int end, start = anIndex;						// Determining Composed Character Sequences
	while (uni_isnonsp([self characterAtIndex: start]) && start > 0)
		start--;
	end = start+1;
	while((end < _count) && uni_isnonsp([self characterAtIndex:end]))
		end++;

	return (NSRange){start, end - start};
}

- (NSComparisonResult) compare:(NSString*)aString
{
	return [self compare:aString options:0 range:((NSRange){0, _count})];			// Comparing Strings
}

- (NSComparisonResult) compare:(NSString*)aString options:(unsigned int)mask
{
	return [self compare:aString options:mask range:((NSRange){0, _count})];
}

- (NSComparisonResult) compare:(NSString*)aString
					   options:(unsigned int)mask
						 range:(NSRange)aRange
{								// FIX ME Should implement full POSIX.2 collate
	if (NSMaxRange(aRange) > _count)
		[NSException raise:NSRangeException format:@"Invalid location+length"];

	if (aRange.length == 0)
		return NSOrderedSame;
	if (((_count - aRange.location == 0) && (![aString length])))
		return NSOrderedSame;
	if (!_count)
		return NSOrderedAscending;
	if (![aString length])
		return NSOrderedDescending;

	if (mask & NSLiteralSearch)
		{
		int i;
		int s1len = aRange.length;
		int s2len = [aString length];
		int end;
		unichar s1[s1len+1];
		unichar s2[s2len+1];

		[self getCharacters:s1 range: aRange];
		s1[s1len] = (unichar)0;
		[aString getCharacters:s2];
		s2[s2len] = (unichar)0;
		end = s1len + 1;
		if (s2len < s1len)
			end = s2len+1;

		if (mask & NSCaseInsensitiveSearch)
			{
			for (i = 0; i < end; i++)
				{
				int c1 = uni_tolower(s1[i]);
				int c2 = uni_tolower(s2[i]);

				if (c1 < c2)
					return NSOrderedAscending;
				if (c1 > c2)
					return NSOrderedDescending;
				}
			}
		else
			{
			for (i = 0; i < end; i++)
				{
				if (s1[i] < s2[i])
					return NSOrderedAscending;
				if (s1[i] > s2[i])
					return NSOrderedDescending;
				}
			}

		if (s1len > s2len)
			return NSOrderedDescending;

		return (s1len < s2len) ? NSOrderedAscending : NSOrderedSame;
		}
	else
		{												// if NSLiteralSearch
														//		int start = aRange.location;
			NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];	// limit memory allocation in the loop
			int end = NSMaxRange(aRange);
			int myCount = aRange.location, sCnt = aRange.location;
			NSRange m, s;
			id mySeq, strSeq;
			NSComparisonResult result;

			while(myCount < end)
				{
				if(sCnt >= [aString length])
					{
					[pool release];
					return NSOrderedDescending;
					}
				if(myCount >= _count)
					{
					[pool release];
					return NSOrderedAscending;
					}
				m = [self rangeOfComposedCharacterSequenceAtIndex:  myCount];
				myCount += m.length;
				s = [aString rangeOfComposedCharacterSequenceAtIndex:sCnt];
				sCnt += s.length;
				mySeq = [GSSequence sequenceWithString: self range: m];
				strSeq = [GSSequence sequenceWithString: aString range: s];
				if (mask & NSCaseInsensitiveSearch)
					result = [[mySeq lowercase] compare: [strSeq lowercase]];
				else
					result = [mySeq compare: strSeq];
				if(result != NSOrderedSame)
					{
					[pool release];
					return result;
					}
				}
			[pool release];

			return (sCnt < [aString length]) ? NSOrderedAscending : NSOrderedSame;
		}
}

- (NSComparisonResult) compare:(NSString*)aString
					   options:(unsigned int)mask
						 range:(NSRange)aRange
						locale:(NSDictionary *)dict
{
	if(!dict)
		// shouldn't we cache the dictionaryRepresentation and watch change-notifications?
		dict=[[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
	NIMP;
	return NSOrderedAscending;
}

- (NSComparisonResult) localizedCompare:(NSString *)string
{
	return [self compare:string options:0 range:((NSRange){0, _count}) locale:nil];
}

- (NSComparisonResult) localizedCaseInsensitiveCompare:(NSString *)string
{
	return [self compare:string options: NSCaseInsensitiveSearch range:((NSRange){0, _count}) locale:nil];
}

- (BOOL) isEqual:(id)obj						{ SUBCLASS return NO; }
- (BOOL) isEqualToString:(NSString*)aString		{ SUBCLASS return NO; }

- (BOOL) isEqualTo:(id) obj;
{
	NSLog(@"Warning: you are using the scripting method -[NSString isEqualTo:] instead of -[NSString isEqual:] or -[NSString isEqualToString:]");
	return [self isEqual:obj];
}

- (NSUInteger) hash
{
	if (_count)
		{
		unichar *source, *p, *target, *spoint, *tpoint;
		unichar *dpoint, *first, *second, tmp;
		NSUInteger ret = 0, char_count = 0;
		NSUInteger count, len2, len;
		BOOL notdone;

		len = (_count > NSHashStringLength) ? NSHashStringLength : _count;

		source = objc_malloc(sizeof(unichar) * (len * MAXDEC +1));
		[self getCharacters:source range:(NSRange){0, len}];
		source[len] = (unichar)0;
		// decompose
		target = objc_malloc(sizeof(unichar) * (len * MAXDEC +1));
		spoint = source;
		tpoint = target;
		do {
			notdone = NO;
			do {
				if(!(dpoint = uni_is_decomp(*spoint)))
					*tpoint++ = *spoint;
				else
					{
					while(*dpoint)
						*tpoint++ = *dpoint++;
					notdone = YES;
					}	}
			while(*spoint++);

			*tpoint = (unichar)0;
			memcpy(source, target, sizeof(unichar) * (len * MAXDEC +1));
			tpoint = target;
			spoint = source;
		}
		while(notdone);
		// order
		if((len2 = uslen(source)) > 1)
			do {
				notdone = NO;
				first = source;
				second = first+1;
				for(count = 1; count < len2; count++)
					{
					if(uni_cop(*second))
						{
						if(uni_cop(*first) > uni_cop(*second))
							{
							tmp = *first;
							*first = *second;
							*second = tmp;
							notdone = YES;
							}
						if(uni_cop(*first) == uni_cop(*second))
							if(*first > *second)
								{
								tmp = *first;
								*first = *second;
								*second = tmp;
								notdone = YES;
								}		}
					first++;
					second++;
					}	}
		while(notdone);

		p = source;

		while (*p && char_count++ < NSHashStringLength)
			ret = (ret << 5) + ret + *p++;

		// 		len = (_count > NSHashStringLength) ? NSHashStringLength : _count;
		// GSSequence *seq=[GSSequence sequenceWithString:self range:NSMakeRange(0, len)];
		// NSAssert([[[seq decompose] order] hash] == ret, @"hash mismatch");
		// ret = [[[[GSSequence sequenceWithString:self range:NSMakeRange(0, len)] decompose] order] hash];
		//

		if (ret == 0)				// The hash caching in our concrete string classes uses zero to denote an empty cache value, so we MUST NOT return a hash of zero.
			ret = (NSUInteger) -1;
		objc_free(source);
		objc_free(target);
		return ret;
		}
	else
		return (NSUInteger) -2;						// Hash for an empty string.
}

- (BOOL) hasPrefix:(NSString*)aString
{
	NSRange range = [self rangeOfString:aString];
	return ((range.location == 0) && (range.length != 0)) ? YES : NO;
}

- (BOOL) hasSuffix:(NSString*)aString
{
	NSRange range = [self rangeOfString:aString options:NSBackwardsSearch];
	return (range.length > 0
			&& range.location == (_count - [aString length])) ? YES : NO;
}

- (NSString*) commonPrefixWithString:(NSString*)aString options:(unsigned int)mask
{ // Getting a Shared Prefix
	if(mask & NSLiteralSearch)
		{
		int prefix_len = 0;
		unichar *a1=objc_malloc(sizeof(unichar)*(_count+1));
		unichar *s1 = a1;
		unichar *a2=objc_malloc(sizeof(unichar)*([aString length]+1));
		unichar *s2 = a2;

		[self getCharacters:s1];
		s1[_count] = (unichar)0;
		[aString getCharacters:s2];
		s2[[aString length]] = (unichar)0;

		if(mask & NSCaseInsensitiveSearch)
			{
			while (*s1 && *s2 && (uni_tolower(*s1) == uni_tolower(*s2)))
				{
				s1++;
				s2++;
				prefix_len++;
				}
			}
		else
			{
			while (*s1 && *s2 && (*s1 == *s2))
				{
				s1++;
				s2++;
				prefix_len++;
				}
			}
		objc_free(a2);
		return [[[NSString alloc] initWithCharactersNoCopy:a1 length:prefix_len freeWhenDone:YES] autorelease];
		}
	else
		{
		id mySeq, strSeq;
		NSRange m, s;
		unsigned int myLength = _count;
		unsigned int strLength = [aString length];
		unsigned int myIndex = 0;
		unsigned int sIndex = 0;

		if(!myLength)
			return self;
		if(!strLength)
			return aString;
		if(mask & NSCaseInsensitiveSearch)
			{
			NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
			while((myIndex < myLength) && (sIndex < strLength))
				{
				if(uni_tolower([self characterAtIndex: myIndex]) == uni_tolower([aString characterAtIndex: sIndex]))
					{
					myIndex++;
					sIndex++;
					}
				else
					{
					m = [self rangeOfComposedCharacterSequenceAtIndex: myIndex];
					s = [aString rangeOfComposedCharacterSequenceAtIndex:sIndex];
					if((m.length < 2) || (s.length < 2))
						{
						[pool release];
						return [self substringWithRange:(NSRange){0, myIndex}];
						}
					else
						{
						mySeq = [GSSequence sequenceWithString:self range:m];
						strSeq=[GSSequence sequenceWithString:aString range:s];
						if([[mySeq lowercase] isEqual: [strSeq lowercase]])
							{
							myIndex += m.length;
							sIndex += s.length;
							}
						else
							{
							[pool release];
							return [self substringWithRange:NSMakeRange(0,myIndex)];
							}
						}
					}
				}
			[pool release];
			return [self substringWithRange:(NSRange){0, myIndex}];
			}
		else
			{
			NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
			while((myIndex < myLength) && (sIndex < strLength))
				{
				if([self characterAtIndex: myIndex] == [aString characterAtIndex: sIndex])
					{
					myIndex++;
					sIndex++;
					}
				else
					{
					m = [self rangeOfComposedCharacterSequenceAtIndex: myIndex];
					s = [aString rangeOfComposedCharacterSequenceAtIndex: sIndex];
					if((m.length < 2) || (s.length < 2))
						{
						[pool release];
						return [self substringWithRange:(NSRange){0, myIndex}];
						}
					else
						{
						mySeq = [GSSequence sequenceWithString: self range: m];
						strSeq =[GSSequence sequenceWithString:aString range:s];
						if([mySeq isEqual: strSeq])
							{
							myIndex += m.length;
							sIndex += s.length;
							}
						else
							{
							[pool release];
							return [self substringWithRange:(NSRange){0, myIndex}];
							}
						}
					}
				}
			[pool release];
			return [self substringWithRange:(NSRange){0, myIndex}];
			}
		}
}

- (NSRange) paragraphRangeForRange:(NSRange)aRange
{
	NSUInteger startIndex;
	NSUInteger lineEndIndex;
	[self getParagraphStart: &startIndex
						end: &lineEndIndex
				contentsEnd: NULL
				   forRange: aRange];
	return (NSRange){startIndex, lineEndIndex - startIndex};
}

- (NSRange) lineRangeForRange:(NSRange)aRange
{
	NSUInteger startIndex;
	NSUInteger lineEndIndex;
	[self getLineStart: &startIndex
				   end: &lineEndIndex
		   contentsEnd: NULL
			  forRange: aRange];
	return (NSRange){startIndex, lineEndIndex - startIndex};
}

- (void) getParagraphStart:(NSUInteger *)startIndex
					   end:(NSUInteger *)lineEndIndex
			   contentsEnd:(NSUInteger *)contentsEndIndex
				  forRange:(NSRange)aRange
{
	NIMP;
}

- (void) getLineStart:(NSUInteger *)startIndex
				  end:(NSUInteger *)lineEndIndex
		  contentsEnd:(NSUInteger *)contentsEndIndex
			 forRange:(NSRange)aRange
{
	unichar thischar;
	unsigned int start, end, len;

	if (NSMaxRange(aRange) > _count)
		[NSException raise:NSRangeException format:@"Invalid location+length"];

	len = _count;
	start = aRange.location;

	if(startIndex)
		{
		if(start > 0)
			{
			start--;
			while(start > 0)
				{
				BOOL done = NO;
				// FIXME: should also detect CRLF
				switch(([self characterAtIndex:start])) {
					case (unichar)'\n':
					case (unichar)'\r':
					case (unichar)0x2028:
					case (unichar)0x2029:
						done = YES;
						break;
					default:
						start--;
						break;
				}
				if(done)
					break;
				}

			if(start == 0)
				{
				thischar = [self characterAtIndex:start];

				switch(thischar) {
					case (unichar)'\n':
					case (unichar)'\r':
					case (unichar)0x2028:
					case (unichar)0x2029:
						start++;
						break;
					default:
						break;
				}
				}
			else
				start++;
			}
		*startIndex = start;
		}
	if(lineEndIndex || contentsEndIndex)
		{
		end = aRange.location+aRange.length;
		while(end < len)
			{
			BOOL done = NO;

			thischar = [self characterAtIndex:end];
			switch(thischar)
				{
					case (unichar)'\n':
					case (unichar)'\r':
					case (unichar)0x2028:
					case (unichar)0x2029:
					done = YES;
					break;
					default:
					break;
				}
			end++;
			if(done)
				break;
			}
		if(lineEndIndex)
			{
			if(end < len)
				{
				if([self characterAtIndex:end] == (unichar)'r')
					if([self characterAtIndex:end+1] == (unichar)'n')
						*lineEndIndex = end+1;
					else
						*lineEndIndex = end;
					else
						*lineEndIndex = end;
				}
			else
				*lineEndIndex = end;
			}
		// Assume last line is terminated
		if(contentsEndIndex)					// as OS docs do not specify.
			*contentsEndIndex = (end < len) ? end-1 : end;
		}
}

// FIX ME There is more than this to Unicode word capitalization but this will work in most cases

- (NSString*) capitalizedString
{
	unichar *s = objc_malloc(sizeof(unichar)*(_count+1));
	int count = 0;
	BOOL found = YES;
	if(!s)
		[NSException raise: NSMallocException format: @"Unable to allocate"];

	[self getCharacters:s];
	s[_count] = (unichar)0;
	while (count < _count)
		{
		if ((*__whitespceIMP)(__whitespce, __charIsMem, s[count]))
			{
			count++;
			found = YES;
			while ((*__whitespceIMP)(__whitespce, __charIsMem, s[count])
				   && (count < _count))
				count++;
			}
		if (found)
			{
			s[count] = uni_toupper(s[count]);
			count++;
			}
		else
			{
			while (!(*__whitespceIMP)(__whitespce, __charIsMem, s[count])
				   && (count < _count))
				{
				s[count] = uni_tolower(s[count]);
				count++;
				}	}

		found = NO;
		};

	return [[[NSString alloc] initWithCharactersNoCopy:s
												length:_count
										  freeWhenDone: YES] autorelease];
}

- (NSString*) lowercaseString
{
	unichar *s = objc_malloc(sizeof(unichar)*(_count+1));
	int count;
	if(!s)
		[NSException raise: NSMallocException format: @"Unable to allocate"];

	for(count = 0; count < _count; count++)
		s[count] = uni_tolower([self characterAtIndex:count]);

	return [[[[self class] alloc] initWithCharactersNoCopy: s
										   length: _count
											  freeWhenDone: YES] autorelease];
}

- (NSString*) uppercaseString;
{
	unichar *s = objc_malloc(sizeof(unichar)*(_count+1));
	int count;
	if(!s)
		[NSException raise: NSMallocException format: @"Unable to allocate"];

	for(count = 0; count < _count; count++)
		s[count] = uni_toupper([self characterAtIndex:count]);

	return [[[[self class] alloc] initWithCharactersNoCopy: s
										   length: _count
											  freeWhenDone: YES] autorelease];
}

- (double) doubleValue
{
#if 0
	const char *s=[self cString];
	fprintf(stderr, "doubleValue(%s) -> %f\n", s, atof(s));
#endif
	return atof([self cString]);
}

- (float) floatValue			{ return (float) atof([self cString]); }
- (int) intValue				{ return atoi([self cString]); }
- (NSInteger) integerValue		{ return atoi([self cString]); }
- (long long) longLongValue				{ return atoll([self cString]); }

- (BOOL) boolValue
{
	const char *s=[self cString];
	while(isspace(*s))
		s++;
	if(*s == 't' || *s == 'T' || *s == 'y' || *s == 'Y')
		return YES;	// yes or true
	return atoi(s) != 0;	// also accept 0 and 1
}

- (NSUInteger) completePathIntoString:(NSString**)outputName
						caseSensitive:(BOOL)flag
					 matchesIntoArray:(NSArray**)outputArray
						  filterTypes:(NSArray*)filterTypes
{
	NSString *base_path = [self stringByDeletingLastPathComponent];
	NSString *last_compo = [self lastPathComponent];
	NSString *tmp_path;
	NSDirectoryEnumerator *e;
	NSMutableArray *op=nil;
	int match_count = 0;
	// Manipulating File System Paths
	if (outputArray != 0)
		op = [NSMutableArray array];
	if (outputName != NULL)
		*outputName = nil;
	if ([base_path length] == 0)
		base_path = @".";

	e = [[NSFileManager defaultManager] enumeratorAtPath: base_path];
	while (tmp_path = [e nextObject], tmp_path)
		{													// Prefix matching
			if (flag)
				{ 												// Case sensitive
					if (NO == [tmp_path hasPrefix: last_compo])
						continue;
				}
			else
				{
				if (NO == [[tmp_path uppercaseString]
						   hasPrefix: [last_compo uppercaseString]])
					continue;
				}
			// Extensions filtering
			if (filterTypes &&
				(NO == [filterTypes containsObject: [tmp_path pathExtension]]))
				continue;
			// Found a completion
			match_count++;
			if (outputArray != NULL)
				[op addObject: tmp_path];

			if ((outputName != NULL) && ((*outputName == nil)
										 || (([*outputName length] < [tmp_path length]))))
				*outputName = tmp_path;
		}
	if (outputArray != NULL)
		*outputArray = [[op copy] autorelease];

	return match_count;
}

// Return a string for passing to OS calls to handle file system objects.

- (const char*) fileSystemRepresentation		{ return [[NSFileManager defaultManager] fileSystemRepresentationWithPath:self]; }

- (BOOL) getFileSystemRepresentation:(char*)buffer maxLength:(NSUInteger)size
{
	const char *ptr = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:self];

	if (strlen(ptr) > size)
		return NO;  // does not fit
	strcpy(buffer, ptr);

	return YES;
}

// return a string containing the portion
// receiver following the last '/'. If last
// char is '/' then return the previous sub
// string delimited by '/'.  returns emtpy
// string if receiver contains only a '/'.

- (NSString*) lastPathComponent
{
	NSArray *components=[self _mutablePathComponents];
	unsigned int cnt=[components count];
	if(cnt < 1)
		return @"";	// FIXME: what happens if we call this on NSMutableString??? -> return [[self class] stringWithString:@""];
	if(cnt > 1 && [[components objectAtIndex:cnt-1] isEqualToString:@"/"])	// path ends (but does not start) in /
		return [components objectAtIndex:cnt-2];
	return [components objectAtIndex:cnt-1];

#if OLD
	NSRange range;
	NSString *substring = nil;

	range = [self rangeOfCharacterFromSet:pathSeps options:NSBackwardsSearch];
#if 0
	fprintf(stderr, [[NSString stringWithFormat:@"range=%@ self=%@\n", NSStringFromRange(range), self] UTF8String]);
#endif
	if (range.length == 0)
		substring = [[self copy] autorelease];
	else  if (range.location == (_count - 1))
		{ // ends in /
			if (range.location == 0)
				substring = @"/";	// pure /
			else
				substring = [[self substringToIndex:range.location]
							 lastPathComponent];	// take last path component before trailing /
		}
	else
		substring = [self substringFromIndex:range.location + 1];
	return substring;
#endif
}

- (NSString*) pathExtension
{ // interpret receiver as a path and return the portion after the last '.' or an empty str
	NSString *c=[self lastPathComponent];
	NSRange r = [c rangeOfString:@"." options: NSBackwardsSearch];
	if(r.location == NSNotFound || r.location == 0)
		return @"";	// no . or .ext // FIXME: what happens if we call this on NSMutableString???
	return [c substringFromIndex:NSMaxRange(r)];	// starts behind last .

#if OLD
	NSRange r, range = [self rangeOfString:@"." options: NSBackwardsSearch];
	if (range.location == 0 || range.length == 0)
		return @"";
	range.location++;	// remove .
	range.length=[self length]-range.location;	// all to end of string
	r = [self rangeOfCharacterFromSet: pathSeps options: NSBackwardsSearch];	// may be multiple
	if (r.location != NSNotFound)
		range.length=r.location-range.location;	// strip off traling / or //
	return [self substringWithRange:range];
#endif
}

- (NSString*) stringByAppendingPathComponent:(NSString*)aString
{ // return a new string with aString appended to reciever
  // FIXME: this is much less efficient than the old implementation - but handles the special cases like multiple /// correctly
	NSMutableArray *s=[self _mutablePathComponents];
	NSArray *a=[aString _mutablePathComponents];
	[s addObjectsFromArray:a];	// append
								//	NSLog(@"a=%@", s);
	return [[self class] pathWithComponents:s];

#if OLD
	NSRange range;
	NSString *newstring;

	if ([aString length] == 0)
		return [[self copy] autorelease];

	range = [aString rangeOfCharacterFromSet: pathSeps];
	if (range.length != 0 && range.location == 0)
		aString = [aString substringFromIndex: 1];	// strip off first / (only)

	range = [self rangeOfCharacterFromSet:pathSeps options:NSBackwardsSearch];
	if ((range.length == 0 || range.location != _count - 1) && _count > 0)
		newstring = [self stringByAppendingString: pathSepString];
	else
		newstring = self;

	return [newstring stringByAppendingString: aString];
#endif
}

- (NSString*) stringByAppendingPathExtension:(NSString*)aString
{ // returns a new string with the path extension given in aString appended to the receiver
	NSMutableArray *a=[self _mutablePathComponents];
	NSString *last;
	//	NSLog(@"0=%@", a);
	if([a count] > 1 && [[a lastObject] isEqualToString:pathSepString])
		[a removeLastObject];
	last=[a lastObject];
	//	NSLog(@"a=%@", a);
	if([last isEqualToString:pathSepString])
		return self;	// don't modify!
	if([last length] != 0)	// don't return /.ext
		[a replaceObjectAtIndex:[a count]-1 withObject:[NSString stringWithFormat:@"%@.%@", last, aString]];
	//	NSLog(@"b=%@", a);
	return [[self class] pathWithComponents:a];
#if OLD
	NSRange range;
	NSString *newstring;
	if ([aString length] == 0)
		return [[self copy] autorelease];

	range = [aString rangeOfString:@"."];
	if (range.length != 0 && range.location == 0)
		aString = [aString substringFromIndex: 1];

	range = [self rangeOfString:@"." options:NSBackwardsSearch];
	if (range.length == 0 || range.location != _count - 1)
		newstring = [self stringByAppendingString:@"."];
	else
		newstring = self;

	return [newstring stringByAppendingString:aString];
#endif
}

- (NSString*) stringByDeletingLastPathComponent
{
	NSMutableArray *components=[self _mutablePathComponents];
	unsigned int cnt=[components count];
	//	NSLog(@"c=%@", components);
	if(cnt > 0)
		{
		if(cnt > 1 && [[components objectAtIndex:cnt-1] isEqualToString:@"/"])	// path ends in /
			cnt--, [components removeLastObject];	// remove trailing /
		if(cnt > 1 || ![[components objectAtIndex:cnt-1] isEqualToString:@"/"])
			[components removeLastObject];	// remove path component unless we are the first and a /
		}
	//	NSLog(@"d=%@", components);
	return [[self class] pathWithComponents:components];

#if OLD
	NSString *str=self;
	NSRange range;
	while([str hasSuffix:@"/"])
		str=[str substringToIndex:[str length]-1];	// strip off / characters
	range = [str rangeOfString:[self lastPathComponent]
					   options:NSBackwardsSearch];
#if 0
	fprintf(stderr, "%s\n", [[NSString stringWithFormat:@"range=%@ lpath=%@ self=%@", NSStringFromRange(range), [self lastPathComponent], self] UTF8String]);
#endif
	if (range.length == 0)
		return [[self copy] autorelease];

	if (range.location == 0)
		return @"";

	return (range.location > 1) ? [str substringToIndex:range.location-1] : pathSepString;
#endif
}

- (NSString*) stringByDeletingPathExtension
{
	NSMutableArray *components=[self _mutablePathComponents];
	unsigned int cnt=[components count];
	//	NSLog(@"c=%@", components);
	if(cnt > 0)
		{
		NSString *last;
		NSRange rng;
		if(cnt > 1 && [[components objectAtIndex:cnt-1] isEqualToString:@"/"])	// path ends in /
			cnt--, [components removeLastObject];	// remove trailing /
		last=[components objectAtIndex:cnt-1];
		rng=[last rangeOfString:@"." options:NSBackwardsSearch];
		if(rng.location != NSNotFound && NSMaxRange(rng) > 1)
			{
			last=[last substringToIndex:NSMaxRange(rng)-1];	// delete last . only
			[components replaceObjectAtIndex:cnt-1 withObject:last];
			}
		}
	//	NSLog(@"d=%@", components);
	return [[self class] pathWithComponents:components];
#if OLD
	NSRange range = [self rangeOfString:[self pathExtension]
								options:NSBackwardsSearch];
	return (range.length != 0) ? [self substringToIndex:range.location-1] : [[self copy] autorelease];
#endif
}

// ~			NSHomeDir()
// ~/blah		NSHomeDir()/blah
// ~user		home dir of user
// ~user/blah	home dir of user/blah
// other		other
// ~user/blah/	should strip off trailing /

- (NSString *) stringByExpandingTildeInPath
{
	NSMutableArray *path=[self _mutablePathComponents];
	unsigned int cnt=[path count];
	NSString *first=cnt > 0 ? [path objectAtIndex:0] : nil; // exists even for "/" - except vor ""
	if([first hasPrefix:@"~"])
		{
		if([first isEqualToString:@"~"])
			[path replaceObjectAtIndex:0 withObject:NSHomeDirectory()];   // replace ~
		else
			{
			NSString *home=NSHomeDirectoryForUser([first substringFromIndex:1]);
			if(home)
				[path replaceObjectAtIndex:0 withObject:home];   // replace ~user - if it exists
			}
		}
	if(cnt >= 2 && [[path objectAtIndex:cnt-1] isEqualToString:@"/"])
		[path removeLastObject];	// remove traling /
	return [[self class] pathWithComponents:path];  // join together
}

- (NSString*) stringByAbbreviatingWithTildeInPath
{
	NSString *hd=NSHomeDirectory();
	NSArray *hdc=[hd _mutablePathComponents];
	NSArray *path=[self _mutablePathComponents];
	NSArray *r;
	NSString *s;
	NSEnumerator *e=[hdc objectEnumerator], *f=[path objectEnumerator];
#if 0
	NSLog(@"hd=%@", hd);
	NSLog(@"hdc=%@", hdc);
	NSLog(@"path=%@", path);
#endif
	while((s=[e nextObject]))
		{
		NSString *t=[f nextObject];
		if(!t || ![s isEqualToString:t])
			return [[self class] pathWithComponents:path];	// not prefixed
		}
	r=[f allObjects];	// all remaining components
	if([r count] == 0)
		return @"~";	// no remaining (sub) path
	return [@"~/" stringByAppendingString:[[self class] pathWithComponents:r]];	// make path from remaining components
}

- (NSString*) stringByResolvingSymlinksInPath
{
	NSString *first_half = self, * second_half = @"";
	const char * tmp_cpath;
	const int MAX_PATH_LEN = 1024;
	char *tmp_buf=objc_malloc(MAX_PATH_LEN+1);
	int syscall_result;
	struct stat tmp_stat;

	// FIXME: should properly process result of readlink() into string representation
	// and handle virtual chroot() cases
	// by using NSFileManager's pathContentOfSymbolicLinkAtPath

	while(1)
		{
		tmp_cpath = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:first_half];

		syscall_result = lstat(tmp_cpath, &tmp_stat);
		if (0 != syscall_result)
			return self;

		if ((tmp_stat.st_mode & S_IFLNK) &&
			((syscall_result = readlink(tmp_cpath, tmp_buf, MAX_PATH_LEN)) != -1))
			{						// first half is a path to a symbolic link.
				tmp_buf[syscall_result] = '\0'; 			// Make a C string
				second_half = [[NSString stringWithCString: tmp_buf]
							   stringByAppendingPathComponent: second_half];
				first_half = [first_half stringByDeletingLastPathComponent];
			}
		else
			{						// second_half is an absolute path
				if ([second_half hasPrefix: @"/"])
					return [second_half stringByResolvingSymlinksInPath];

				// first half is NOT a path to a symbolic link
				second_half = [[first_half lastPathComponent]
							   stringByAppendingPathComponent: second_half];
				first_half = [first_half stringByDeletingLastPathComponent];
			}

		if ([first_half length] == 0) 						// BREAK CONDITION
			break;

		if ([first_half length] == 1
			&& [pathSeps characterIsMember: [first_half characterAtIndex: 0]])
			{
			second_half = [pathSepString stringByAppendingPathComponent:second_half];
			break;
			}	}

	objc_free(tmp_buf);
	return second_half;
}

- (NSString*) stringByStandardizingPath
{
	NSMutableArray *c=[[self stringByExpandingTildeInPath] _mutablePathComponents];
	unsigned int cnt=[c count];
	unsigned int i;
	//	NSLog(@"a=%@", c);
	BOOL isAbsolute=cnt > 0 && [[c objectAtIndex:0] isEqualToString:pathSepString];
	for(i=(isAbsolute?1:0); i < cnt; i++)
		{
		NSString *component=[c objectAtIndex:i];
		//		NSLog(@"i=%u cnt=%u c=%@", i, cnt, component);
		if(cnt >= (isAbsolute?3:2) && [component isEqualToString:@"."])
			[c removeObjectAtIndex:i], i--, cnt--;	// remove ./
		else if(isAbsolute && [component isEqualToString:@".."])
			{
			if(i >= 2)
				[c removeObjectsInRange:NSMakeRange(i-1, 2)], i--, cnt-=2;	// remove something/../
			else
				[c removeObjectAtIndex:1], i--, cnt--;	// remove .. from /..
			}
		}
	//	NSLog(@"c=%@", c);
	return [[self class] pathWithComponents:c];
#if OLD
	NSMutableString *s = [[self stringByExpandingTildeInPath] mutableCopy]; // Expand `~' in path
	NSRange search = {0, [s length]};
	NSRange found = [s rangeOfString:@"//" options:NSLiteralSearch range:search];

	if ([s hasPrefix: @"/private"])						// Remove `/private' - not useful but according to documentation
		[s deleteCharactersInRange:((NSRange){0,7})];

	while (found.length)
		{
		[s deleteCharactersInRange: (NSRange){found.location, 1}];
		search.length = [s length];
		found = [s rangeOfString:@"//" options:0 range:search];
		}
	// Condense `/./'
	found = [s rangeOfString:@"/./" options:NSLiteralSearch range:search];
	while (found.length)
		{
		[s deleteCharactersInRange: (NSRange){found.location, 2}];
		search.length = [s length];
		found = [s rangeOfString:@"/./" options:0 range:search];
		}
	// Condense `/../'
	found = [s rangeOfString:@"/../" options:NSLiteralSearch range:search];
	while (found.length)
		{
		if (found.location > 0)
			{
			NSRange r = {0, found.location};

			found = [s rangeOfCharacterFromSet: pathSeps
									   options: NSBackwardsSearch
										 range: r];
			found.length = r.length - found.location + 3;	// Add the `/../'
			[s deleteCharactersInRange: found];
			}
		else
			[s deleteCharactersInRange: (NSRange){found.location, 3}];
		search.length = [s length];
		found = [s rangeOfString:@"/../" options:0 range:search];
		}

	return [s autorelease];
#endif
}

- (NSString *) stringByTrimmingCharactersInSet:(NSCharacterSet *) set
{ // not at all optimized for speed!
	unsigned from=0, to=[self length];
	while(from < to)
		{
		if(![set characterIsMember:[self characterAtIndex:from]])
			break;
		from++;
		}
	while(to > from)
		{
		if(![set characterIsMember:[self characterAtIndex:to-1]])
			break;
		to--;
		}
	return [self substringWithRange:NSMakeRange(from, to-from)];
}

// private methods for Unicode level 3 implementation
- (NSUInteger) _baseLength					{ return 0; }

// FIXME: we could define a NSPathComponentsString which has a NSMutableArray iVar
// to speed up successive path operations on the components
// and convert it back to a pure NSString by -string or any other primitive operation

+ (NSString*) pathWithComponents:(NSArray*)components
{
	NSMutableArray *a=[NSMutableArray arrayWithCapacity:[components count]];
	NSEnumerator *e=[components objectEnumerator];
	NSString *c;
	BOOL isAbsolute=NO;
	while((c=[e nextObject]))
		{
		if([c hasPrefix:pathSepString])
			{
			c=[c substringFromIndex:1];	// remove initial /
			if([a count] == 0)
				isAbsolute=YES;	// the first component that is absolute defines the absolute status
			}
		if([c hasSuffix:pathSepString])
			c=[c substringToIndex:[c length]-1];	// remove trailing /
		if([c length] > 0)	// ignore empty components
			[a addObject:c];
		}
	c=[a componentsJoinedByString:pathSepString];	// merge all components
	if(isAbsolute)
		c=[pathSepString stringByAppendingString:c];	// prefix with absolute path (unless it was already embedded in components)
	return c;
#if OLD
	unsigned int cnt=[components count];
	if(cnt > 0)
		{
		NSString *s = [components objectAtIndex: 0];
		int i;
		for (i = 1; i < cnt; i++)
			s = [s stringByAppendingPathComponent: [components objectAtIndex: i]];
		return s;
		}
	return @"";	// what happens if we call this on NSMutableString???
#endif
}

- (BOOL) isAbsolutePath
{
	return (_count > 0 && [self hasPrefix:pathSepString]);
}

- (NSMutableArray*) _mutablePathComponents
{
	NSMutableArray *a = [[self componentsSeparatedByCharactersInSet: pathSeps] mutableCopy];
	int	i = [a count];

	if (i > 0)
		{
		BOOL isAbsolute=NO;	// path is absolute
							//		NSLog(@"a=%@", a);
		if (i > 1 && [[a objectAtIndex: 0] length] == 0)
			// If the path began with a '/' then the first path component must be a '/' rather than an empty string
			[a replaceObjectAtIndex: 0 withObject: pathSepString], isAbsolute=YES;
		if (i > 1 && [[a objectAtIndex: i-1] length] == 0 && !(isAbsolute && i == 2))
			// If the path did end with a '/' then the last path component must be a '/' rather than an empty string - except for a "/" string
			[a replaceObjectAtIndex: i-1 withObject: pathSepString];
		//		NSLog(@"b=%@", a);
		for (i = i - 1; i >= 0; i--)
			{ // remove empty path components
				if ([[a objectAtIndex: i] length] == 0)
					[a removeObjectAtIndex: i];
			}
		//		NSLog(@"c=%@", a);
		}
	return [a autorelease];
}

- (NSArray*) pathComponents
{ // return an immutable copy
	return [[[self _mutablePathComponents] copy] autorelease];
}

- (NSArray*) stringsByAppendingPaths:(NSArray*)paths
{
	NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity: [paths count]];
	NSArray *r;
	int i;
	for (i = 0; i < [paths count]; i++)
		[a addObject: [self stringByAppendingPathComponent: [paths objectAtIndex: i]]];
	r = [a copy];
	[a release];
	return [r autorelease];
}

- (NSComparisonResult) caseInsensitiveCompare:(NSString*)aString
{
	return [self compare:aString
				 options:NSCaseInsensitiveSearch
				   range:((NSRange){0, _count})];
}

- (BOOL) writeToFile:(NSString*)filename atomically:(BOOL)useAuxiliaryFile
{
	id d;

	if(!(d = [self dataUsingEncoding: __cStringEncoding]))
		d = [self dataUsingEncoding: NSUnicodeStringEncoding];

	return [d writeToFile:filename atomically:useAuxiliaryFile];
}

- (BOOL) writeToURL:(NSURL *)url atomically:(BOOL)useAuxiliaryFile
{
	NIMP;
	return NO;
}

- (BOOL) writeToFile:(NSString *)path
		  atomically:(BOOL)useAuxiliaryFile
			encoding:(NSStringEncoding)enc
			   error:(NSError **)error;
{
	NIMP;
	return NO;
}

- (BOOL) writeToURL:(NSURL *)url
		 atomically:(BOOL)useAuxiliaryFile
		   encoding:(NSStringEncoding)enc
			  error:(NSError **)error;
{
	NIMP;
	return NO;
}

// NSCoding Protocol

- (void) encodeWithCoder:(NSCoder *)anEncoder					{ SUBCLASS }
- (id) initWithCoder:(NSCoder *)aDecoder						{ SUBCLASS return nil; }

- (Class) classForArchiver							{ return [NSString class]; }
- (Class) classForCoder								{ return [NSString class]; }

- (id) propertyList
{
	NSString *err=@"bug: err not changed!";
	NSPropertyListFormat fmt;
	id o;
	o=[NSPropertyListSerialization _propertyListFromString:self
										  mutabilityOption:NSPropertyListImmutable
													format:&fmt errorDescription:&err];
	if(!o)
		{
		NSLog(@"error: %@\n%@", err, self);
		[NSException raise:NSParseErrorException format:@"propertyList: %@", err];
		}
	return o;
}

- (NSDictionary*) propertyListFromStringsFileFormat
{
	NSString *err=@"bug: err not changed!";
	NSPropertyListFormat fmt;
	id o;
#if 0
	NSLog(@"[%@ propertyListFromStringsFileFormat]", NSStringFromClass([self class]));
#endif
	o=[NSPropertyListSerialization _propertyListFromString:self
										  mutabilityOption:NSPropertyListImmutable
													format:&fmt
										  errorDescription:&err];
	if(![o isKindOfClass:[NSDictionary class]])
		{
		NSLog(@"error: %@\n%@", err, self);
		[NSException raise:NSParseErrorException format:@"propertyListFromStringsFileFormat: %@", err];
		}
	return o;
}

- (NSString *) stringByPaddingToLength:(NSUInteger)len withString:(NSString *) pad startingAtIndex:(NSUInteger) index;
{
	NSUInteger count=[self length];
	NSUInteger pcount;
	NSMutableString *r;
	// assert that index < pcount!
	if(count == len)
		return self;	// already that length
	if(len < count)
		return [self substringToIndex:len]; // shrink
	r=[[self mutableCopy] autorelease];
	//	NSLog(@"self=%@", r);
	//	NSLog(@"mutableCopy=%@", r);
	pcount=[pad length];
	while(count < len)
		{
		unsigned n;
		if(count+pcount <= len && index == 0)
			{ // append a full padding block
			  //			NSLog(@"pad with *%@*", pad);
				[r appendString:pad];
				count+=pcount;
				continue;
			}
		// append first/last fragment
		n=index-pcount;		// to end of padding characters
		if(n > len-count)
			n=len-count;	// but not more than requested
							//		NSLog(@"pad with *%@*", [pad substringWithRange:NSMakeRange(index, n)]);
		[r appendString:[pad substringWithRange:NSMakeRange(index, n)]];
		count+=n;
		index=0;	// continue with full fragments
		}
	//	NSLog(@"padded=%@", r);
	return r;
}

- (NSString *) stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding) encoding;
{ // convert to given encoding (should be UTF8) http://www.w3.org/International/O-URL-code.html
	NSMutableString *s;
	NSData *data=[self dataUsingEncoding:encoding];
	int i, count;
	const char *p;
	if(!data)
		return nil;	// can't encode
	p=[data bytes];
	count=[data length];
	s=[NSMutableString stringWithCapacity:count+6];	// for 1-2 encoded characters
	for(i=0; i<count; p++, i++)
		{
		if(*p == '%' || *p <= 0x20 || *p >= 0x7f)
			[s appendFormat:@"%%%02x", *p];
		else
			[s appendFormat:@"%c", *p];
		}
	return s;
}

- (NSString *) stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding) encoding;
{
	NSMutableData *data=[NSMutableData dataWithCapacity:[self length]];
	int i, count=[self length];
	for(i=0; i<count; i++)
		{
		unichar c=[self characterAtIndex:i];
		char ac;
		if(c > 255)
			return nil;	// can't decode
		if(c == '%')
			{
			i++;
			if(count - i < 2)
				return nil;	// too short
			c=[self characterAtIndex:i++];
			if(c >= '0' && c <= '9') ac=c;
			else if(c >= 'A' && c <= 'F') ac=(c-'A'+10);
			else if(c >= 'a' && c <= 'f') ac=(c-'a'+10);
			else return nil;	// invalid character
			ac=(ac&0x000f)<<4;
			c=[self characterAtIndex:i++];
			if(c >= '0' && c <= '9') c&=0x0f;
			else if(c >= 'A' && c <= 'F') c=(c-'A'+10);
			else if(c >= 'a' && c <= 'f') c=(c-'a'+10);
			else return nil;	// invalid character
			ac+=c;
			}
		else
			ac=c;
		[data appendBytes:&ac length:1];
		}
	return [[[NSString alloc] initWithData:data encoding:encoding] autorelease];	// and try to decode
}

// FIXME: distinguish form "D" and "KD" - see http://en.wikipedia.org/wiki/Unicode_normalization#Canonical_Equivalence

- (NSString *) decomposedStringWithCanonicalMapping; { return [[[GSSequence sequenceWithString:self range:NSMakeRange(0, [self length])] decompose] string]; }	// decompose Ÿ into u and ..
- (NSString *) precomposedStringWithCanonicalMapping; { return NIMP; }
- (NSString *) decomposedStringWithCompatibilityMapping; { return [[[GSSequence sequenceWithString:self range:NSMakeRange(0, [self length])] decompose] string]; }	// map super/subscript to digits, map wide/narrow katakana
- (NSString *) precomposedStringWithCompatibilityMapping; { return NIMP; }

@end /* NSString */

//*****************************************************************************
//
// 		NSMutableString
//
//*****************************************************************************

@implementation NSMutableString

+ (id) allocWithZone:(NSZone *) z
{
	return (NSMutableString *) NSAllocateObject(_mutableStringClass, 0, z);
}

+ (NSMutableString*) stringWithCapacity:(NSUInteger)capacity
{
	return [[[self alloc] initWithCapacity:capacity] autorelease];
}

+ (id) stringWithCString:(const char*)byteString
{
	return [[[GSMutableString alloc] initWithCString:byteString] autorelease];
}

+ (id) stringWithCString:(const char*)byteString length:(unsigned int)length
{
	return [[[_mutableStringClass alloc] initWithCString:byteString
												  length:length] autorelease];
}

- (void) appendFormat:(NSString*)format, ...;		{ SUBCLASS; }
- (void) appendString:(NSString*)aString;			{ SUBCLASS; }
- (void) deleteCharactersInRange:(NSRange)range;	{ SUBCLASS; }
- (id) initWithCapacity:(NSUInteger)capacity;			{ return SUBCLASS; }
- (void) insertString:(NSString*)aString atIndex:(NSUInteger)index;	{ SUBCLASS; }
- (void) replaceCharactersInRange:(NSRange)range withString:(NSString*)aString; { SUBCLASS; }
- (NSUInteger) replaceOccurrencesOfString: (NSString*)replace
							   withString: (NSString*)by
								  options: (NSUInteger)opts
									range: (NSRange)searchRange				{ SUBCLASS; return 0; }
- (void) setString:(NSString*)aString;											{ SUBCLASS; }

@end /* NSMutableString */

//*****************************************************************************
//
// 		GSString
//
//*****************************************************************************

@implementation GSString

+ (id) allocWithZone:(NSZone *) z
{
	return (GSString *) NSAllocateObject(self, 0, z);
}

- (id) initWithCharactersNoCopy:(unichar*)chars
						 length:(unsigned int)length
				   freeWhenDone:(BOOL)flag
{
	_count = length;
	_uniChars = chars;
	_freeWhenDone = flag;
	return self;
}

- (id) initWithCStringNoCopy:(char*)byteString
					  length:(unsigned int)length
				freeWhenDone:(BOOL)flag
{ // replace with CString
	[self release];
	return (GSString *) [[GSCString alloc] initWithCStringNoCopy:byteString
														  length:length
													freeWhenDone: flag];
}

- (void) dealloc
{
	if (_freeWhenDone && _uniChars)
		objc_free(_uniChars);
	if(_cString)
		objc_free(_cString);
	[super dealloc];
}

- (BOOL) isEqual:(id)obj
{ // self is a Unicode string
	Class c;
#if 0
	NSLog(@"++ %@ isEqual %@", self, obj);
#endif
	if (obj == self)
		return YES;
	c = object_getClass(obj);	// peer class
#if 0
	NSLog(@"++ 1 %@ %p", c, c);
	NSLog(@"++ 2 %@ %p", _constantStringClass, _constantStringClass);
#endif
	if (c == _strClass || c == _mutableStringClass)
		{ // c is a Unicode string
			if (_hash == 0)
				_hash = _strHashImp(self, @selector(hash));
			if (((GSString*)obj)->_hash == 0)
				((GSString*)obj)->_hash = _strHashImp(obj, @selector(hash));
			if (_hash != ((GSString*)obj)->_hash)
				return NO;
		}
	else if (c == _cStringClass || c == _constantStringClass)
		{ // c is a C-String
#if 0
			NSLog(@"++ 3 %@", c);
#endif
			if (_hash == 0)
				_hash = _strHashImp(self, @selector(hash));
#if 0
			NSLog(@"  hash %u", _hash);
#endif
			if ((c != _constantStringClass) && (_hash != [(NSString *) obj hash]))
				return NO;
#if 0
			NSLog(@"  _count %u vs. count %u", _count, ((NSString*)obj)->_count);
#endif
			if(_count != ((NSString*)obj)->_count)
				return NO;
			if(!_cString)
				{ // not yet cached
					NS_DURING
					[self cString];	// may fail with character conversion error - then we can't be equal to the other string
					NS_HANDLER
#if 0
					NSLog(@"failed to convert");
#endif
					return NO;	// failed - i.e. we have some non-convertible characters
					NS_ENDHANDLER
				}
#if 0
			NSLog(@"cString: %p %u", _cString, _count);
			NSLog(@"%@", [NSData dataWithBytes:_cString length:_count]);
			NSLog(@"%@", [NSData dataWithBytes:((NSString*)obj)->_cString length:((NSString*)obj)->_count]);
#endif
			return memcmp(_cString, ((NSString*)obj)->_cString, _count) == 0;
		}

	if (_classIsKindOfClass(c, _nsStringClass))
		return [self isEqualToString: obj];

	return NO;
}

- (BOOL) isEqualToString:(NSString *)aString
{
	unsigned int mi = 0, si = 0;
	NSAutoreleasePool *pool;
	Class c;

	if (aString == nil)
		return NO;
	if (aString == self)
		return YES;
	c = object_getClass(aString);	// peer class

	if (_hash == 0)
		_hash = _strHashImp(self, @selector(hash));
	if (c == _strClass || c == _mutableStringClass)
		{ // other is a unichar string
			if (((GSString*)aString)->_hash == 0)
				((GSString*)aString)->_hash = _strHashImp(aString,@selector(hash));
			if (_hash != ((GSString*)aString)->_hash)
				return NO;	// different hash
		}
	else
		{ // other is a C char string
			if(_count != aString->_count)
				return NO;
			if ((c != _constantStringClass) && (_hash != [aString hash]))
				return NO;
			if(!_cString)
				{
				NS_DURING
					[self cString];	// this may fail with character conversion error!
				NS_HANDLER
					return NO;	// failed - i.e. we have some non-convertible characters so we can't be equal
				NS_ENDHANDLER
				}
			return memcmp(_cString, aString->_cString, _count) == 0;
		}

	if((!_count) && (!aString->_count))
		return YES;
	if(!_count || (!aString->_count))
		return NO;

	pool=[[NSAutoreleasePool alloc] init];
	while((mi < _count) && (si < aString->_count))
		{
		if([self characterAtIndex:mi] == [aString characterAtIndex:si])
			{ // directly the same
				mi++;
				si++;
			}
		else
			{ // check for sequence
				NSRange m = [self rangeOfComposedCharacterSequenceAtIndex:mi];
				NSRange s = [aString rangeOfComposedCharacterSequenceAtIndex:si];

				if((m.length < 2) || (s.length < 2))
					{
					[pool release];
					return NO;
					}
				else
					{
					id mySeq = [GSSequence sequenceWithString: self range: m];
					id strSeq = [GSSequence sequenceWithString:aString range:s];

					if([mySeq isEqual: strSeq])
						{
						mi += m.length;
						si += s.length;
						}
					else
						{
						[pool release];
						return NO;
						}
					}
			}
		}
	[pool release];
	return ((mi == _count) && (si == aString->_count)) ? YES : NO;
}

- (NSUInteger) hash
{
	return _hash == 0 ? (_hash = _strHashImp(self,@selector(hash))) : _hash;
}

- (unichar) characterAtIndex:(NSUInteger)index
{
	if (index >= _count)
		[NSException raise: NSRangeException format:@"Invalid index."];
	return _uniChars[index];
}

- (void) getCharacters:(unichar*)buffer
{
#if 0
	fprintf(stderr, "GSString getCharacters count=%d\n", _count);
#endif
	memcpy(buffer, _uniChars, _count*sizeof(unichar));
}

- (void) getCharacters:(unichar*)buffer range:(NSRange)aRange
{
	if (NSMaxRange(aRange) > _count)
		[NSException raise:NSRangeException format:@"Invalid location+length"];
	memcpy(buffer, _uniChars + aRange.location, aRange.length * sizeof(unichar));
}

- (NSString*) substringWithRange:(NSRange)aRange
{											// Dividing Strings into Substrings
	if (NSMaxRange(aRange) > _count)
		[NSException raise:NSRangeException format:@"Invalid location+length"];

	return [[self class] stringWithCharacters:_uniChars + aRange.location
									   length: aRange.length];
}

- (const char *) cString								// Getting C Strings
{ // convert to a C-String and cache in _cString
	uniencoder e=encodeuni(__cStringEncoding);		// get appropriate encoder function
	unsigned char *bp;
	int len;
	int i;
	if(!e)
		return NULL;
	len=[self maximumLengthOfBytesUsingEncoding:__cStringEncoding]+1;
	_cString=(char*) objc_realloc(_cString, len);
	if(!_cString)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	bp=(unsigned char *) _cString;
	for(i = 0; i < _count; i++)
		{
		if(!(*e)(_uniChars[i], &bp))
			{
#if 0
			NSLog(@"-cString: can't convert due to non-ASCII characters: %@", self);
			abort();
#endif
			*bp=0;
			objc_free(_cString);	// release buffer
			_cString=NULL;	// remove from cache or we get problems using the same string later on
			[NSException raise:NSCharacterConversionException format:@"-cString can't convert: %@", self];	// conversion error
			}
		}
	*bp=0;
	NSAssert(bp-((unsigned char *) _cString) < len, @"buffer overflow");
#if 0
	NSLog(@"cString: %p %u", _cString, _count);
#endif
	return _cString;
}

- (NSUInteger) cStringLength			{ return _count; }		// may depend on default encoding!
- (NSStringEncoding) fastestEncoding	{ return NSUnicodeStringEncoding; }
- (NSStringEncoding) smallestEncoding	{ return NSUnicodeStringEncoding; }

- (NSUInteger) _baseLength
{ // private method for Unicode level 3 implementation
	int count = 0;
	int blen = 0;
	while(count < _count)
		if(!uni_isnonsp([self characterAtIndex: count++]))
			blen++;

	return blen;
}

- (void) encodeWithCoder:(NSCoder *)aCoder						// NSCoding Protocol
{
	//	NSLog(@"@encode(unichar)='%s'", @encode(unichar));
	[aCoder encodeValueOfObjCType: @encode(unsigned) at: &_count];
	// FIXME: should we always encode/decode UTF8 to become compatible with NSPortCoder?
	// or should this depend on [aCoder versionForClassName:@"NSString"] == 1
	if(_count > 0)
		[aCoder encodeArrayOfObjCType: @encode(unichar)
								count: _count
								   at: _uniChars];
}

- (id) initWithCoder:(NSCoder *)aCoder
{
	if([aCoder allowsKeyedCoding])
		{
		[self release];
		return [[aCoder decodeObjectForKey:@"NS.string"] retain];
		}
	[aCoder decodeValueOfObjCType: @encode(unsigned) at: &_count];
	if(_count)
		[aCoder decodeArrayOfObjCType: @encode(unichar)
								count: _count
								   at: (_uniChars = objc_malloc(sizeof(unichar)*_count))];

	return self;
}

@end /* GSString */

//*****************************************************************************
//
// 		GSMutableString
//
//*****************************************************************************

@implementation GSMutableString

- (BOOL) isEqual:(id)obj
{ // self is a Unicode string
#if 0
	NSLog(@"%@ isEqual %@", self, obj);
#endif
	return [super isEqual:obj];
}

- (id) initWithCharactersNoCopy:(unichar*)chars
						 length:(unsigned int)length
				   freeWhenDone:(BOOL)flag
{
	_capacity = length;
	_count = length;
	_uniChars = chars;
	_freeWhenDone = flag;
	return self;
}

- (id) initWithCapacity:(unsigned)capacity
{
	_count = 0;
	_capacity = (capacity < 2) ? 2 : capacity;
	_uniChars = objc_malloc(sizeof(unichar) * _capacity);
	_freeWhenDone = YES;

	return self;
}

- (id) initWithCStringNoCopy:(char*)byteString
					  length:(unsigned int)length
				freeWhenDone:(BOOL)flag
{
	[self release];
	return [[[[NSString alloc] initWithCStringNoCopy: byteString
											  length: length
										freeWhenDone: flag] autorelease] mutableCopy];
}

- (id) copyWithZone:(NSZone *) z
{
	return [[_mutableStringClass alloc] initWithString:self];
}

- (void) deleteCharactersInRange:(NSRange)range
{
	_count -= range.length;
	memcpy(self->_uniChars + range.location,
		   self->_uniChars + NSMaxRange(range),
		   sizeof(unichar) * (self->_count - range.location));
	if(_cString)
		{ // release cached cString
			objc_free(_cString);
			_cString=NULL;
		}
	_hash = 0;
}

- (void) replaceCharactersInRange:(NSRange)aRange withString:(NSString*)aString
{
	int offset;
	unsigned stringLength, maxRange = NSMaxRange(aRange);
#if 0
	NSLog(@"%@ replaceCharactersInRange:%@ withString:\"%@\" (len=%d)", self, NSStringFromRange(aRange), aString, [aString length]);
#endif
	if(maxRange > _count)
		[NSException raise:NSRangeException format:@"Invalid location+length"];
	stringLength = (aString == nil) ? 0 : [aString length];
	offset = stringLength - aRange.length;
	if(_count + stringLength > _capacity + aRange.length)
		{ // needs to increase capacity
			_capacity += stringLength - aRange.length;
			if(_capacity < 2)
				_capacity = 2;
			_uniChars = objc_realloc(_uniChars, sizeof(unichar)*_capacity);
		}
	if(offset != 0)
		{
		unichar *src = _uniChars + maxRange;
		memmove(src + offset, src, (_count - aRange.location - aRange.length)*sizeof(unichar));	// shrink or expand original range
		}
	[aString getCharacters:&_uniChars[aRange.location]];
	_count += offset;
	if(_cString)
		{ // release cached cString
			objc_free(_cString);
			_cString=NULL;
		}
	_hash = 0;
#if 0
	NSLog(@"  -> \"%@\" offset=%d _count=%d", self, offset, _count);
#endif
}

- (void) insertString:(NSString*)aString atIndex:(unsigned)loc
{
	[self replaceCharactersInRange:(NSRange){loc, 0} withString:aString];
}

- (void) appendString:(NSString*)aString
{
	[self replaceCharactersInRange:(NSRange){_count, 0} withString:aString];
}

- (void) appendFormat:(NSString*)format, ...
{
	va_list ap;
	id tmp;
	va_start(ap, format);
	tmp = [[NSString alloc] initWithFormat:format arguments:ap];
	va_end(ap);
	[self appendString:tmp];
	[tmp release];
}

- (void) setString:(NSString*)aString
{
	int len = [aString length];
	if (_capacity < len)
		{
		_capacity = (len < 2) ? 2 : len;
		_uniChars = objc_realloc(_uniChars, sizeof(unichar)*_capacity);
		}
	[aString getCharacters: _uniChars];
	_count = len;
	if(_cString)
		{ // release cached cString
			objc_free(_cString);
			_cString=NULL;
		}
	_hash = 0;
}

- (id) initWithCoder:(id)aCoder
{
	unsigned cap;
	if([aCoder allowsKeyedCoding])
		{
		[self release];
		return [[aCoder decodeObjectForKey:@"NS.string"] retain];
		}
	[aCoder decodeValueOfObjCType: @encode(unsigned) at: &cap];
	[self initWithCapacity:cap];
	// FIXME: should we encode as UTF8?
	if ((_count = cap) > 0)
		[aCoder decodeArrayOfObjCType: @encode(unichar)
								count: _count
								   at: _uniChars];
	return self;
}

/**
 * Replaces all occurrences of the replace string with the by string,
 * for those cases where the entire replace string lies within the
 * specified searchRange value.<br />
 * The value of opts determines the direction of the search is and
 * whether only leading/trailing occurrances (anchored search) of
 * replace are substituted.<br />
 * Raises NSInvalidArgumentException if either string argument is nil.<br />
 * Raises NSRangeException if part of searchRange is beyond the end
 * of the receiver.
 */

- (unsigned int) replaceOccurrencesOfString: (NSString*)replace
								 withString: (NSString*)by
									options: (unsigned int)opts
									  range: (NSRange)searchRange
{
	NSRange	range;
	unsigned int count = 0;

	if (replace == nil)
		{
		[NSException raise: NSInvalidArgumentException
					format: @"%@ nil search string (%@)", NSStringFromSelector(_cmd), self];
		}
	if (by == nil)
		{
		[NSException raise: NSInvalidArgumentException
					format: @"%@ nil replace string (%@)", NSStringFromSelector(_cmd), self];
		}
	range = [self rangeOfString: replace options: opts range: searchRange];

	if (range.length > 0)
		{
		unsigned	byLen = [by length];

		do
			{
			count++;
			[self replaceCharactersInRange: range
								withString: by];
			if ((opts & NSBackwardsSearch) == NSBackwardsSearch)
				{
				searchRange.length = range.location - searchRange.location;
				}
			else
				{
				unsigned int	newEnd;

				newEnd = NSMaxRange(searchRange) + byLen - range.length;
				searchRange.location = range.location + byLen;
				searchRange.length = newEnd - searchRange.location;
				}

			range = [self rangeOfString: replace
								options: opts
								  range: searchRange];
			}
		while (range.length > 0);
		}
	return count;
}

@end /* GSMutableString */

//*****************************************************************************
//
// 		GSBaseCString
//
//*****************************************************************************

@implementation GSBaseCString

- (const char *) cString { return _cString; }

- (NSUInteger) cStringLength		{ return _count; }
- (NSUInteger) _baseLength					{ return _count; }

- (void) getCString:(char*)buffer
{
	//	NSAssert(buffer, @"getCString buffer is NULL");
	memcpy(buffer, _cString, _count);
	buffer[_count] = '\0';
}

- (void) getCString:(char*)buffer maxLength:(NSUInteger)maxLength
{
	if (maxLength > _count)
		maxLength = _count;
	memcpy(buffer, _cString, maxLength);
	buffer[maxLength] = '\0';
}

- (void) getCString:(char*)buffer
		  maxLength:(NSUInteger)maxLength
			  range:(NSRange)aRange
	 remainingRange:(NSRange*)leftoverRange
{
	int len;

	if (NSMaxRange(aRange) > _count)
		[NSException raise:NSRangeException format:@"Invalid location+length"];

	if (maxLength < aRange.length)
		{
		len = maxLength;
		if (leftoverRange)
			{
			leftoverRange->location = 0;
			leftoverRange->length = 0;
			}	}
	else
		{
		len = aRange.length;
		if (leftoverRange)
			{
			leftoverRange->location = aRange.location + maxLength;
			leftoverRange->length = aRange.length - maxLength;
			}	}

	memcpy(buffer, &_cString[aRange.location], len);
	buffer[len] = '\0';
}

- (unichar) characterAtIndex:(NSUInteger)index
{
	unidecoder d=decodeuni(__cStringEncoding);		// get appropriate encoder function
	unsigned char *c;
	if(!d) return 0;
	if (index >= _count)
		[NSException raise: NSRangeException
					format: @"in %s, index %d is out of range",
		 sel_getName(_cmd), index];
	// CHECKME/FIXME: this does not work for UTF8 as defaultCStringEncoding
	c=(unsigned char *) _cString+index;
	return (*d)(&c);
}

- (void) getCharacters:(unichar *)buffer
{
	unidecoder d=decodeuni(__cStringEncoding);		// get appropriate encoder function
	unsigned char *p, *e;
#if 0
	fprintf(stderr, "GSBaseCString getCharacters\n");
#endif
	if(!d)
		{
		NSLog(@"invalid default C string encoding %lu", (unsigned long)__cStringEncoding);
		return;
		}
	p=(unsigned char *) _cString;
	e=p+_count;	// end of C string
	while(p < e)
		*buffer++ = (*d)(&p);	// may read multi-bytes from C-string if UFT8
}

- (void) getCharacters:(unichar*)buffer range:(NSRange)aRange
{
	int e, i;
	unidecoder d=decodeuni(__cStringEncoding);		// get appropriate encoder function
	unsigned char *p;
	if(!d)
		return;
	if ((e = NSMaxRange(aRange)) > _count)
		[NSException raise:NSRangeException format:@"Invalid location+length"];
	p=(unsigned char *) _cString+aRange.location;
	for (i = aRange.location; i < e; i++)
		*buffer++ = (*d)(&p);
}

- (NSString *) _unicharString
{ // get as Unicode string
	unichar *s = objc_malloc(_count * sizeof(unichar));
	if(!s)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	[self getCharacters:s];
	return [[[NSString alloc] initWithCharactersNoCopy: s
												length: _count
										  freeWhenDone: YES] autorelease];
}

- (NSString*) substringWithRange:(NSRange)aRange
{
	if (NSMaxRange(aRange) > _count)
		[NSException raise:NSRangeException format:@"Invalid location+length"];

	return [_cStringClass stringWithCString: _cString + aRange.location
									 length: aRange.length];
}

- (void) encodeWithCoder:(NSCoder *)aCoder						// NSCoding protocol
{
	//	NSLog(@"@encode(unsigned char)=%s", @encode(unsigned char));
	[aCoder encodeValueOfObjCType:@encode(unsigned) at:&_count];
	// FIXME: should we always encode/decode UTF8 to become compatible with NSPortCoder?
	// or should this depend on [aCoder versionForClassName:@"NSString"] == 1
	if(_count > 0)
		[aCoder encodeArrayOfObjCType:@encode(unsigned char)
								count:_count
								   at:_cString];
}

- (id) initWithCoder:(NSCoder *)aCoder
{
	if([aCoder allowsKeyedCoding])
		{
		[self release];
		return [[aCoder decodeObjectForKey:@"NS.string"] mutableCopy];
		}
	[aCoder decodeValueOfObjCType:@encode(unsigned) at:&_count];
	if (_count > 0)
		{
		_cString = objc_malloc(_count + 1);
		[aCoder decodeArrayOfObjCType:@encode(unsigned char)
								count:_count
								   at:_cString];
		_cString[_count] = '\0';
		}

	return self;
}

@end /* GSBaseCString */

//*****************************************************************************
//
// 		GSCString
//
//*****************************************************************************

@implementation GSCString

+ (id) allocWithZone:(NSZone *) z
{
	return (GSCString *) NSAllocateObject(self, 0, z);
}

- (id) initWithCStringNoCopy:(char*)byteString			// OPENSTEP designated
					  length:(unsigned int)length		// initializer
				freeWhenDone:(BOOL)flag
{
	if(byteString[length] != 0)
		{
		NSLog(@"warning: initWithCStringNoCopy is not 0-terminated: %p[%u]", byteString, length);
		NSLog(@"warning: initWithCStringNoCopy is not 0-terminated: %.*s", length, byteString);
		}
	_count = length;
	_cString = byteString;
	_freeWhenDone = flag;
	return self;
}

- (id) initWithCharactersNoCopy:(unichar*)chars
						 length:(unsigned int)length
				   freeWhenDone:(BOOL)flag
{
	[self release];
	return (GSCString *) [[GSString alloc] initWithCharactersNoCopy: chars
															 length: length
													   freeWhenDone: flag];
}

- (id) initWithString:(NSString*)string
{
	NSUInteger length = [string cStringLength];
	char *buf = objc_malloc(length+1);  						// getCString appends a nul
	if(!buf)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	[string getCString: buf];
	buf[length]=0;
	return [self initWithCStringNoCopy:buf length:length freeWhenDone:YES];
}

- (void) dealloc
{
	if(_freeWhenDone && _cString)
		objc_free(_cString);
	[super dealloc];
}

- (id) mutableCopyWithZone:(NSZone *) z
{
	unichar *s = objc_malloc(_count * sizeof(unichar));
	if(!s)
		[NSException raise: NSMallocException format: @"Unable to allocate"];
	[self getCharacters:s];
	return [[_mutableStringClass alloc] initWithCharactersNoCopy: s
														  length: _count
													freeWhenDone: YES];
}

- (NSUInteger) hash
{
	return _hash == 0 ? (_hash = _strHashImp(self,@selector(hash))) : _hash;
}

- (BOOL) isEqual:(id)obj
{ // self is a C string (other side must be convertible)
	Class c;
	if (obj == self)
		return YES;
	c = object_getClass(obj);	// peer class
	if (c == _cStringClass)
		{ // compare two C strings
			if (_count != ((NSString*)obj)->_count)
				return NO;
			if (memcmp(_cString, ((NSString*)obj)->_cString, _count) == 0)
				return YES;	// byte sequence is the same
			if (_hash == 0)
				_hash = _strHashImp(self, @selector(hash));
			if (((GSCString*)obj)->_hash == 0)
				((GSCString*)obj)->_hash =_strHashImp(obj,@selector(hash));
			if (_hash != ((GSCString*)obj)->_hash)
				return NO;
			return YES;
		}
	else if(c == _constantStringClass)
		{ // compare to a constant C string
			if(_count != ((NSString*)obj)->_count)
				return NO;
			if(memcmp(_cString, ((NSString*)obj)->_cString,_count) != 0)
				return NO;
			return YES;
		}
	if (c && _classIsKindOfClass(c, _nsStringClass))
		{ // compare to a unicode string
			if(!((NSString*)obj)->_cString)
				{
				if(((NSString*)obj)->_count > 0)
					{
					NS_DURING
					[obj cString];				// convert to a C str (if possible)
					NS_HANDLER
					return NO;	// we were not able to convert the other string to a C string - so they can't be equal
					NS_ENDHANDLER
					}
				else							// str but does not yet have a
					return NO;					// C str backing, create it
				}
		}
	if (_count != ((NSString*)obj)->_count)
		return NO;
	if (memcmp(_cString, ((NSString*)obj)->_cString, _count) == 0)
		return YES;
	return NO;
}

- (BOOL) isEqualToString:(NSString*)aString
{
	Class c;
	if (aString == nil)
		return NO;
	if (aString == self)
		return YES;
	c = object_getClass(aString);	// peer class

	if (c == _cStringClass)
		{
		GSCString *other = (GSCString*)aString;

		if (_count != aString->_count)
			return NO;
		if (_hash == 0)
			_hash = _strHashImp(self, @selector(hash));
		if (other->_hash == 0)
			other->_hash = _strHashImp(aString, @selector(hash));
		if (_hash != other->_hash)
			return NO;

		return (memcmp(_cString,aString->_cString,_count) != 0) ? NO : YES;
		}
	else if (c == _constantStringClass)
		{
		if (_count != aString->_count)
			return NO;
		if(memcmp(_cString, aString->_cString, _count) != 0)
			return NO;
		return YES;
		}
	if (_count != aString->_count)
		return NO;
	if(!aString->_cString)
		{
		if(aString->_count > 0)
			{
			NS_DURING
			[aString cString];				// if an object is a unichar str but does not yet have a C str backing, create one
			NS_HANDLER
			return NO;	// we were not able to convert the other string to a C string - so it can't be equal
			NS_ENDHANDLER
			}
		else
			return NO;
		}
	if (memcmp(_cString, aString->_cString, _count) == 0)
		return YES;
	return NO;
}

- (NSStringEncoding) fastestEncoding
{
	return ((__cStringEncoding == NSASCIIStringEncoding) || (__cStringEncoding == NSISOLatin1StringEncoding))
	? __cStringEncoding : NSUnicodeStringEncoding;
}

- (NSStringEncoding) smallestEncoding		{ return __cStringEncoding; }
- (NSUInteger) _baseLength							{ return _count; }

@end /* GSCString */

//*****************************************************************************
//
// 		NXConstantString
//
//*****************************************************************************

#ifdef __APPLE__

/* this allows us to compile on MacOS X - but it does not work */
/* described by http://jens.ayton.se/blag/objc-constant-objects/#objc-constant-objects-footnote-1 */
int __CFConstantStringClassReference [];

#else

@implementation _NSConstantStringClassName

- (void) dealloc						{ return; [super dealloc]; }
- (id) retain							{ return self; }
- (oneway void) release					{ return; }
- (id) autorelease						{ return self; }
- (id) copyWithZone:(NSZone *) z		{ return self; }
- (NSStringEncoding) fastestEncoding	{ return NSASCIIStringEncoding; }
- (NSStringEncoding) smallestEncoding	{ return NSASCIIStringEncoding; }

- (BOOL) isEqual:(id)obj
{ // self is a constant C string
	Class c;

	if (obj == self)
		return YES;
	c = object_getClass(obj);	// peer class

	if (c == _cStringClass || c == _constantStringClass)
		{
		if(_count != ((NSString*)obj)->_count)
			return NO;
		if(memcmp(_cString, ((NSString*)obj)->_cString, _count) != 0)
			return NO;
		return YES;
		}

	if (_classIsKindOfClass(c, _nsStringClass))
		{
		if (_count != ((NSString*)obj)->_count)
			return NO;
		if(!((NSString*)obj)->_cString)
			{
			if(((NSString*)obj)->_count > 0)
				[obj cString];				// if an object is a unichar
			else							// str but does not yet have a
				return YES;	/* both are empty */	// C str backing, create it
			}
		if (memcmp(_cString, ((NSString*)obj)->_cString, _count) == 0)
			return YES;
		}
	return NO;
}

- (BOOL) isEqualToString:(NSString*)aString
{
	if (aString == nil)
		return NO;
	if (aString == self)
		return YES;
	if (_count != aString->_count)
		return NO;
	if(!aString->_cString)
		{
			if(aString->_count > 0)
				[aString cString];					// if an object is a unichar
			else									// str but does not yet have a
				return YES; /* both are empty */	// C str allocated, create it
		}
	
	return (memcmp(_cString, aString->_cString, _count) == 0) ? YES : NO;
}

@end /* NXConstantString */

#endif
