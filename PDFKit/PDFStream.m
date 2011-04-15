//
//  PDFFilter.m
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

// #include <zlib.h>
#import "PDFKitPrivate.h"

@interface PDFASCIIHexStream : PDFStream
@end

@implementation PDFASCIIHexStream

- (NSData *) decode;
{
	NSLog(@"%@ data", NSStringFromClass([self class]));
	_source=[_previous data];
	NIMP;
	// decode
	// return decoded data
	return _source;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: %@", NSStringFromClass([self class]), _dict];
}

- (unsigned) decodedLength;	{ return (2*([_previous decodedLength]-1)); } // estimate

@end

@interface PDFASCII85Stream : PDFStream
@end

@implementation PDFASCII85Stream

- (NSData *) decode;
{
	NSLog(@"%@ data", NSStringFromClass([self class]));
	_source=[_previous data];
	NIMP;
	// decode
	// return decoded data
	return _source;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: %@", NSStringFromClass([self class]), _dict];
}

- (unsigned) decodedLength;	{ return (5*([_previous decodedLength]-2))/4; } // estimate

@end

@interface NSData (Zip)
- (NSData *) inflate;
@end

@interface PDFFlateStream : PDFStream
@end

@implementation PDFFlateStream

- (NSData *) decode;
{
	return [[_previous data] inflate];
#if OLD
	z_stream strm;
	int err;
	NSMutableData *result=[NSMutableData dataWithCapacity:[self length]];	// estimate required length
	unsigned char buf[512];
	_source=[_previous data];
#if 0
	NSLog(@"%@ raw=%@", NSStringFromClass([self class]), _source);
#endif
//	[_source writeToFile:@"stream.zip" atomically:NO];
	strm.zalloc=Z_NULL;	// use internal memory allocator
	strm.zfree=Z_NULL;
	strm.opaque=NULL;
	strm.next_in=(unsigned char *) [_source bytes];
	strm.avail_in=[_source length];
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
#endif
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: %@", NSStringFromClass([self class]), _dict];
}

- (unsigned) decodedLength;	{ return 2*[_previous decodedLength]; } // estimate

@end

@interface PDFDCTStream : PDFStream
@end

@implementation PDFDCTStream

- (NSData *) decode;
{
	return [_previous data];	// do not really decode - it should be a compressed JPEG image
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: %@", NSStringFromClass([self class]), _dict];
}

- (unsigned) decodedLength;	{ return [_previous decodedLength]; } // estimate

@end

@interface PDFFileStream : PDFStream
@end

@implementation PDFFileStream

- (NSData *) decode;
{
	NSLog(@"%@ data - file=%@", NSStringFromClass([self class]), [_dict objectForKey:@"F"]);
	// read file
	return nil;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: %@", NSStringFromClass([self class]), _dict];
}

- (unsigned) decodedLength;	{ return 0; } // could return file size

@end

@interface PDFEncryptedStream : PDFStream
@end

@implementation PDFEncryptedStream

- (id) initWithPrevious:(PDFStream *) prev dictionary:(NSDictionary *) dict parameters:(NSDictionary *) params;
{ // initialize as filter
	if((self=[super init]))
		{
		_previous=[prev retain];
		_len=[[[dict objectForKey:@"Length"] self] unsignedIntValue];
		_dict=[params retain];
		}
	return self;
}

- (NSData *) decode;
{
	NSLog(@"%@ data: %@", NSStringFromClass([self class]), _dict);
	// read and decrypt file
	return nil;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: %@", NSStringFromClass([self class]), _dict];
}

- (unsigned) decodedLength;	{ return [_previous decodedLength]; } // assume the same

@end

@implementation PDFStream

- (NSData *) _PDFDataRepresentation;
{
	// glue together
	return nil;
}

- (id) initWithPrevious:(PDFStream *) prev dictionary:(NSDictionary *) dict parameters:(NSDictionary *) params;
{ // initialize as filter
	if((self=[super init]))
		{
		_previous=[prev retain];
		_dict=[dict retain];
		_len=[[[dict objectForKey:@"Length"] self] unsignedIntValue];
		}
	return self;
}

- (id) initWithDoc:(PDFDocument *) doc raw:(NSData *) raw dictionary:(NSDictionary *) dict atPos:(unsigned) pos;
{ // initialize as unfiltered raw accessor
	if((self=[self initWithPrevious:nil dictionary:dict parameters:nil]))
		{
		NSArray *filter;
		NSArray *params;
		unsigned i;
		_doc=doc;
		_source=[raw retain];
		_start=pos;
		if([dict objectForKey:@"F"])
			{ // substitute with PDFFileStream
			[self autorelease];
			self=[[PDFFileStream alloc] initWithPrevious:nil dictionary:dict parameters:nil];
			filter=[dict objectForKey:@"FFilter"];
			params=[dict objectForKey:@"FDecodeParams"];
			}
		else
			{
			NSDictionary *enc;	// encryption dictionary
			filter=[dict objectForKey:@"Filter"];
			params=[dict objectForKey:@"DecodeParams"];
			if((enc=[[[doc _trailer] objectForKey:@"Encrypt"] self]))
				{ // start with decryption filter phase
				[self autorelease];
				self=[[PDFEncryptedStream alloc] initWithPrevious:self dictionary:dict parameters:enc];
#if 0
				NSLog(@"encrypted stream %@", self);
#endif
				}
			}
		if(filter && [filter isPDFAtom])
			filter=[NSArray arrayWithObject:filter];
		if(params && [params isPDFAtom])
			params=[NSArray arrayWithObject:params];	// may be missing if filter has no parameters
		for(i=0; self && i<[filter count]; i++)
			{ // build chain of filters
			PDFAtom *f=[filter objectAtIndex:i];
			NSDictionary *param;
			Class fc=nil;
			[self autorelease];
			if([f isEqualToString:@"ASCIIHexDecode"]) fc=[PDFASCIIHexStream class];
			else if([f isEqualToString:@"ASCII85Decode"]) fc=[PDFASCII85Stream class];
			// else if([f isEqualToString:@"LZWDecode"]) fc=[PDFLZWStream class];
			else if([f isEqualToString:@"FlateDecode"]) fc=[PDFFlateStream class];
			// else if([f isEqualToString:@"RunLengthDecode"]) fc=[PDFASCII85Stream class];
			// else if([f isEqualToString:@"CCITTFaxDecode"]) fc=[PDFASCII85Stream class];
			// else if([f isEqualToString:@"JBIG2Decode"]) fc=[PDFJBIG2Stream class];
			if([f isEqualToString:@"DCTDecode"]) fc=[PDFDCTStream class];
			// else if([f isEqualToString:@"JPXDecode"]) fc=[PDFJPXStream class];
			// else if([f isEqualToString:@"Crypt"]) fc=[PDFCryptStream class];
			if(!fc)
				{
				NSLog(@"Stream filter %@ not implemented", [f value]);
				return nil;
				}
			param=[params objectAtIndex:i];
			// check for NSNull -> nil
			self=[[fc alloc] initWithPrevious:self dictionary:dict parameters:param];
			}
		}
	return self;
}

- (void) dealloc;
{
	[_dict release];
	[_previous release];
	[_source release];
	[_result release];
	[super dealloc];
}

- (id) objectForKey:(NSString *) key; { return [_dict objectForKey:key]; }

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ at %u..%u: %@", NSStringFromClass([self class]), _start, _start+_len, _dict];
}

- (unsigned) decodedLength;	{ return _len; } // a hint only (0 if not available)
- (unsigned) length; { return _len; }
- (NSData *) decode; { return [_source subdataWithRange:NSMakeRange(_start, _len)]; }
- (NSData *) data;
{ // cache decoded result
	if(!_result)
		_result=[[self decode] retain];
	return _result;
}

@end
