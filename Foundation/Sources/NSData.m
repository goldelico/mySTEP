/*
 NSData.m

 Stream of bytes class for serialization and persistance

 Copyright (C) 1995, 1996, 1997 Free Software Foundation, Inc.

 Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	March 1995
 GNUstep:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
 Date:	September 1997

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

/*
 Rewritten to use the class cluster architecture as in OPENSTEP.

 NB. In our implementaion we require an extra primitive for the
 NSMutableData subclasses.  This new primitive method is the
 [-_setCapacity:] method, and it differs from [-setLength:]
 as follows -

 [-setLength:]
 clears bytes when the allocated buffer grows
 never shrinks the allocated buffer capacity
 [-setCapacity:]
 doesn't clear newly allocated bytes
 sets the size of the allocated buffer.

 The actual class hierarchy is as follows -

 NSData					Abstract base class.
 NSDataStatic			Concrete class static buffers.
 NSDataMalloc			Concrete class.
 NSDataMappedFile		Memory mapped files.
 NSDataShared		Extension for shared memory.
 NSMutableData			Abstract base class.
 NSMutableDataMalloc		Concrete class.
 NSMutableDataShared		Extension for shared memory.

 NSMutableDataMalloc MUST share it's initial instance variable layout
 with NSDataMalloc so that it can use the 'behavior' code to inherit
 methods from NSDataMalloc.

 Since all the other subclasses are based on NSDataMalloc or
 NSMutableDataMalloc, we can put most methods in here and not
 bother with duplicating them in the other classes.
 */

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSByteOrder.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSURL.h>
#import "NSPrivate.h"
#include <zlib.h>

#if	HAVE_MMAP
#include <sys/mman.h>
#include <fcntl.h>
#ifndef	MAP_FAILED
#define	MAP_FAILED	((void*)-1)			// Failure address
#endif /* MAP_FAILED */
@class	NSDataMappedFile;
#endif /* HAVE_MMAP */

#if	HAVE_SHMCTL
#include <sys/ipc.h>
#include <sys/shm.h>
#define	VM_RDONLY	0644				// self read/write - other readonly
#define	VM_ACCESS	0666				// read/write access for all
#endif /* HAVE_SHMCTL */

// Some static variables to cache classes and methods for quick access -
// these are set up at process startup or in [NSData +initialize]
static SEL appendSel;
static Class dataMalloc;
static Class mutableDataMalloc;
static IMP appendImp;

/*
 *	NB, The start of the NSMutableDataMalloc instance variables must be
 *	identical to that of NSDataMalloc in order to inherit its methods.
 */

@interface	NSDataStatic : NSData
{
	void *bytes;
	NSUInteger length;
}
@end

@interface	NSDataMalloc : NSDataStatic
@end

// FIXME: NSMutableDataMalloc is NOT a subclass of NSMutableData!

@interface	NSMutableDataMalloc : NSDataMalloc
{
	NSUInteger capacity;
	NSUInteger growth;
}
// Increase capacity to at least the specified minimum value.
- (void) _grow:(unsigned)minimum;

@end

#if	HAVE_MMAP
// FIXME: why is this a NSDataMalloc subclass?
@interface	NSDataMappedFile : NSDataMalloc
@end
#endif

#if	HAVE_SHMCTL
@interface	NSDataShared : NSDataMalloc
{
	int shmid;
}
- (id) initWithShmID:(int)anId length:(unsigned)bufferSize;
@end

@interface	NSMutableDataShared : NSMutableDataMalloc
{
	int shmid;
}
- (id) initWithShmID:(int)anId length:(unsigned)bufferSize;
@end
#endif


@implementation NSData

+ (void) initialize
{
#if 0
	NSLog(@"NData initialize");
#endif
	if (self == [NSData class])
		{
		dataMalloc = [NSDataMalloc class];
		mutableDataMalloc = [NSMutableDataMalloc class];
		appendSel = @selector(appendBytes:length:);
		appendImp = [mutableDataMalloc instanceMethodForSelector: appendSel];
		}
}

+ (id) allocWithZone:(NSZone *) z
{
#if 0
	id p=NSAllocateObject(dataMalloc, 0, z);
	NSLog(@"allocated %@: %p", NSStringFromClass(self), p);	// warning: this leads to recursion in NSConcreteDate
	return p;
#endif
	return (id) NSAllocateObject(dataMalloc, 0, z);
}

+ (id) data
{
	return [[[NSDataStatic alloc] initWithBytesNoCopy:NULL length:0] autorelease];
}

+ (id) dataWithBytes:(const void*)bytes length:(NSUInteger)length
{
	return [[[dataMalloc alloc] initWithBytes:bytes length:length] autorelease];
}

+ (id) dataWithBytesNoCopy:(void*)bytes length:(NSUInteger)length
{
	return [[[dataMalloc alloc] initWithBytesNoCopy:bytes
											 length:length] autorelease];
}

+ (id) dataWithBytesNoCopy:(void*)bytes length:(NSUInteger)length freeWhenDone:(BOOL)flag;
{
	if(flag)
		return [[[dataMalloc alloc] initWithBytesNoCopy:bytes length:length] autorelease];
	return [[[NSDataStatic alloc] initWithBytesNoCopy: bytes length: length] autorelease];
}

+ (id) dataWithContentsOfFile:(NSString*)path
{
#if 0
	NSLog(@"dataWithContentsOfFile: %@", path);
#endif
	return [[[dataMalloc alloc] initWithContentsOfFile: path] autorelease];
}

+ (id) dataWithContentsOfFile:(NSString*)path options:(NSDataReadingOptions) mask error:(NSError **) error;
{
#if 0
	NSLog(@"dataWithContentsOfFile: %@", path);
#endif
	return [[[dataMalloc alloc] initWithContentsOfFile: path options:mask error:error] autorelease];
}

+ (id) dataWithContentsOfURL:(NSURL*)url
{
	return [[[dataMalloc alloc] initWithContentsOfURL: url] autorelease];
}

+ (id) dataWithContentsOfURL:(NSURL*)url options:(NSDataReadingOptions) mask error:(NSError **) error;
{
	return [[[dataMalloc alloc] initWithContentsOfURL: url options:mask error:error] autorelease];
}

+ (id) dataWithContentsOfMappedFile:(NSString*)path
{
#if	HAVE_MMAP
	id a = [NSDataMappedFile alloc];
#else
	id a = [dataMalloc alloc];
#endif
	return [[a initWithContentsOfMappedFile: path] autorelease];
}

+ (id) dataWithData:(NSData*)data
{
	return [[[dataMalloc alloc] initWithBytes: [data bytes]
									   length: [data length]] autorelease];
}

- (id) init
{
	return [self initWithBytesNoCopy:NULL length: 0];
}

- (id) initWithBytes:(const void*)aBuffer
			  length:(NSUInteger)bufferSize				{ return SUBCLASS }
- (id) initWithContentsOfFile:(NSString *)path			{ return SUBCLASS }
- (id) initWithContentsOfMappedFile:(NSString *)path	{ return SUBCLASS }

- (id) initWithData:(NSData*)data
{
	return [self initWithBytes:[data bytes] length:[data length]];
}

- (id) _initWithBase64String:(NSString *) string;
{ // we need that for unarchiving NSData objects in XML format (and somewhere else)
	NSUInteger len=(3*[string length])/4+2;
	const char *str=[string UTF8String];
	char *bytes=objc_malloc(len);	// at least as much as we really need (this does not exclude skipped padding and whitespace)
	char *bp=bytes;
	int b;
	int cnt=0;
	int pad=0;
	unsigned long byte=0;
#if 0
	NSLog(@"_initWithBase64String:%@", string);
#endif
	NSAssert(string, @"does not accept a nil string");
	while((b=*str++))
		{
		int bit6;
		if(b >= 'A' && b <= 'Z')
			bit6=b-'A';
		else if(b >= 'a' && b <= 'z')
			bit6=b+(26-'a');
		else if(b >= '0' && b <= '9')
			bit6=b+(52-'0');
		else switch(b)
			{
				case '+':	bit6=62; break;
				case '/':	bit6=63; break;
				case '=':	pad++; continue;	// handle padding
				case ' ':
				case '\t':
				case '\r':
				case '\n':
				continue;	// ignore white space
				default:
				NSLog(@"NSData: invalid base64 character %c (%02x)", b, b&0xff);
				objc_free(bytes);
				[self release];
				return nil;	// invalid character
			}
		if(pad)
			{ // invalid character follows after any padding
				objc_free(bytes);
				[self release];
				return nil;
			}
		byte=(byte<<6)+bit6;	// append next 6 bits
		if(++cnt == 4)
			{ // 4 character ‡ 6 bit = 24 bits decoded
				*bp++=(byte>>16);
				*bp++=(byte>>8);
				*bp++=byte;
				byte=0;
				cnt=0;
			}
		}
	if(pad == 2 && cnt != 3)
		{ // one more byte (ABC=)
			if((byte&0xffffff00) > 0)
				{ [self release]; return nil; }	// bad bits...
			*bp++=byte;
		}
	else if(pad == 1 && cnt != 2)
		{ // two more bytes (AB==)
			if((byte&0xffff0000) > 0)
				{ [self release]; return nil; }	// bad bits...
			*bp++=(byte>>8);
			*bp++=byte;
		}
	else if(!(pad == 0 && cnt == 0))
		{ // there is bad padding or some partial byte lying around
#if 0
			NSLog(@"pad=%d", pad);
			NSLog(@"cnt=%d", cnt);
			NSLog(@"byte=%06x", byte);
			NSLog(@"string=%@", string);
#endif
			objc_free(bytes);
			[self release];
			return nil;
		}
#if 0
	NSLog(@"new length=%u", (bp-bytes));
#endif
	if(bp == bytes)
		{
		objc_free(bytes);	// not used...
		return [self initWithBytesNoCopy:NULL length:0];	// empty data
		}
	NSAssert(bp-bytes <= len, @"buffer overflow");
	bytes=objc_realloc(bytes, (bp-bytes));	// shrink as needed
	return [self initWithBytesNoCopy:bytes length:(bp-bytes)]; // take ownership
}

- (NSString *) _base64String
{ // convert into base64 string
	NSMutableString *result=[NSMutableString stringWithCapacity:3*([self length]/4+1)];
	const char *src = [self bytes];
	NSInteger length = [self length];
	long bytes = 0;
	while(length > 0)
		{
		int i;
		for(i=0; i<length && i<3; i++)
			bytes=(bytes<<8)+(*src++);	// collect bytes
		for(i=0; i<4; i++)
			{
			int bits=bytes&0x3f;
			bytes >>= 6;
			if(bits < 26)
				bits += 'A';
			else if(bits < 2*26)
				bits += 'a'-26;
			else if(bits < 2*26+10)
				bits += '0'-2*26;
			else if(bits == 62)
				bits='+';
			else
				bits='/';
			[result appendFormat:@"%c", bits];
			// CHECKME: handle padding
			if(i == 2 && length == 2)
				{
				[result appendString:@"="];
				break;
				}
			if(i == 1 && length == 1)
				{
				[result appendString:@"=="];
				break;
				}
			}
		length-=4;
		}
	return result;
}

- (const void*) bytes	{ SUBCLASS return NULL; }

- (void *) _bytesWith0;
{ // bytes with 0-suffix
	unsigned len=[self length];
	void *buffer=_autoFreedBufferWithLength(len+1);
	memcpy(buffer, (char *)[self bytes], len);	// get bytes
	((char *) buffer)[len]='\0';
	return buffer;
}

- (NSString *) description
{
	const char *src = [self bytes];
	int i;
	int length = [self length];
	int l=2 * length + (length+3)/4 + 3;	// 2 hext digits, 1 space every 4 bytes, < > and '\0'
	char *dest, *bp;	// build a cString and convert it to an NSString
#if 0
	fprintf(stderr, "NSData description length=%d l=%d\n", length, l);
#endif
	if ((bp=dest=(char *) objc_malloc(l)) == NULL)
		[NSException raise: NSMallocException format: @"malloc failed in NSData -description (length=%d l=%d)", length, l];
	*bp++ = '<';
	for (i = 0; i < length; i++)
		{
		sprintf(bp, "%02x", src[i]&0xff);
		bp+=2;
		if((i&0x3) == 3 && i != length-1)
			*bp++ = ' ';					// if we've just finished a block
		NSAssert(bp-dest < l, @"buffer overflow");
		}
	*bp++ = '>';
	*bp = 0;	// 0-terminate
	NSAssert(bp-dest < l, @"buffer overflow");
#if 0
	fprintf(stderr, "   bp-dest=%d\n", bp-dest);
#endif

	return [[[NSString alloc] initWithCStringNoCopy:dest length:bp-dest freeWhenDone:YES] autorelease];
}

- (void) getBytes:(void*)buffer
{
	[self getBytes:buffer range:NSMakeRange(0, [self length])];
}

- (void) getBytes:(void*)buffer length:(NSUInteger)length
{
	[self getBytes:buffer range:NSMakeRange(0, length)];
}

- (void) getBytes:(void*)buffer range:(NSRange)aRange
{ // Check for 'out of range' errors.  This code assumes that the NSRange location and length types will remain unsigned (hence the lack of a less-than-zero check).
	int s = [self length];
	if(NSMaxRange(aRange) > s)
		// FIXME: should we simply limit the range and don't throw an exception?
		[NSException raise: NSRangeException
					format: @"-[NSData getBytes:range:] Range: %@ Size: %d", NSStringFromRange(aRange), s];	// goes behind end
	memcpy(buffer, ((char *)[self bytes]) + aRange.location, aRange.length);
}

// could be optimized to avoid copying if we know that we don't have mutable data and handle responsibility of the buffer

- (NSData*) subdataWithRange:(NSRange)aRange
{ // Check for 'out of range' errors before calling [-getBytes:range:] so that we can be sure that we don't get a range exception after we have alloc'd memory.
	void *buffer;
	unsigned l = [self length];	if (aRange.location > l || aRange.length > l || NSMaxRange(aRange) > l)
		[NSException raise: NSRangeException
					format: @"-[NSData subdataWithRange:] Range: (%u, %u) Size: %d",
		 aRange.location, aRange.length, l];

	if ((buffer = objc_malloc(aRange.length)) == 0)
		[NSException raise: NSMallocException format: @"malloc failed in -subdataWithRange"];

	[self getBytes:buffer range:aRange];

	return [NSData dataWithBytesNoCopy: buffer length: aRange.length];
}

- (NSUInteger) hash					{ return [self length]; }

- (BOOL) isEqual:(id) anObject
{
	if(anObject == self)
		return YES;
	if([anObject isKindOfClass: [NSData class]])
		return [self isEqualToData: anObject];
	return NO;
}

- (BOOL) isEqualToData:(NSData*)other;
{													// Querying a Data Object
	int len;
	if(other == self)
		return YES;
	if((len = [self length]) != [other length])
		return NO;
	return (memcmp([self bytes], [other bytes], len) ? NO : YES);
}

- (NSUInteger) length					{ SUBCLASS return 0; }

- (BOOL) writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile
{
	char p[PATH_MAX+8];
	const char *r=[path fileSystemRepresentation];
	FILE *f;
	int c;

	// Use the path name of the destination file as a
	// prefix for the mktemp() call so that we can be
	// sure that both files are on the same filesystem
	// and the subsequent rename() will work.
	if (useAuxiliaryFile)
		{
		int fd;
		strcpy(p, r);
		strcat(p, ".XXXXXX");
		if ((fd = mkstemp(p)) < 0)
			{
			NSLog(@"mktemp (%s) failed - %s", p, strerror(errno));
			return NO;
			}
		fchmod(fd, 0644);	// make it readable by default
		f = fdopen(fd, "w");
		}
	else
		{
		strcpy(p, r);
		f = fopen(p, "w");
		}
	if (f == NULL)
		{
		NSLog(@"fopen(%s, \"w\") failed - %s", p, strerror(errno));
		return NO;
		}
	// Now we try and write the NSData's bytes to the
	// file.  Here `c' is the number of bytes which
	// were successfully written to the file in the
	// fwrite() call.
	c = fwrite([self bytes], sizeof(char), [self length], f);

	if (c < [self length])
		{										// failed to write all of data
			NSLog(@"fwrite (%s) failed - %s", p, strerror(errno));
			return NO;
		}

	if ((fclose(f)) != 0)					// close the file and deal with
		{										// errors should they occur
			NSLog(@"fclose (%s) failed - %s", p, strerror(errno));
			return NO;
		}								// If we used a temporary file, we need
										// to rename() it to be the real file
	if (useAuxiliaryFile && (rename(p, r) != 0))
		{
		NSLog(@"rename (%s, %s) failed - %s", p, r, strerror(errno));
		return NO;
		}

	return YES;	// success
}

- (BOOL) writeToURL:(NSURL*)url atomically:(BOOL)useAuxiliaryFile;
{
	if(![url isFileURL])
		return NO;	// can't write otherwise
	return [self writeToFile:[url path] atomically:useAuxiliaryFile];
}

///// FIXME: deprecated???

// Deserializing Data
- (NSUInteger) deserializeAlignedBytesLengthAtCursor:(NSUInteger*)cursor
{
	return (unsigned)[self deserializeIntAtCursor: cursor];
}

- (void) deserializeBytes:(void*)buffer
				   length:(NSUInteger)bytes
				 atCursor:(NSUInteger*)cursor
{
	[self getBytes:buffer range:(NSRange){*cursor, bytes}];
	*cursor += bytes;
}

- (void) deserializeDataAt:(void*)data
				ofObjCType:(const char*)type
				  atCursor:(NSUInteger*)cursor
				   context:(id <NSObjCTypeSerializationCallBack>)callback
{
	if (!type || !data)
		return;

	switch(*type)
	{
		case _C_ID:
		{
		[callback deserializeObjectAt:data
						   ofObjCType:type
							 fromData:self
							 atCursor:cursor];
		return;
		}
		case _C_CHARPTR:
		{
		int len = [self deserializeIntAtCursor: cursor];

		if (len == -1)
			{
			*(const char**)data = NULL;
			return;
			}
		else
			{
			unsigned l = (len + 1) * sizeof(char);

			*(char**)data = (char*)objc_malloc(l);
			[[[dataMalloc alloc] initWithBytesNoCopy: *(void**)data
											  length: l] autorelease];
			}

		[self deserializeBytes:*(char**)data length:len atCursor:cursor];
		(*(char**)data)[len] = '\0';
		return;
		}
		case _C_ARY_B:
		{
		unsigned offset = 0;
		unsigned size;
		unsigned count = atoi(++type);
		unsigned i;

		while (isdigit(*type))
			type++;

		size = objc_sizeof_type(type);

		for (i = 0; i < count; i++)
			{
			[self deserializeDataAt: (char*)data + offset
					  ofObjCType: type
						   atCursor: cursor
					  context: callback];
			offset += size;
			}
		return;
		}
		case _C_STRUCT_B:
		{
		int offset = 0;

		while (*type != _C_STRUCT_E && *type++ != '='); // skip "<name>="
		for (;;)
			{
			[self deserializeDataAt: ((char*)data) + offset
					  ofObjCType: type
						   atCursor: cursor
					  context: callback];
			offset += objc_sizeof_type(type);
			type = objc_skip_typespec(type);
			if (*type != _C_STRUCT_E)
				{
				int	align = objc_alignof_type(type);
				int	rem = offset % align;

				if (rem != 0)
					offset += align - rem;
				}
			else
				break;
			}
		return;
		}
		case _C_PTR:
		{
		unsigned len = objc_sizeof_type(++type);

		*(char**)data = (char*)objc_malloc(len);
		[[[dataMalloc alloc] initWithBytesNoCopy: *(void**)data
										  length: len ] autorelease];
		[self deserializeDataAt: *(char**)data
				  ofObjCType: type
					   atCursor: cursor
				  context: callback];
		return;
		}
		case _C_CHR:
		case _C_UCHR:
		{
		[self deserializeBytes: data
				  length: sizeof(unsigned char)
					  atCursor: cursor];
		return;
		}
		case _C_SHT:
		case _C_USHT:
		{
		unsigned short ns;

		[self deserializeBytes: &ns
				  length: sizeof(unsigned short)
					  atCursor: cursor];
		*(unsigned short*)data = NSSwapBigShortToHost(ns);
		return;
		}
		case _C_INT:
		case _C_UINT:
		{
		unsigned ni;

		[self deserializeBytes:&ni
				  length:sizeof(unsigned)
					  atCursor:cursor];
		*(unsigned*)data = NSSwapBigIntToHost(ni);
		return;
		}
		case _C_LNG:
		case _C_ULNG:
		{
		unsigned long nl;

		[self deserializeBytes: &nl
						length: sizeof(unsigned long)
					  atCursor: cursor];
		*(unsigned long*)data = NSSwapBigLongToHost(nl);
		return;
		}
#ifdef	_C_LNG_LNG
		case _C_LNG_LNG:
		case _C_ULNG_LNG:
		{
		unsigned long long nl;

		[self deserializeBytes: &nl
						length: sizeof(unsigned long long)
					  atCursor: cursor];
		*(unsigned long long*)data = NSSwapBigLongLongToHost(nl);
		return;
		}
#endif
		case _C_FLT:
		{
		NSSwappedFloat nf;

		[self deserializeBytes: &nf
						length: sizeof(NSSwappedFloat)
					  atCursor: cursor];
		*(float*)data = NSSwapBigFloatToHost(nf);
		return;
		}
		case _C_DBL:
		{
		NSSwappedDouble nd;

		[self deserializeBytes: &nd
						length: sizeof(NSSwappedDouble)
					  atCursor: cursor];
		*(double*)data = NSSwapBigDoubleToHost(nd);
		return;
		}
		case _C_CLASS:
		{
		unsigned n;

		[self deserializeBytes:&n length:sizeof(unsigned) atCursor:cursor];
		if ((n = NSSwapBigIntToHost(n)) == 0)
			*(Class*)data = 0;
		else
			{
			char name[n+1];
			Class c;

			[self deserializeBytes:name length:n atCursor:cursor];
			name[n] = '\0';
			if ((c = objc_lookUpClass(name)) == 0)
				[NSException raise: NSInternalInconsistencyException
							format: @"can't find class - %s", name];

			*(Class*)data = c;
			}
		return;
		}
		case _C_SEL:
		{
		unsigned t, n;

		[self deserializeBytes:&n length:sizeof(unsigned) atCursor:cursor];
		n = NSSwapBigIntToHost(n);
		[self deserializeBytes:&t length:sizeof(unsigned) atCursor:cursor];
		t = NSSwapBigIntToHost(t);
		if (n == 0)
			*(SEL*)data = 0;
		else
			{
			char name[n+1], types[t+1];
			SEL	sel;

			[self deserializeBytes:name length:n atCursor:cursor];
			name[n] = '\0';
			[self deserializeBytes:types length:t atCursor:cursor];
			types[t] = '\0';

			if (t)
				// FIXME:
				sel = sel_getTypedSelector(name);
			else
				sel = sel_registerName(name);
			if (sel == 0)
				[NSException raise: NSInternalInconsistencyException
							format: @"can't find sel with name '%s' "
				 @"and types '%s'", name, types];
			*(SEL*)data = sel;
			}
		return;
		}
		default:
		[NSException raise: NSGenericException
					format: @"Unknown type to deserialize - '%s'", type];
	}
}

- (int) deserializeIntAtCursor:(NSUInteger*)cursor
{
	unsigned int ni;
	[self deserializeBytes: &ni length: sizeof(ni) atCursor: cursor];
	return NSSwapBigIntToHost(ni);
}

- (int) deserializeIntAtIndex:(NSUInteger)index
{
	unsigned int ni;
	[self deserializeBytes: &ni length: sizeof(ni) atCursor: &index];
	return NSSwapBigIntToHost(ni);
}

- (void) deserializeInts:(int*)intBuffer
				   count:(NSUInteger)numInts
				atCursor:(NSUInteger*)cursor
{
	unsigned i;
	[self deserializeBytes: &intBuffer
					length: numInts * sizeof(*intBuffer)
				  atCursor: cursor];
	for (i = 0; i < numInts; i++)
		intBuffer[i] = NSSwapBigIntToHost(intBuffer[i]);
}

- (void) deserializeInts:(int*)intBuffer
				   count:(NSUInteger)numInts
				 atIndex:(NSUInteger)index
{
	unsigned i;
	[self deserializeBytes: &intBuffer
					length: numInts * sizeof(*intBuffer)
				  atCursor: &index];
	for (i = 0; i < numInts; i++)
		intBuffer[i] = NSSwapBigIntToHost(intBuffer[i]);
}
// NSCopying, NSMutableCopying
- (id) copyWithZone:(NSZone *) zone
{
	if(![self isKindOfClass: [NSMutableData class]])
		return [self retain];
	return [[dataMalloc alloc] initWithBytes:[self bytes]
									  length:[self length]];
}

- (id) mutableCopyWithZone:(NSZone *) zone
{
	return [[mutableDataMalloc alloc] initWithBytes: [self bytes]
											 length: [self length]];
}

- (void) encodeWithCoder:(NSCoder*)coder				{ [coder encodeDataObject:self]; }

- (id) initWithCoder:(NSCoder*)coder
{
	[self release];
	return [[coder decodeDataObject] retain];
}

- (id) initWithBytesNoCopy:(void*)bytes
					length:(NSUInteger)length			{ SUBCLASS return nil; }

- (id) initWithBytesNoCopy:(void*)bytes length:(NSUInteger)length freeWhenDone:(BOOL)flag;
{
	if(flag)
		return [self initWithBytesNoCopy:bytes length:length]; // take ownership
	[self release];
	return [[NSDataStatic alloc] initWithBytesNoCopy:bytes length:length]; // static data
}

- (id) initWithContentsOfURL:(NSURL *)url
{
	return [self initWithContentsOfURL:url options:0 error:NULL];
}

- (id) initWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)mask error:(NSError **)errorPtr;
{
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:path] options:mask error:errorPtr];
}

- (id) initWithContentsOfURL:(NSURL *)url options:(NSDataReadingOptions)mask error:(NSError **)errorPtr;
{
	NSURLRequest *request;
	NSURLResponse *response;
	NSData *data;
	NSError *localError;
	if([url isFileURL])
		// FIXME: handle error
		return [self initWithContentsOfMappedFile:[url path]];	// default to a mapped file
	if(!errorPtr)
		errorPtr=&localError;
	request=[NSURLRequest requestWithURL:url];
	data=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:errorPtr];
#if 0
	NSLog(@"initWithContentsOfURL: %@ done data=%p error=%@", url, data, *errorPtr);
#endif
	// could analyse response for content-type, content-encoding...
	[self release];
#if 0
	NSLog(@"received data length=%lu", (unsigned long)[data length]);
#endif
	return [data retain];
}

- (BOOL) writeToFile:(NSString *)path options:(NSDataWritingOptions)mask error:(NSError **)errorPtr;
{
	return [self writeToURL:[NSURL fileURLWithPath:path] options:mask error:errorPtr];
}

- (BOOL) writeToURL:(NSURL *)aURL options:(NSDataWritingOptions)mask error:(NSError **)errorPtr;
{
	NIMP;
	return NO;
}
@end

@implementation NSData (Zip)

- (NSData *) _inflate;
{
	z_stream strm;
	int err;
	NSMutableData *result=[NSMutableData dataWithCapacity:[self length]];	// estimate required length
	unsigned char buf[512];
#if 0
	NSLog(@"%@ raw=%@", NSStringFromClass([self class]), _source);
#endif
	//	[_source writeToFile:@"stream.zip" atomically:NO];
	strm.zalloc=Z_NULL;	// use internal memory allocator
	strm.zfree=Z_NULL;
	strm.opaque=NULL;
	strm.next_in=(unsigned char *) [self bytes];
	strm.avail_in=[self length];
	strm.next_out=buf;
	strm.avail_out=sizeof(buf);
	if(inflateInit(&strm) != Z_OK)
		{ // some error
			return nil;
		}
	while(YES)
		{
		err=inflate(&strm, Z_NO_FLUSH);
		if(err == Z_OK || err == Z_STREAM_END)
			{
#if 0
			NSLog(@"Z_OK (%d bytes)", sizeof(buf)-strm.avail_out);
#endif
			[result appendBytes:buf length:sizeof(buf)-strm.avail_out];
			if(err == Z_STREAM_END)
				break;
			strm.next_out=buf;
			strm.avail_out=sizeof(buf);
			continue;
			}
		NSLog(@"Z_ERROR %d: %s", err, strm.msg);
		inflateEnd(&strm);
		return nil;
		}
	if(inflateEnd(&strm) != Z_OK)
		{ // some error
			return nil;
		}
	return result;
}

@end

// Top of concrete implementations of
// hierarchy. Contains efficient
@implementation	NSDataStatic			// implementations of most methods.

+ (id) allocWithZone:(NSZone *) z
{
	return (id) NSAllocateObject(self, 0, z);
}

- (id) copyWithZone:(NSZone *) zone								{ return [self retain]; }

- (id) mutableCopyWithZone:(NSZone *) zone
{
	return [[mutableDataMalloc alloc] initWithBytes: bytes length: length];
}

- (id) init
{
	return [self initWithBytesNoCopy:NULL length:0];
}

- (id) initWithBytesNoCopy:(void*)aBuffer length:(NSUInteger)bufferSize
{
	bytes = aBuffer;
	length = bufferSize;
	return self;
}

// NSCoding	Protocol
- (Class) classForArchiver			{ return dataMalloc; }		// Not static
- (Class) classForCoder				{ return dataMalloc; }		// when decoded
- (Class) classForPortCoder			{ return [NSData class]; }

- (const void *) bytes				{ return bytes; }
- (NSUInteger) length					{ return length; }

- (void) getBytes:(void*)buffer range:(NSRange)aRange
{
	if (aRange.location > length || NSMaxRange(aRange) > length)
		[NSException raise: NSRangeException
					format: @"-[NSData getBytes:range:] Range: (%u, %u) Size: %d",
		 aRange.location, aRange.length, length];
	memcpy(buffer, ((char *) bytes) + aRange.location, aRange.length);
}

static inline void
getBytes(void* dst, void* src, NSUInteger len, NSUInteger limit, NSUInteger *pos)
{
	if (*pos > limit || len > limit || len+*pos > limit)
		[NSException raise: NSRangeException
					format: @"getbytes() Range: (%u, %u) Size: %d", *pos, len, limit];

	memcpy(dst, ((char *) src) + *pos, len);
	*pos += len;
}

- (void) deserializeDataAt:(void*)data
				ofObjCType:(const char*)type
				  atCursor:(NSUInteger *)cursor
				   context:(id <NSObjCTypeSerializationCallBack>)callback
{
	if (data == 0 || type == 0)
		{
		if (data == 0)
			NSLog(@"attempt to deserialize to a nul pointer");
		if (type == 0)
			NSLog(@"attempt to deserialize with a nul type encoding");

		return;
		}

	switch (*type)
	{
		case _C_ID:
		{
		[callback deserializeObjectAt: data
						   ofObjCType: type
							 fromData: self
							 atCursor: cursor];
		return;
		}
		case _C_CHARPTR:
		{
		int len = [self deserializeIntAtCursor: cursor];

		if (len == -1)
			{
			*(const char**)data = NULL;
			return;
			}
		else
			*(char**)data = (char*)objc_malloc(len+1);

		getBytes(*(void**)data, bytes, len, length, cursor);
		(*(char**)data)[len] = '\0';

		return;
		}
		case _C_ARY_B:
		{
		unsigned offset = 0;
		unsigned size;
		unsigned count = atoi(++type);
		unsigned i;

		while (isdigit(*type))
			type++;

		size = objc_sizeof_type(type);

		for (i = 0; i < count; i++)
			{
			[self deserializeDataAt: (char*)data + offset
					  ofObjCType: type
						   atCursor: cursor
					  context: callback];
			offset += size;
			}
		return;
		}
		case _C_STRUCT_B:
		{
		int offset = 0;

		while (*type != _C_STRUCT_E && *type++ != '=')
			; // skip "<name>="
		for (;;)
			{
			[self deserializeDataAt: ((char*)data) + offset
						 ofObjCType: type
						   atCursor: cursor
							context: callback];
			offset += objc_sizeof_type(type);
			type = objc_skip_typespec(type);
			if (*type != _C_STRUCT_E)
				{
				int	align = objc_alignof_type(type);
				int	rem = offset % align;

				if (rem != 0)
					offset += align - rem;
				}
			else
				break;
			}
		return;
		}
		case _C_PTR:
		{
		unsigned len = objc_sizeof_type(++type);

		*(char**)data = (char*)objc_malloc(len);
		[[[dataMalloc alloc] initWithBytesNoCopy: *(void**)data
										  length: len ] autorelease];
		[self deserializeDataAt: *(char**)data
					 ofObjCType: type
					   atCursor: cursor
						context: callback];
		return;
		}
		case _C_CHR:
		case _C_UCHR:
		getBytes(data, bytes, sizeof(unsigned char), length, cursor);
		return;

		case _C_SHT:
		case _C_USHT:
		{
		unsigned short ns;

		getBytes((void*)&ns, bytes, sizeof(ns), length, cursor);
		*(unsigned short*)data = NSSwapBigShortToHost(ns);
		return;
		}
		case _C_INT:
		case _C_UINT:
		{
		unsigned ni;

		getBytes((void*)&ni, bytes, sizeof(ni), length, cursor);
		*(unsigned*)data = NSSwapBigIntToHost(ni);
		return;
		}
		case _C_LNG:
		case _C_ULNG:
		{
		unsigned long nl;

		getBytes((void*)&nl, bytes, sizeof(nl), length, cursor);
		*(unsigned long*)data = NSSwapBigLongToHost(nl);
		return;
		}
#ifdef	_C_LNG_LNG
		case _C_LNG_LNG:
		case _C_ULNG_LNG:
		{
		unsigned long long nl;

		getBytes((void*)&nl, bytes, sizeof(nl), length, cursor);
		*(unsigned long long*)data = NSSwapBigLongLongToHost(nl);
		return;
		}
#endif
		case _C_FLT:
		{
		NSSwappedFloat nf;

		getBytes((void*)&nf, bytes, sizeof(nf), length, cursor);
		*(float*)data = NSSwapBigFloatToHost(nf);
		return;
		}
		case _C_DBL:
		{
		NSSwappedDouble nd;

		getBytes((void*)&nd, bytes, sizeof(nd), length, cursor);
		*(double*)data = NSSwapBigDoubleToHost(nd);
		return;
		}
		case _C_CLASS:
		{
		unsigned ni;

		getBytes((void*)&ni, bytes, sizeof(ni), length, cursor);
		ni = NSSwapBigIntToHost(ni);
		if (ni == 0) {
			*(Class*)data = 0;
		}
		else {
			char	name[ni+1];
			Class	c;

			getBytes((void*)name, bytes, ni, length, cursor);
			name[ni] = '\0';
			c = objc_getClass(name);
			if (c == 0) {
				[NSException raise: NSInternalInconsistencyException
							format: @"can't find class - %s", name];
			}
			*(Class*)data = c;
		}
		return;
		}
		case _C_SEL:
		{
		unsigned ln;
		unsigned lt;

		getBytes((void*)&ln, bytes, sizeof(ln), length, cursor);
		ln = NSSwapBigIntToHost(ln);
		getBytes((void*)&lt, bytes, sizeof(lt), length, cursor);
		lt = NSSwapBigIntToHost(lt);
		if (ln == 0)
			*(SEL*)data = 0;
		else
			{
			char name[ln+1];
			char types[lt+1];
			SEL	sel;

			getBytes((void*)name, bytes, ln, length, cursor);
			name[ln] = '\0';
			getBytes((void*)types, bytes, lt, length, cursor);
			types[lt] = '\0';

			if (lt)
				sel = sel_getTypedSelector(name);
			else
				sel = sel_registerName(name);
			if (sel == 0)
				[NSException raise: NSInternalInconsistencyException
							format: @"can't find sel with name '%s' "
				 @"and types '%s'", name, types];
			*(SEL*)data = sel;
			}
		return;
		}
		default:
		[NSException raise: NSGenericException
					format: @"Unknown type to deserialize - '%s'", type];
	}
}

@end

@implementation	NSDataMalloc

#if 0
+ (id) alloc
{
	id r=[super alloc];
	extern BOOL __doingNSLog;
	if(!__doingNSLog)
		fprintf(stderr, "alloc NSDataMalloc: %p\n", r);
	return r;
}
#endif

- (id) copyWithZone:(NSZone *) zone							{ return [self retain]; }

- (void) dealloc
{
#if 0
	extern BOOL __doingNSLog;
	if(!__doingNSLog)
		fprintf(stderr, "dealloc NSDataMalloc: %p %p %u\n", self, bytes, length);
	if(!bytes && length > 0)
		abort();	// should not happen
#if defined(__mySTEP__)
	free(malloc(8192));	// segfaults???
#endif
#endif
	if(bytes)
		objc_free(bytes);
	[super dealloc];
}

- (id) initWithBytes:(const void*)aBuffer length:(NSUInteger)bufferSize
{
	void *tmp = NULL;

	if(aBuffer != NULL && bufferSize > 0)
		{
		if((tmp = objc_malloc(bufferSize)) == NULL)
			return GSError(self, @"NSDataMalloc -initWithBytes:length: unable to allocate %lu bytes", bufferSize);
		memcpy(tmp, aBuffer, bufferSize);
		}
	bytes = tmp;
	length = bufferSize;
	return self;
}

- (id) initWithBytesNoCopy:(void*)aBuffer length:(NSUInteger)bufferSize
{
	bytes = aBuffer;
	length = bufferSize;
#if 0 && defined(__mySTEP__)
	free(malloc(8192));
#endif
	return self;
}

#if CODER_RESPONSIBILITY
- (id) initWithCoder:(NSCoder*)aCoder
{
	unsigned l;
	void* b;

	[aCoder decodeValueOfObjCType: @encode(unsigned long) at: &l];
	if (l)
		{
		if ((b = objc_malloc(l)) == NULL)
			[NSException raise:NSMallocException format:@"malloc failed"];

		[aCoder decodeArrayOfObjCType: @encode(unsigned char) count: l at: b];
		}
	else
		b = 0;

	return [self initWithBytesNoCopy: b length: l];
}
#endif

- (id) initWithContentsOfFile:(NSString *)path
{
	const char *p;
	FILE *f;
	if(!path)
		{ [self release]; return nil; }
	p=[[NSFileManager defaultManager] fileSystemRepresentationWithPath:path];
#if 0
	NSLog(@"initWithContentsOfFile: %@ -> %s", path, p);
#endif

	if ((f = fopen(p, "r")) == NULL)
		{
		[self release];
		return nil; // does not exist or can't read
		}

	if ((fseek(f, 0L, SEEK_END)) != 0)			// Seek to end of the file
		{
		fclose(f);
		[self release];
		return GSError(self,@"Seek end of file failed - %s",strerror(errno));
		}

	if ((length = ftell(f)) == -1)					// Determine length of file
		{
		fclose(f);
		[self release];
		return GSError(self, @"Ftell failed - %s", strerror(errno));
		}

	if ((bytes = objc_malloc(length)) == NULL)
		[NSException raise:NSMallocException format:@"malloc failed in NSData -initWithContentsOfFile:"];

	if ((fseek(f, 0L, SEEK_SET)) != 0)
		{
		fclose(f);
		[self release];
		return GSError(self, @"fseek SEEK_SET failed - %s", strerror(errno));	// does a [self release] which does objc_free(bytes)
		}
#if 0
	NSLog(@"length=%d", length);
#endif
	if(length == 0 || length == 4096)
		{
		/*
		 * Special case ... a file of length zero may be a named pipe or some
		 * file in the /proc filesystem, which will return us data if we read
		 * from it ... so we try reading as much as we can.
		 * More special case: a file in /sys reports 4096 (always???) length
		 */
		unsigned char buf[BUFSIZ];	// temporary buffer
		int l;
		length=0;
		while((l = fread(buf, 1, BUFSIZ, f)) != 0)
			{
			unsigned char *newBytes=objc_realloc(bytes, length+l);	// increase buffer size
			if (newBytes == NULL)
				{
				fclose(f);
				[self release];
				return GSError(self, @"realloc failed for %s - %s", p, strerror(errno));
				}
			bytes=newBytes;
			memcpy(((char *) bytes) + length, buf, l);	// append new block
			length += l;	// advance append pointer
			}
#if 0
		NSLog(@"data from /proc or /sys %@", self);
#endif
		}
	else if ((fread(bytes, 1, length, f)) != length)  // we know the length; read in one full chunk
		{ // did not read the full file
			int err=errno;
			fclose(f);
			[self release];
			return GSError(self, @"Fread of file %@ failed - %s", path, strerror(err));
		}
	fclose(f);
#if 0
	NSLog(@"initWithContentsOfFile done (%d): %@", length, path);
#endif
	return self;
}

- (id) initWithContentsOfMappedFile:(NSString *)path
{
#if 0
	NSLog(@"%@ initWithContentsOfMappedFile:%@", NSStringFromClass([self class]), path);
#endif
#if	HAVE_MMAP
#if 0
	NSLog(@"HAVE_MMAP");
#endif
	[self release];
	return [[NSDataMappedFile alloc] initWithContentsOfMappedFile: path];
#else
	return [self initWithContentsOfFile: path];
#endif
}

- (id) initWithData:(NSData *)anObject
{
	if(anObject == nil)
		return [self initWithBytesNoCopy:NULL length: 0];	// better raise exception?
	if([anObject isKindOfClass: [NSData class]] == NO)
		return GSError(self, @"-initWithData: passed a non-data object");
	return [self initWithBytes: [anObject bytes] length: [anObject length]];
}

@end

#if	HAVE_MMAP
@implementation	NSDataMappedFile

+ (id) allocWithZone:(NSZone *) z
{
	return (NSDataMappedFile *) NSAllocateObject([NSDataMappedFile class], 0, z);
}

- (void) dealloc
{
	if(bytes)
		{
		munmap(bytes, length);
		bytes=NULL;	// don't try to objc_free()
		length=0;
		}
	[super dealloc];
}

- (id) initWithContentsOfMappedFile:(NSString*)path
{
	int fd;
	const char *p;
	NSInteger l;
	if(!path)
		{ [self release]; return nil; }
	p=[path fileSystemRepresentation];
	if((fd = open(p, O_RDONLY)) < 0)
		return GSError(self, @"NSDataMappedFile -initWithContentsOfMappedFile: unable to open %s - %s", p, strerror(errno));
	// Find size of file to be mapped.
	if((l = lseek(fd, 0, SEEK_END)) < 0)
		{
		close(fd);
		return GSError(self, @"NSDataMappedFile -initWithContentsOfMappedFile:\
					   unable to seek to sof %s - %s", p, strerror(errno));
		}
	length = l;
	if(lseek(fd, 0, SEEK_SET) != 0)		// Position at start of file.
		{
		close(fd);
		return GSError(self, @"NSDataMappedFile -initWithContentsOfMappedFile:\
					   unable to seek to eof %s - %s", p, strerror(errno));
		}
#if 0
	NSLog(@"mmap");
#endif
	if ((bytes = mmap(0, length, PROT_READ, MAP_SHARED, fd, 0)) == MAP_FAILED)
		{
		NSLog(@"[NSDataMappedFile -initWithContentsOfMappedFile:] mapping \
			  failed for %s - %s", p, strerror(errno));
		[self release];
		self = [[dataMalloc alloc] initWithContentsOfFile: path];	// replace by non-mapped file
		}
	close(fd);
	return self;
}

@end
#endif	/* HAVE_MMAP */

#if	HAVE_SHMCTL
@implementation	NSDataShared

+ (id) allocWithZone:(NSZone *) z
{
	return NSAllocateObject([NSDataShared class], 0, z);
}

- (void) dealloc
{
	if (bytes)
		{
		struct shmid_ds	buf;
		if (shmctl(shmid, IPC_STAT, &buf) < 0)
			NSLog(@"[NSDataShared -dealloc] shared memory control failed - %s",
				  strerror(errno));
		else
			if (buf.shm_nattch == 1)
				if (shmctl(shmid, IPC_RMID, &buf) < 0)	  // Mark for deletion.
					NSLog(@"[NSDataShared -dealloc] shared memory delete failed - %s", strerror(errno));
		if (shmdt(bytes) < 0)
			NSLog(@"[NSDataShared -dealloc] shared memory detach failed - %s",
				  strerror(errno));
		bytes = NULL;	// don't try to obj_free()...
		length = 0;
		shmid = -1;
		}
	[super dealloc];
}

- (id) initWithBytes:(const void*)aBuffer length:(unsigned)bufferSize
{
	struct shmid_ds	buf;
	if(!aBuffer)
		{ [self release]; return nil; }

	shmid = -1;
	if (aBuffer && bufferSize)
		{
		shmid = shmget(IPC_PRIVATE, bufferSize, IPC_CREAT|VM_RDONLY);
		if (shmid == -1)									// Created memory?
			{
			NSLog(@"[-initWithBytes:length:] shared mem get failed for %u -%s",
				  bufferSize, strerror(errno));
			[self release];
			self = [dataMalloc alloc];

			return [self initWithBytes: aBuffer length: bufferSize];
			}

		bytes = shmat(shmid, 0, 0);
		if (bytes == (void*)-1)
			{
			NSLog(@"-initWithBytes:length: shared mem attach failed for %u-%s",
				  bufferSize, strerror(errno));
			bytes = 0;
			[self release];
			self = [dataMalloc alloc];

			return [self initWithBytes: aBuffer length: bufferSize];
			}
		length = bufferSize;
		}

	return self;
}

- (id) initWithShmID:(int)anId length:(unsigned)bufferSize
{
	struct shmid_ds	buf;

	shmid = anId;
	if (shmctl(shmid, IPC_STAT, &buf) < 0)
		return GSError(self, @"NSDataShared -initWithShmID:length: shared \
					   memory control failed - %s", strerror(errno));

	if (buf.shm_segsz < bufferSize)
		return GSError(self, @"NSDataShared -initWithShmID:length: shared \
					   memory segment too small");

	bytes = shmat(shmid, 0, 0);
	if (bytes == (void*)-1)
		{
		bytes = 0;								// Unable to attach to memory

		return GSError(self, @"NSDataShared initWithShmID:length: shared mem \
					   attach failed - %s", strerror(errno));
		}
	length = bufferSize;

	return self;
}

- (int) shmID							{ return shmid; }

@end
#endif	/* HAVE_SHMCTL	*/

//*****************************************************************************
//
// 		NSMutableData
//
//*****************************************************************************

@implementation NSMutableData

+ (id) allocWithZone:(NSZone *) z
{
	return (id) NSAllocateObject(mutableDataMalloc, 0, z);
}

+ (id) data
{
	return [[[mutableDataMalloc alloc] initWithCapacity: 0] autorelease];
}

+ (id) dataWithBytes:(const void*)bytes length:(NSUInteger)length
{
	return [[[mutableDataMalloc alloc] initWithBytes: bytes
											  length: length] autorelease];
}

+ (id) dataWithBytesNoCopy:(void*)bytes length:(NSUInteger)length
{
	return [[[mutableDataMalloc alloc] initWithBytesNoCopy: bytes
													length: length] autorelease];
}

+ (id) dataWithCapacity:(NSUInteger)numBytes
{
	return [[[mutableDataMalloc alloc] initWithCapacity:numBytes] autorelease];
}

+ (id) dataWithContentsOfFile:(NSString*)path
{
	return [[[mutableDataMalloc alloc] initWithContentsOfFile:path]autorelease];
}

+ (id) dataWithContentsOfMappedFile:(NSString*)path
{
	return [[[mutableDataMalloc alloc] initWithContentsOfFile:path]autorelease];
}

+ (id) dataWithData:(NSData*)data
{
	return [[[mutableDataMalloc alloc] initWithBytes: [data bytes]
											  length: [data length]] autorelease];
}

+ (id) dataWithLength:(NSUInteger)length
{
	return [[[mutableDataMalloc alloc] initWithLength: length] autorelease];
}

- (const void *) bytes						 { return [self mutableBytes]; }
- (id) initWithCapacity:(NSUInteger)capacity			{ SUBCLASS return nil; }
- (id) initWithLength:(NSUInteger)length				{ SUBCLASS return nil; }

- (id) initWithCoder:(NSCoder*)coder
{
	if([coder allowsKeyedCoding])
		{
		[self release];
		return [[coder decodeObjectForKey:@"NS.data"] mutableCopy];
		}
	return NIMP;
}

- (void) increaseLengthBy:(NSUInteger)extraLength		// Adjusting Capacity
{
	[self setLength: [self length] + extraLength];
}

- (void) setLength:(NSUInteger)size								{ SUBCLASS }
- (void*) mutableBytes								{ SUBCLASS return NULL; }
- (void) serializeInt:(int)value								{ SUBCLASS }
- (void) serializeInt:(int)value atIndex:(NSUInteger)index		{ SUBCLASS }
- (void) serializeInts:(int*)intBuffer count:(NSUInteger)numInts	{ SUBCLASS }
- (void) serializeInts:(int*)intBuffer
				 count:(NSUInteger)numInts
			   atIndex:(NSUInteger)index 						{ SUBCLASS }
- (void) serializeDataAt:(const void*)data
			  ofObjCType:(const char*)type
				 context:(id <NSObjCTypeSerializationCallBack>)callback	{ SUBCLASS }
- (void) appendData:(NSData*)other								{ SUBCLASS }
- (void) resetBytesInRange:(NSRange)aRange						{ SUBCLASS }
- (void) setData:(NSData*)data									{ SUBCLASS }
- (void) serializeAlignedBytesLength:(NSUInteger)length			{ SUBCLASS }
- (void) replaceBytesInRange:(NSRange)aRange
				   withBytes:(const void*)moreBytes				{ SUBCLASS }
- (void) replaceBytesInRange:(NSRange)aRange
				   withBytes:(const void*)moreBytes
					  length:(NSUInteger)length					{ SUBCLASS }
- (void) appendBytes:(const void*)aBuffer
			  length:(NSUInteger)bufferSize						{ SUBCLASS }

//*****************************************************************************
//
// 		NSMutableDataMalloc (mySTEPExtensions)
//
//*****************************************************************************

+ (id) dataWithShmID:(int)anID length:(NSUInteger)length
{
#if	HAVE_SHMCTL
	return [[[NSMutableDataShared alloc] initWithShmID: anID length: length]
	  autorelease];
#else
	NSLog(@"[NSMutableData -dataWithSmdID:length:] no shared memory support");
	return nil;
#endif
}

+ (id) dataWithSharedBytes:(const void*)sbytes length:(NSUInteger)length
{
#if	HAVE_SHMCTL
	return [[[NSMutableDataShared alloc] initWithBytes: sbytes length: length]
	  autorelease];
#else
	return [[[mutableDataMalloc alloc] initWithBytes: sbytes length: length]
	  autorelease];
#endif
}

@end

//*****************************************************************************
//
// 		NSMutableDataMalloc
//
//*****************************************************************************

@implementation	NSMutableDataMalloc

+ (id) allocWithZone:(NSZone *) z
{
	return (id) NSAllocateObject(mutableDataMalloc, 0, z);
}

#if 0
- (void) dealloc
{
	extern BOOL __doingNSLog;
	if(!__doingNSLog)
		fprintf(stderr, "dealloc NSMutableData: %p %p %u %u %u\n", self, bytes, length, capacity, growth);
	[super dealloc];
}
#endif

- (Class) classForArchiver			{ return mutableDataMalloc; }
- (Class) classForCoder				{ return mutableDataMalloc; }
- (Class) classForPortCoder			{ return mutableDataMalloc; }

- (id) copyWithZone:(NSZone *) zone
{
	return [[mutableDataMalloc alloc] initWithBytes: bytes length: length];
}

- (id) initWithCapacity:(NSUInteger)size
{													// designated initializer
	if (size && ((bytes = objc_malloc(size)) == 0))
		[NSException raise:NSMallocException format:@"malloc failed in NSMutableData -initWithCapacity:"];

	capacity = size;
	if ((growth = (capacity/2)) == 0)
		growth = 1;
	length = 0;

	return self;
}

- (id) initWithBytes:(const void*)aBuffer length:(NSUInteger)bufferSize
{
	if(!aBuffer)
		{ [self release]; return nil; }
	if ((self = [self initWithCapacity: bufferSize]))
		if (aBuffer && bufferSize > 0)
			{
			memcpy(bytes, aBuffer, bufferSize);
			length = bufferSize;
			}

	return self;
}

- (id) _setCapacity:(NSUInteger)size
{
#if 0
	NSLog(@"_setCapacity:%u for %@", size, self);
#endif
	if (size != capacity)
		{
		void *tmp;

		if (bytes)
			tmp = objc_realloc(bytes, size);
		else
			tmp = objc_malloc(size);

		if (tmp == 0)
			[NSException raise: NSMallocException
						format: @"Unable to set data capacity to '%u'", size];
		bytes = tmp;
		capacity = size;
		if ((growth = (capacity/2)) == 0)
			growth = 1;
		}
	if (size < length)
		length = size;

	return self;
}

- (void) setLength:(unsigned)size
{
	if (size > capacity)
		[self _setCapacity: size];
	if (size > length)
		memset(((char *) bytes) + length, '\0', size - length);
	length = size;
}

- (id) initWithBytesNoCopy:(void*)aBuffer length:(NSUInteger)bufferSize
{
	if (!aBuffer)
		{
		if ((self = [self initWithCapacity: bufferSize]))
			[self setLength: bufferSize];
		}
	else
		if ((self = [self initWithCapacity: 0]))
			{
			bytes = aBuffer;
			length = bufferSize;
			capacity = bufferSize;
			if ((growth = (capacity/2)) == 0)
				growth = 1;
			}

	return self;
}

#if CODER_RESPONSIBILITY

- (id) initWithCoder:(NSCoder*)aCoder
{
	NSUInteger l;

	[aCoder decodeValueOfObjCType: @encode(unsigned long) at: &l];
	if (l)
		{
		[self initWithCapacity: l];
		if (bytes == 0)
			return GSError(self, @"NSMutableDataMalloc -initWithCoder: unable \
						   to alloc %lu bytes",l);

		[aCoder decodeArrayOfObjCType:@encode(unsigned char) count:l at:bytes];
		length = l;
		}

	return self;
}

#endif

- (id) initWithLength:(unsigned)size
{
	if ((self = [self initWithCapacity: size]))
		{
		memset(bytes, '\0', size);
		length = size;
		}
	return self;
}

- (id) initWithContentsOfFile:(NSString *)path
{
	if ((self = [super initWithContentsOfFile:path]) != nil)
		{
		capacity = length;
		growth = capacity / 2+1;
		}
	return self;
}

- (id) initWithContentsOfMappedFile:(NSString *)path
{
	return [self initWithContentsOfFile: path];
}

- (id) initWithData:(NSData*)anObject
{
	if (anObject == nil)
		return [self initWithCapacity: 0];

	if ([anObject isKindOfClass: [NSData class]] == NO)
		return GSError(self, @"-initWithData: passed a non-data object");

	return [self initWithBytes: [anObject bytes] length: [anObject length]];
}

- (void) appendBytes:(const void*)aBuffer length:(unsigned)bufferSize
{
	// FIXME: what happens if length+bufferSize overflows? We will not grow but overwrite most memory...
	unsigned oldLength = length;
	unsigned minimum = length + bufferSize;

	NSAssert(minimum >= length && minimum >= bufferSize, @"too many bytes to append");

	if (minimum > capacity)
		[self _grow: minimum];

	memcpy(((char *) bytes) + oldLength, aBuffer, bufferSize);
	length = minimum;
}

- (unsigned) capacity						{ return capacity; }
- (void*) mutableBytes						{ return bytes; }

- (void) _grow:(unsigned)minimum
{ // recalculate the grow factor
	if (minimum > capacity)
		{
		unsigned nextCapacity = capacity + growth;
		unsigned nextGrowth = capacity ? capacity : 1;

		while (nextCapacity < minimum)
			{
			unsigned tmp = nextCapacity + nextGrowth;

			nextGrowth = nextCapacity;
			nextCapacity = tmp;
			}
		[self _setCapacity: nextCapacity];
		growth = nextGrowth;
		}
}

- (void) replaceBytesInRange:(NSRange)aRange
				   withBytes:(const void*)moreBytes
{
	if (aRange.location > length || NSMaxRange(aRange) > length)
		[NSException raise: NSRangeException
					format: @"replaceBytesInRange Range: (%u, %u) Size: %u", aRange.location, aRange.length, length];

	memcpy(((char *) bytes) + aRange.location, moreBytes, aRange.length);
}

- (void) replaceBytesInRange:(NSRange)aRange
				   withBytes:(const void*)moreBytes
					  length:(unsigned)len
{
	if (aRange.location > length || NSMaxRange(aRange) > length)
		[NSException raise: NSRangeException
					format: @"replaceBytesInRange Range: (%u, %u) Length: %u Size: %u", aRange.location, aRange.length, len, length];
	if(len > aRange.length)
		{ // must grow
			NSAssert((length+len)-aRange.length > length, @"too many bytes to replace");	// protect against integer overflow
			[self _grow:(length+len)-aRange.length];
		}
	memmove(((char *) bytes) + aRange.location + len, ((char *) bytes) + NSMaxRange(aRange), length-NSMaxRange(aRange));
	memcpy(((char *) bytes) + aRange.location, moreBytes, len);
}

- (void) serializeInt:(int)value
{
	unsigned ni = NSSwapHostIntToBig(value);
	[self appendBytes: &ni length: sizeof(unsigned)];
}

- (void) serializeDataAt:(const void*)data
			  ofObjCType:(const char*)type
			  context:(id <NSObjCTypeSerializationCallBack>)callback
{
	if (data == NULL)
		{
		NSLog(@"attempt to serialize from a nul pointer");
		return;
		}
	if (type == NULL)
		{
		NSLog(@"attempt to serialize with a nul type encoding");
		return;
		}

	switch (*type)
	{
		case _C_ID:
		[callback serializeObjectAt:(id*)data
					  ofObjCType:type
						   intoData: (NSMutableData*)self];
		return;

		case _C_CHARPTR:
		{
		unsigned len;
		unsigned ni;
		unsigned minimum;

		if (!*(void**)data) {
			[self serializeInt: -1];
			return;
		}
		len = strlen(*(void**)data);
		ni = NSSwapHostIntToBig(len);
		minimum = length + len + sizeof(unsigned);
		if (minimum > capacity) {
			[self _grow: minimum];
		}
		memcpy(((char *) bytes)+length, &ni, sizeof(unsigned));
		length += sizeof(unsigned);
		if (len) {
			memcpy(((char *) bytes)+length, *(void**)data, len);
			length += len;
		}
		return;
		}
		case _C_ARY_B: {
			unsigned	offset = 0;
			unsigned	size;
			unsigned	count = atoi(++type);
			unsigned	i;
			unsigned	minimum;

			while (isdigit(*type)) {
				type++;
			}
			size = objc_sizeof_type(type);

			/*
			 *	Serialized objects are going to take up at least as much
			 *	space as the originals, so we can calculate a minimum space
			 *	we are going to need and make sure our buffer is big enough.
			 */
			minimum = length + size*count;
			if (minimum > capacity) {
				[self _grow: minimum];
			}

			for (i = 0; i < count; i++) {
				[self serializeDataAt: (char*)data + offset
						   ofObjCType: type
							  context: callback];
				offset += size;
			}
			return;
		}
		case _C_STRUCT_B:
		{
		int offset = 0;

		while (*type != _C_STRUCT_E && *type++ != '='); // skip "<name>="
		for (;;) {
			[self serializeDataAt: ((char*)data) + offset
					   ofObjCType: type
						  context: callback];
			offset += objc_sizeof_type(type);
			type = objc_skip_typespec(type);
			if (*type != _C_STRUCT_E) {
				unsigned	align = objc_alignof_type(type);
				unsigned	rem = offset % align;

				if (rem != 0) {
					offset += align - rem;
				}
			}
			else break;
		}
		return;
		}
		case _C_PTR:
		[self serializeDataAt: *(char**)data
				   ofObjCType: ++type
					  context: callback];
		return;
		case _C_CHR:
		case _C_UCHR:
		(*appendImp)(self, appendSel, data, sizeof(unsigned char));
		return;
		case _C_SHT:
		case _C_USHT: {
			unsigned short ns = NSSwapHostShortToBig(*(unsigned short*)data);
			(*appendImp)(self, appendSel, &ns, sizeof(unsigned short));
			return;
		}
		case _C_INT:
		case _C_UINT: {
			unsigned ni = NSSwapHostIntToBig(*(unsigned int*)data);
			(*appendImp)(self, appendSel, &ni, sizeof(unsigned));
			return;
		}
		case _C_LNG:
		case _C_ULNG: {
			unsigned long nl = NSSwapHostLongToBig(*(unsigned long*)data);
			(*appendImp)(self, appendSel, &nl, sizeof(unsigned long));
			return;
		}
#ifdef	_C_LNG_LNG
		case _C_LNG_LNG:
		case _C_ULNG_LNG: {
			unsigned long long nl;

			nl = NSSwapHostLongLongToBig(*(unsigned long long*)data);
			(*appendImp)(self, appendSel, &nl, sizeof(unsigned long long));
			return;
		}
#endif
		case _C_FLT: {
			NSSwappedFloat nf = NSSwapHostFloatToBig(*(float*)data);
			(*appendImp)(self, appendSel, &nf, sizeof(NSSwappedFloat));
			return;
		}
		case _C_DBL: {
			NSSwappedDouble nd = NSSwapHostDoubleToBig(*(double*)data);
			(*appendImp)(self, appendSel, &nd, sizeof(NSSwappedDouble));
			return;
		}
		case _C_CLASS:
		{
		const char *name = *(Class*)data ? class_getName(*(Class*)data) : "";
		unsigned ln = strlen(name);
		unsigned minimum = length + ln + sizeof(unsigned);
		unsigned ni;

		if (minimum > capacity)
			[self _grow: minimum];

		ni = NSSwapHostIntToBig(ln);
		memcpy(((char *) bytes)+length, &ni, sizeof(unsigned));
		length += sizeof(unsigned);
		if (ln)
			{
			memcpy(((char *) bytes)+length, name, ln);
			length += ln;
			}
		return;
		}
		case _C_SEL:
		{
		const char *name = *(SEL*)data ? sel_getName(*(SEL*)data) : "";
		unsigned ln = strlen(name);
		const char *types = *(SEL*)data ?
		// FIXME:
		(const char*) sel_getTypeEncoding(*(SEL*)data) : "";
		unsigned lt = strlen(types);
		unsigned minimum = length + ln + lt + 2*sizeof(unsigned);
		unsigned ni;

		if (minimum > capacity) {
			[self _grow: minimum];
		}
		ni = NSSwapHostIntToBig(ln);
		memcpy(((char *) bytes)+length, &ni, sizeof(unsigned));
		length += sizeof(unsigned);
		ni = NSSwapHostIntToBig(lt);
		memcpy(((char *) bytes)+length, &ni, sizeof(unsigned));
		length += sizeof(unsigned);
		if (ln) {
			memcpy(((char *) bytes)+length, name, ln);
			length += ln;
		}
		if (lt) {
			memcpy(((char *) bytes)+length, types, lt);
			length += lt;
		}
		return;
		}
		default:
		[NSException raise: NSGenericException
					format: @"Unknown type to serialize - '%s'", type];
	}
}

- (void) serializeTypeTag:(unsigned char)tag
{
	if (length == capacity)
		[self _grow: length + 1];
	((unsigned char*)bytes)[length++] = tag;
}

- (void) serializeCrossRef:(unsigned)xref
{
	if (length + sizeof(unsigned) >= capacity)
		[self _grow: length + sizeof(unsigned)];
	xref = NSSwapHostIntToBig(xref);
	memcpy(((char *) bytes)+length, &xref, sizeof(unsigned));
	length += sizeof(unsigned);
}

- (void) appendData:(NSData*)other							// Appending Data
{
	[self appendBytes:[other bytes] length:[other length]];
}

// Modifying Data

- (void) resetBytesInRange:(NSRange)aRange
{
	int	size = [self length];
	// Check for 'out of range' errors.
	if(aRange.location >size || aRange.length >size || NSMaxRange(aRange)>size)
		[NSException raise: NSRangeException
					format: @"resetBytesInRange Range: (%u, %u) Size: %d", aRange.location,
		 aRange.length, size];

	memset((char*)[self bytes] + aRange.location, 0, aRange.length);
}

- (void) setData:(NSData*)data
{
	NSRange	r = NSMakeRange(0, [data length]);
	[self _setCapacity:r.length];
	[self replaceBytesInRange:r withBytes:[data bytes]];
}

- (void)serializeAlignedBytesLength:(unsigned)aLength		// Serializing Data
{
	[self serializeInt: aLength];
}

- (void)serializeInt:(int)value atIndex:(unsigned)index
{
	unsigned ni = NSSwapHostIntToBig(value);
	NSRange range = { index, sizeof(int) };

	[self replaceBytesInRange: range withBytes: &ni];
}

- (void) serializeInts:(int*)intBuffer count:(unsigned)numInts
{
	unsigned i;
	SEL sel = @selector(serializeInt:);
	IMP imp = [self methodForSelector: sel];

	for (i = 0; i < numInts; i++)
		(*imp)(self, sel, intBuffer[i]);
}

- (void) serializeInts:(int*)intBuffer
				 count:(unsigned)numInts
			   atIndex:(unsigned)index
{
	unsigned i;
	SEL sel = @selector(serializeInt:atIndex:);
	IMP imp = [self methodForSelector: sel];

	for (i = 0; i < numInts; i++)
		(*imp)(self, sel, intBuffer[i], index++);
}
//*****************************************************************************
//
// 		NSMutableDataMalloc (mySTEPExtensions)
//
//*****************************************************************************

- (int) shmID						{ return -1; }

@end

//*****************************************************************************
//
// 		NSMutableDataShared
//
//*****************************************************************************

#if	HAVE_SHMCTL
@implementation	NSMutableDataShared

+ (id) allocWithZone:(NSZone *) z
{
	return NSAllocateObject([NSMutableDataShared class], 0, z);
}

- (void) dealloc
{
	if (bytes)
		{
		struct shmid_ds	buf;
		if (shmctl(shmid, IPC_STAT, &buf) < 0)
			NSLog(@"[NSMutableDataShared -dealloc] shared memory control failed - %s", strerror(errno));
		else if (buf.shm_nattch == 1)
			if (shmctl(shmid, IPC_RMID, &buf) < 0)	/* Mark for deletion. */
				NSLog(@"[NSMutableDataShared -dealloc] shared memory delete failed - %s", strerror(errno));
		if (shmdt(bytes) < 0)
			NSLog(@"[NSMutableDataShared -dealloc] shared memory detach failed - %s", strerror(errno));
		bytes = NULL;
		length = 0;
		capacity = 0;
		shmid = -1;
		}
	[super dealloc];
}

- (id) initWithBytes:(const void*)aBuffer length:(unsigned)bufferSize
{
	if(!aBuffer)
		{ [self release]; return nil; }
	if ((self = [self initWithCapacity: bufferSize]))
		{
		if (bufferSize && aBuffer)
			memcpy(bytes, aBuffer, bufferSize);
		length = bufferSize;
		}

	return self;
}

- (id) initWithCapacity:(unsigned)bufferSize
{
	struct shmid_ds buf;
	int e;

	shmid = shmget(IPC_PRIVATE, bufferSize, IPC_CREAT|VM_ACCESS);
	if (shmid == -1)			/* Created memory? */
		{
		NSLog(@"[NSMutableDataShared -initWithCapacity:] shared memory get failed for %u - %s", bufferSize, strerror(errno));
		[self release];
		self = [mutableDataMalloc alloc];

		return [self initWithCapacity: bufferSize];
		}

	bytes = shmat(shmid, 0, 0);
	e = errno;
	if (bytes == (void*)-1)
		{
		NSLog(@"[NSMutableDataShared -initWithCapacity:] shared memory attach \
			  failed for %u - %s", bufferSize, strerror(e));
		bytes = 0;
		[self release];
		self = [mutableDataMalloc alloc];

		return [self initWithCapacity: bufferSize];
		}
	length = 0;
	capacity = bufferSize;

	return self;
}

- (id) initWithShmID:(int)anId length:(unsigned)bufferSize
{
	struct shmid_ds	buf;

	shmid = anId;
	if (shmctl(shmid, IPC_STAT, &buf) < 0)
		return GSError(self, @"NSMutableDataShared -initWithShmID:length: \
					   shared memory control failed - %s", strerror(errno));

	if (buf.shm_segsz < bufferSize)
		return GSError(self, @"NSMutableDataShared -initWithShmID:length: \
					   shared memory segment too small");

	if ((bytes = shmat(shmid, 0, 0)) == (void*)-1)
		{
		bytes = 0;

		return GSError(self, @"NSMutableDataShared -initWithShmID:length: \
					   shared memory attach failed - %s", strerror(errno));
		}
	length = bufferSize;
	capacity = length;

	return self;
}

- (id) _setCapacity:(unsigned)size
{
	if (size != capacity)
		{
		void *tmp;
		struct shmid_ds	buf;
		int newid = shmget(IPC_PRIVATE, size, IPC_CREAT|VM_ACCESS);

		if (newid == -1)									// Created memory?
			[NSException raise: NSMallocException
						format: @"Unable to create shared memory segment - %s.",
			 strerror(errno)];
		tmp = shmat(newid, 0, 0);
		if ((int)tmp == -1)									// Attached memory?
			[NSException raise: NSMallocException
						format: @"Unable to attach to shared memory segment."];
		memcpy(tmp, bytes, length);
		if (bytes)
			{
			struct shmid_ds	buf;

			if (shmctl(shmid, IPC_STAT, &buf) < 0)
				NSLog(@"[NSMutableDataShared -setCapacity:] shared memory control failed - %s", strerror(errno));
			else if (buf.shm_nattch == 1)
				if (shmctl(shmid, IPC_RMID, &buf) < 0)	/* Mark for deletion. */
					NSLog(@"[NSMutableDataShared -setCapacity:] shared memory delete failed - %s", strerror(errno));
			if (shmdt(bytes) < 0)				// Detach memory.
				NSLog(@"[NSMutableDataShared -setCapacity:] shared memory detach failed - %s", strerror(errno));
			}
		bytes = tmp;
		shmid = newid;
		capacity = size;
		}
	if (size < length)
		length = size;

	return self;
}

- (int) shmID												{ return shmid; }

@end

#endif	/* HAVE_SHMCTL	*/

@implementation NSAutoreleasePool (NSPrivate)

+ (void *) _autoFree:(void *) pointer;
{ // wrap in autoreleased NSData object
	if(pointer)
		[[[NSData alloc] initWithBytesNoCopy:pointer length:0] autorelease];
	return pointer;
}

// FIXME: should sit close to objc_malloc
void *_autoFreedBufferWithLength(NSUInteger bytes)
{
	return [NSAutoreleasePool _autoFree:objc_malloc(bytes)];
}

@end
