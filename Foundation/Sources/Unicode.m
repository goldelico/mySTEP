/* 
   Unicode.m

   Support functions for Unicode implementation

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:	Stevo Crvenkovski <stevo@btinternet.com>
   Date:	March 1997

   This file is part of the mGSTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSCharacterSet.h>

struct _ucc_ { unichar from; char to; };

#include "Unicode.h"
#include "cyrillic.h"
#include "nextstep.h"
#include "caseconv.h"
#include "cop.h"
#include "decomp.h"

#define ENC(encoding) NS##encoding##StringEncoding

static const NSStringEncoding __availableEncodings[] =
{
	NSASCIIStringEncoding,
	NSNonLossyASCIIStringEncoding,
	NSUTF8StringEncoding,
	NSNEXTSTEPStringEncoding,
	NSISOLatin1StringEncoding,
	NSUnicodeStringEncoding,
	NSCyrillicStringEncoding,
	NSMorseCodeStringEncoding,
	0
};

const NSStringEncoding *_availableEncodings(void)	{ return __availableEncodings; }

static int asciiencoder(UTF32Char u, unsigned char **p)
{
	if(u >= 128)
		return 0;	// can't encode
	*(*p)++=u;	// save just lower 7 bits
	return 1;
}

static int ascii8encoder(UTF32Char u, unsigned char **p)
{
	if(u >= 256)
		return 0;	// can't encode
	*(*p)++=u;	// save lower 8 bits
	return 1;
}

static int morsecodeencoder(UTF32Char u, unsigned char **p)
{
	// look up character and append string to *p
	// append ' '
	return 0;	// can't encode
}

static int UTF8encoder(UTF32Char u, unsigned char **p)
{
//	if(u == 0xFEFF)
//		return 1;   // strip off Byte Order Mask by ignoring
	if(u<0x7f)
		*(*p)++=u;
	else if(u<0x7ff)
		*(*p)++=192 + (u/64),	// assume that the compiler knows how to optimize to a bit shift
		*(*p)++=128 + (u%64);	// assume that the compiler knows how to optimize to a bit mask
	else if(u<0xffff)
		*(*p)++=224 + (u/4096),
		*(*p)++=128 + ((u/64)%64),
		*(*p)++=128 + (u%64);
	else if(u<0x1ffff)
		*(*p)++=240 + (u/262144),
		*(*p)++=128 + ((u/4096)%64),
		*(*p)++=128 + ((u/64)%64),
		*(*p)++=128 + (u%64);
	else if(u<0x3ffffff)
		*(*p)++=248 + (u/16777216),
		*(*p)++=128 + ((u/262144)%64),
		*(*p)++=128 + ((u/4096)%64),
		*(*p)++=128 + ((u/64)%64),
		*(*p)++=128 + (u%64);
	else if(u<0x7fffffff)
		*(*p)++=252 + (u/1073741824),
		*(*p)++=128 + ((u/16777216)%64),
		*(*p)++=128 + ((u/262144)%64),
		*(*p)++=128 + ((u/4096)%64),
		*(*p)++=128 + ((u/64)%64),
		*(*p)++=128 + (u%64);
	else
		return 0;   // encoding error
	return 1;	// ok
}

static int standarduniencoder(UTF32Char u, unsigned char **p)
{
	if(u >= 65536)
		return 0;	// can't encode
	*(*p)++=u>>8;	// upper 8 bits
	*(*p)++=u;		// lower 8 bits
	return 1;
}

static int nextstepencoder(UTF32Char u, unsigned char **p)
{
	int i;
	BOOL r;
	if(u < Next_conv_base)
		{
		*(*p)++=u;		// lower 8 bits
		return 1;
		}
	i=0;
	while(((r = u - Next_uni_to_char_table[i++].from) > 0) && (i < Next_uni_to_char_table_size))
		;	// search
	if(r)
		return 0;	// not found
	*(*p)++=Next_uni_to_char_table[--i].to;
	return 1;
}

static int cyrillicencoder(UTF32Char u, unsigned char **p)
{
	int i;
	BOOL r;
	if(u < Cyrillic_conv_base)
		{
		*(*p)++=u;		// lower 8 bits
		return 1;
		}
	i=0;
	while(((r = u - Cyrillic_uni_to_char_table[i++].from) > 0) && (i < Cyrillic_uni_to_char_table_size))
		;	// search
	if(r)
		return 0;	// not found
	*(*p)++=Cyrillic_uni_to_char_table[--i].to;
	return 1;
}

uniencoder encodeuni(NSStringEncoding enc)
{ // get appropriate encoder function
	switch(enc)
		{
		case ENC(ASCII):			return asciiencoder;
		case ENC(NonLossyASCII):
		case ENC(ISOLatin1):		return ascii8encoder;
		case ENC(UTF8):				return UTF8encoder;
		case ENC(Unicode):			return standarduniencoder;
		case ENC(NEXTSTEP):			return nextstepencoder;
		case ENC(Cyrillic):			return cyrillicencoder;
		case ENC(MorseCode):		return morsecodeencoder;
		default:					return NULL;	// can't encode
		}
}

static UTF32Char asciidecoder(unsigned char **p)
{
	return *(*p)++;
}

static UTF32Char morsecodedecoder(unsigned char **p)
{
	// skip whitespace (maybe all unknown characters besides . and -)
	// decode and look up pattern from *p until unrecognized character
	return 0;	// can't encode
}

static UTF32Char UTF8decoder(unsigned char **p)
{
	// FIXME
	UTF32Char z=*(*p)++;	// first byte
	if(z<=127)
		return z;  // plain 7 bit ASCII
	else if(z<=223)
		return (z-192)*64+(*(*p)++-128);	// note: we may read past end of *p and do not detect invalid encodings which might be a security issue!
	else if(z<=239)
		{
		z=(z-224)*4096;
		z+=(*(*p)++-128)*64;
		z+=(*(*p)++-128);
		return z;
		}
	else if(z<=247)
		{
		z=(z-240)*262144;
		z+=(*(*p)++-128)*4096;
		z+=(*(*p)++-128)*64;
		z+=(*(*p)++-128);
		return z;
		}
	else if(z<=251)
		{
		z=(z-248)*16777216;
		z+=(*(*p)++-128)*262144;
		z+=(*(*p)++-128)*4096;
		z+=(*(*p)++-128)*64;
		z+=(*(*p)++-128);
		return z;
		}
	else if(z<=253)
		{
		z=(z-252)*1073741824;
		z+=(*(*p)++-128)*16777216;
		z+=(*(*p)++-128)*262144;
		z+=(*(*p)++-128)*4096;
		z+=(*(*p)++-128)*64;
		z+=(*(*p)++-128);
		return z;
		}
	else
		return (char) z; // invalid 254/255 (e.g. Unicode BOM) - will expand to 0xfffffffe and 0xffffffff
}

static UTF32Char standardunidecoder(unsigned char **p)
{ // 16 byte only
	unichar c=*(*p)++;
	c=(c<<8)+*(*p)++;
	return c;
}

static UTF32Char swappedunidecoder(unsigned char **p)
{ // 16 byte only
	unichar c=*(*p)++;	// low byte first
	c+=(*(*p)++)<<8;
	return c;
}

static UTF32Char nextstepunidecoder(unsigned char **p)
{
	unsigned char c=*(*p)++;
	if(c < Next_conv_base)
		return (c);
	return(Next_char_to_uni_table[c - Next_conv_base]);
}

static UTF32Char cyrillicunidecoder(unsigned char **p)
{
	unsigned char c=*(*p)++;
	if(c < Cyrillic_conv_base)
		return (c);
	return(Cyrillic_char_to_uni_table[c - Cyrillic_conv_base]);
}

unidecoder decodeuni(NSStringEncoding enc)		// get appropriate decoder function
{
	switch(enc)
		{
		case ENC(NonLossyASCII):
		case ENC(ASCII):
		case ENC(ISOLatin1):		return asciidecoder;
		case ENC(UTF8):				return UTF8decoder;
		case ENC(Unicode):			return standardunidecoder;
		case ENC(SwappedUnicode):	return swappedunidecoder;
		case ENC(NEXTSTEP):			return nextstepunidecoder;
		case ENC(Cyrillic):			return cyrillicunidecoder;
		case ENC(MorseCode):		return morsecodedecoder;
		default:					return NULL;	// can't encode
		}
}

#if OLD

unichar encode_chartouni(unsigned char c, NSStringEncoding e)
{	
	switch(e)
		{
		case ENC(NonLossyASCII):
		case ENC(ASCII):
		case ENC(ISOLatin1):
			return (unichar)(c);

	// All that I could find in Next documentation on 
	// NSNonLossyASCIIStringEncoding was <<forthcoming>

		case NSNEXTSTEPStringEncoding:
			{
			}
		case NSCyrillicStringEncoding:
			{
				if(c < Cyrillic_conv_base)
					return (unichar)(c);
				return(Cyrillic_char_to_uni_table[c - Cyrillic_conv_base]);
			}
		default:
			return 0;	// can't convert
		}
	return (unichar)(c);
}

char encode_unitochar(unichar u, NSStringEncoding e)
{
	int r, i;
    switch(e)
		{
		case NSNonLossyASCIIStringEncoding:
		case NSASCIIStringEncoding:
			return (u < 128) ? (char)u : 0;
		case NSISOLatin1StringEncoding:
			return (u < 256) ? (char)u : 0;
		case NSNEXTSTEPStringEncoding:
			{
				if(u < (unichar)Next_conv_base)
					return (char)u;
				i=0;
				while(((r = u - Next_uni_to_char_table[i++].from) > 0) 
						& (i < Next_uni_to_char_table_size));
				return r ? 0 : Next_uni_to_char_table[--i].to;
			}
		case NSCyrillicStringEncoding:
			{
				if(u < (unichar)Cyrillic_conv_base)
					return (char)u;
				i=0;
				while(((r = u - Cyrillic_uni_to_char_table[i++].from) > 0) 
						  & (i < Cyrillic_uni_to_char_table_size));
				return r ? 0 : Cyrillic_uni_to_char_table[--i].to;
			}
		// add other code tables like MacRoman or ANSI, Windows, etc.
		default:
			// FIXME
			break;
		}
    return 0;
}

unichar chartouni(char c)
{
	if (_encoding == 0) 
		_encoding = [NSString defaultCStringEncoding];
	return encode_chartouni(c, _encoding);
}

char unitochar(unichar u)
{
	unsigned char r;
	if (_encoding == 0) 
		_encoding = [NSString defaultCStringEncoding];
	return (r = encode_unitochar(u, _encoding)) ? r : '*';
}

int strtoustr(unichar * u1, const char *s1, int size)
{
	int count;
	for(count = 0; (s1[count] != 0) & (count < size); count++)
		u1[count] = chartouni(s1[count]);
	return count;
}
 
#endif

#if OLD	// still used

int ustrtostr(char *s2, unichar *u1, int size, NSStringEncoding enc)
{
	int count, a;
	unsigned char r;
	uniencoder e=encodeuni(enc);
	if (_encoding == 0) 
		_encoding = [NSString defaultCStringEncoding];
    if((_encoding == ENC(NonLossyASCII)) || (_encoding == ENC(ASCII)))
		a = 128;
	else
		a = (_encoding == NSISOLatin1StringEncoding) ? 256 : 0;

	if(!a)
		for(count = 0; (u1[count] != (unichar)0) & (count < size); count++)
			s2[count] = (r = encode_unitochar(u1[count], _encoding)) ? r : '*';
	else
		for(count = 0; (u1[count] != (unichar)0) & (count < size); count++)
			s2[count] = (u1[count] < a) ? (char)u1[count] : '*';

	return count;
}

#endif

// should use UTF32Char!

#if 0

int  encode_strtoustr(unichar * u1, const unsigned char *s1, int size, NSStringEncoding enc)
{
int count;

	if(enc == NSUTF8StringEncoding)
		{ // read size bytes from s1 and store to unichar *u1 - return real length; u1 is allocated for size unichars
		int i;
#if 0
		NSLog(@"UTF-8 not yet implemented - reads as ASCII");
#endif
		count=0;
		for(i=0; i<size; i++)
			{
			unsigned z=s1[i];
			if(z<=127)
				u1[count++]=s1[i];  // plain 7 bit ASCII
			else if(z<=223)
				(u1[count++]=(s1[i]-192)*64+(s1[i+1]-128)), i++;	// note: we may read past end of s1[] and do not detect invalid encodings which might be a security issue!
			else if(z<=239)
				(u1[count++]=(s1[i]-224)*4096+(s1[i+1]-128)*64+(s1[i+2]-128)), i+=2;
			else if(z<=247)
				(u1[count++]=(s1[i]-240)*262144+(s1[i+1]-128)*4096+(s1[i+2]-128)*64+(s1[i+3])), i+=3;
			else if(z<=251)
				(u1[count++]=(s1[i]-248)*16777216+(s1[i+1]-128)*262144+(s1[i+2]-128)*4096+(s1[i+3]-128)*64+(s1[i+4])), i+=4;
			else if(z<=253)
				(u1[count++]=(s1[i]-252)*1073741824+(s1[i+1]-128)*16777216+(s1[i+2]-128)*262144+(s1[i+3]-128)*4096+(s1[i+4]-128)*64+(s1[i+5])), i+=5;
			else
				u1[count++]=s1[i]; // invalid 254/255 - will expand to 0xfffffffe and 0xffffffff
			}
		return count;
		}
	for(count = 0; (s1[count] != 0) & (count < size); count++)
		u1[count] = encode_chartouni(s1[count], enc);
	return count;
}

int encode_ustrtostr(unsigned char *s2, int maxlen, unichar *u1, int size, NSStringEncoding enc, BOOL allowLossy)
{
	int count;
#if 1
	NSLog(@"encode %u bytes to %u encoding %d %@", size, maxlen, enc, allowLossy?@"lossy":@"");
#endif
	if(enc == NSUTF8StringEncoding)
		{ // read size characters from unichar *u1 - return real length; s2 is allocated for ??? chars !!! we might need up to 6*size bytes
		unsigned char *cp=s2;
		unsigned char *end=s2+maxlen-6;
		for(count=0; count<size; count++)
			{
			UTF32Char u=u1[count];
			if(cp >= end)
				return 0;	// can't encode
			if(u == 0xFEFF && count == 0)
				continue;   // strip off Byte Order Mask
			if(u<0x7f)
				*cp++=u;
			else if(u<0x7ff)
				*cp++=192 + (u/64),
				*cp++=128 + (u%64);
			else if(u<0xffff)
				*cp++=224 + (u/4096),
				*cp++=128 + ((u/64)%64),
				*cp++=128 + (u%64);
			else if(u<0x1ffff)
				*cp++=240 + (u/262144),
				*cp++=128 + ((u/4096)%64),
				*cp++=128 + ((u/64)%64),
				*cp++=128 + (u%64);
			else if(u<0x3ffffff)
				*cp++=248 + (u/16777216),
				*cp++=128 + ((u/262144)%64),
				*cp++=128 + ((u/4096)%64),
				*cp++=128 + ((u/64)%64),
				*cp++=128 + (u%64);
			else if(u<0x7fffffff)
				*cp++=252 + (u/1073741824),
				*cp++=128 + ((u/16777216)%64),
				*cp++=128 + ((u/262144)%64),
				*cp++=128 + ((u/4096)%64),
				*cp++=128 + ((u/64)%64),
				*cp++=128 + (u%64);
			else
				return 0;   // encoding error
			}
		return cp-s2;   // real length
		}
	if(maxlen < size)
		size=maxlen;	// limit to smaller
	for(count = 0; count < size; count++)
		{
		int c=encode_unitochar(u1[count], enc);
		if(c==0)
			{ // no conversion
			if(!allowLossy)
				return 0;   // can't convert
			c='*';  // substitute
			}
		s2[count] = c;
		}
	return count;
}
#endif

int uslen (unichar *u)					// Be careful if you use this. Unicode 
{										// arrays returned by -getCharacters
	int len = 0;						// methods are not zero terminated
	while(u[len] != 0)
		++len;
	return len;
}

unichar uni_tolower(unichar ch)
{
	int r;
	int count = 0;
	while(((r = ch - t_tolower[count++][0]) > 0) & (count < t_len_tolower));
		return r ? ch : t_tolower[--count][1];
}
 
unichar uni_toupper(unichar ch)
{
	int r, count = 0;
	while(((r = ch - t_toupper[count++][0]) > 0) & (count < t_len_toupper));
		return r ? ch : t_toupper[--count][1];
 }

unsigned char uni_cop(unichar u)
{
	if (u > (unichar)0x0080)						// no nonspacing in ascii
		{
		unichar count = 0, first = 0, last = uni_cop_table_size, comp;
		BOOL notfound = YES;
		while (notfound & (first <= last))
			{
			if(!(first == last))
				{
				count = (first + last) / 2;
				comp = uni_cop_table[count].code;		
				if(comp < u)
					first = count+1;
				else if(comp > u)
					last = count-1;
				else
					notfound = NO;
				}
			else  										// first == last
				{
				if(u == uni_cop_table[first].code)
					return uni_cop_table[first].cop;		
				return 0;	
				}
			}										// else while not found
		return (notfound) ? 0: uni_cop_table[count].cop;
		}
													// u is ascii
	return 0;
}

BOOL uni_isnonsp(unichar u)			{ return (uni_cop(u)) ? YES : NO; }

unichar *uni_is_decomp(unichar u)
{
	if(u > (unichar)0x0080)  						// no composites in ascii
		{
		unichar count = 0, first = 0, last = uni_dec_table_size, comp;
		BOOL notfound = YES;
		
		while(notfound & (first <= last))
			{
			if(!(first == last))
				{
				count = (first + last) / 2;
				comp = uni_dec_table[count].code;

				if(comp < u)
					first = count+1;
				else if(comp > u)
					last = count-1;
				else
					notfound = NO;
				}
			else										// first == last
				{
				if(u == uni_dec_table[first].code)
					return uni_dec_table[first].decomp;

				return 0;
			}	}										// else while not found

		return (notfound) ? 0 : uni_dec_table[count].decomp;
		}
	// u is ascii
	return 0;
}

// EOF
