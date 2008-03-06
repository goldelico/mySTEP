//
//  PDFParser.m
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#include <string.h>
#include <ctype.h>
#import "PDFKitPrivate.h"

// PDF Engine

#define ishexnum(c) (isdigit(c) || ((c)>='a' && (c)<='f') || ((c)>='A' && (c)<='F'))

@implementation PDFParser

#define IS_PDF_VERSION(MAJOR,MINOR) ([_doc majorVersion] == MAJOR && [_doc minorVersion] == MINOR)
#define IS_PDF_VERSION_ORLATER(MAJOR,MINOR) ([_doc majorVersion] > MAJOR || ([_doc majorVersion] == MAJOR && [_doc minorVersion] >= MINOR))

+ (PDFParser *) parserWithData:(NSData *) src; { return [[[self alloc] initWithData:src] autorelease]; }

- (id) initWithData:(NSData *) src;
{
	if((self=[super init]))
		{
		_source=[src retain];
		_bytes=[_source bytes];
		_end=[_source length];
		}
	return self;
}

- (void) _setPDFDocument:(PDFDocument *) doc; { _doc=doc; }

- (void) dealloc;
{
	[_source release];
	[super dealloc];
}

- (void) setParseLocation:(unsigned) pos; { _pos=pos; }
- (unsigned) parseLocation; { return _pos; }

#define getch() (_pos >= _end?-1:_bytes[_pos++])
// #define curch() (_pos >= _end?-1:_bytes[_pos])
#define ungetch() if(_pos < _end) _pos--
#define whitespace(C) (C == ' ' || C == '\t' || C == '\f' || C == '\r' || C == '\n')
#define delim(C) (whitespace(C) || C<0 || C == '(' || C == ')' || C == '<' || C == '>' || C == '[' || C == ']' || C == '{' || C == '}' || C == '/' || C == '%')
#define white() ({ int _white_c; while((_white_c=getch()), whitespace(_white_c)); _white_c; })

- (BOOL) keyword:(char *) kw;
{
	unsigned p;
	int c;
	c=white();
#if 0
	NSLog(@"1: c=%02x kw=%s", c, kw);
#endif
	p=_pos-1;	// save to back up to first non-space
	if(c == *kw)
		{ // first character fits
		do
			{
			kw++;
			c=getch();
			}
		while(*kw && c == *kw);	// eat while it fits
		}
#if 0
	NSLog(@"2: c=%02x *kw=%02x", c, *kw);
#endif
	if(*kw == 0 && delim(c))
		{ // found
#if 0
		NSLog(@"keyword found");
#endif
		ungetch();
		return YES;
		}
	_pos=p;	// backup to first non-space
	return NO;
}

- (void) _pdfLog;
{ // log next 30 characters
	int i;
	unsigned p=_pos;
	if(_pos > 20)
		_pos-=20;
	else
		_pos=0;
	for(i=0; i<40; i++)
		{
		int ch=getch();
		if(ch > 0)
			printf("%c", ch);
		}
	printf("\n");
	_pos=p;	// restore
}

- (unsigned) _parseUnsignedInt;
{
	int c=white();
	unsigned n;
	if(!isdigit(c))
		return 0;
	n=(c-'0');	// first digit of generation
	while((c=getch(), isdigit(c)))
		n=10*n+(c-'0');	// collect digits
	return n;
}

- (id) _parseObject;
{ // parse a single PDF object
	int c;
nextline:
#if 0
	NSLog(@"%02x", getch());
	ungetch();
#endif
	switch((c=white()))
		{
		case -1:
			return nil;	// end of file
		case '%':	// comment - skip to end of line
			while((c=getch()) != '\r' && c != '\n')
				;
			goto nextline;
		case '<':	// hex NSString
			{
				unsigned len;
				char *bfr;
				char *bp;
				NSString *s;
				if((c=getch()) == '<')
					{ // NSDictionary
					NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:10];
					id key, obj;
					while((white() != '>'))
						{
						ungetch();	// back up
						key=[self _parseObject];
#if 0
						NSLog(@"key=%@", key);
#endif
						if(!key || ![key isPDFAtom])
							return nil;	// error
						obj=[self _parseObject];
#if 0
						NSLog(@"obj=%@", obj);
#endif
						if(!obj)
							return nil;	// error
						if(![obj isMemberOfClass:[NSNull class]])
							[dict setObject:obj forKey:[key value]];	// store
						}
					if((getch() != '>'))
					   return nil;	// second > is missing
					if([self keyword:"stream"])
						{ // make PDFStream
						PDFStream *stream;
						unsigned p0;	// we must save the position because PDFStream may dereference indirect objects in dict or _trailer
						if(getch() != '\r')
							ungetch();	// not optional LF
						if(getch() != '\n')
							ungetch();	// not optional LF
						stream=[[[PDFStream alloc] initWithDoc:_doc raw:_source dictionary:dict atPos:p0=_pos] autorelease];
						if(!stream)
							return nil;	// can't decode
						_pos=p0+[[[dict objectForKey:@"Length"] self] unsignedIntValue];	// go to end of stream
#if 0
						NSLog(@"PDFStream: %@ - %u -> ca. %u", stream, [stream length], [stream decodedLength]);
						NSLog(@"pos: %u ... %u", p0, _pos);
						[self _pdfLog];
#endif
						if(![self keyword:"endstream"])
							{ // Length seems to be corrupt
							NSLog(@"PDFStream: missing 'endstream' or /Length error - Producer=%@", [[_doc documentAttributes] objectForKey:@"Creator"]);
							// search starting at p0 for "endstream" keyword
							}
						return stream;
						}
#if 0
					NSLog(@"Dict: %@", dict);
#endif
					return dict;
					}
				bfr=malloc(len=100);
				if(!bfr)
					return nil;
				bp=bfr;	// store pointer
				while((c=white()) >= 0)
					{
					int chr;
					if(c == '>')
						break;	// done
					if(c >= '0' && c <= '9')
						chr=16*(c-'0');
					else if((c >= 'a' && c <='f') || (c >= 'A' && c <='F'))
						chr=16*((c-'a'+10)%16);
					else
						return nil;
					c=white();
					if(c != '>')
						{
						if(c >= '0' && c <= '9')
							chr+=(c-'0');
						else if((c >= 'a' && c <='f') || (c >= 'A' && c <='F'))
							chr+=((c-'a'+10)%16);
						else
							return nil;
						}
					else
						ungetch();	// back up
					if(bp >= bfr+len)
						{ // needs more space
						bfr=realloc(bfr, len=2*len+100);
						if(!bfr)
							return nil;
						}
					*bp++=chr;	// store
					}
				s=[NSString stringWithCString:bfr length:bp-bfr];
				free(bfr);
#if 0
				NSLog(@"Hex String: %@", s);
#endif
				return s;
			}
		case '(':	// NSString
			{
				unsigned paired=0;
				unsigned len;
				char *bfr=malloc(len=100);
				char *bp=bfr;	// store pointer
				NSString *s;
				if(!bfr)
					return nil;
				while((c=getch()) >= 0)
					{
					if(c == '\\')
						{ // escaped string
						c=getch();	// get next one
						switch(c)
							{
							case '\r':
								if(getch() != '\n')
									ungetch();
							case '\n':
								continue;
							case 'n':	c='\n'; break;
							case 'r':	c='\r'; break;
							case 't':	c='\t'; break;
							case 'b':	c='\b'; break;
							case 'f':	c='\f'; break;
							default:
								{
								if(c >= '0' && c <= '7')
									{ // check for \ddd sequence (octal)
									int n=(c-'0');
									c=getch();	// get next one
									if(c >= '0' && c <= '7')
										{
										n=8*n+((c-'0')%8);
										c=getch();	// get next one
										if(c >= '0' && c <= '7')
											c=8*n+((c-'0')%8);
										else
											ungetch();
										}
									else
										ungetch();
									break;
									}
								}
							}
						}
					else if(c == '\r')
						{ // skip LF if CRLF sequence
						if(getch() != '\n')
							ungetch();
						c='\n';	// always translate
						}
					else if(c == ')' && paired-- == 0)
						break;	// done
					else if(c == '(')
						paired++;
					if(bp >= bfr+len)
						{ // needs more space
						bfr=realloc(bfr, len=2*len+100);
						if(!bfr)
							return nil;
						}
					*bp++=c;	// store
					}
				s=[NSString stringWithCString:bfr length:bp-bfr];
				free(bfr);
#if 0
				NSLog(@"String: %@", s);
#endif
				return s;
			}
		case '/':	// Atomic Literal
			{
				unsigned len;
				char *bfr=malloc(len=100);
				char *bp=bfr;	// store pointer
				NSString *s;
				if(!bfr)
					return nil;
				while((c=getch()) >= 0)
					{
					switch(c)
						{
							// whitespace
						case 0:
						case '\r':
						case '\n':
						case '\t':
						case '\f':
						case ' ':
							// delimiter
						case '(':
						case ')':
						case '<':
						case '>':
						case '[':
						case ']':
						case '{':
						case '}':
						case '/':
						case '%':
							ungetch();	// back up
							break;
							// special
						case '#':
							if(IS_PDF_VERSION_ORLATER(1,2))
								{ // get 2 hext digits
								int cc;
								cc=getch();
								if(cc > '9')
									c=16*((cc-'a'+10) %16);
								else
									c=16*(c-'0');
								cc=getch();
								if(cc > '9')
									c+=((cc-'a'+10) %16);
								else
									c+=(c-'0');
								}
						default:
							{
								if(bp >= bfr+len-1)
									{ // needs more space
									bfr=realloc(bfr, len=2*len+100);
									if(!bfr)
										return nil;
									}
								*bp++=c;	// store
								continue;
							}
						}
					break;
					}
				*bp=0;	// we can't use the length parameter
				s=[NSString stringWithUTF8String:bfr];
				free(bfr);
#if 0
				NSLog(@"Atom: %@", s);
#endif
				return [[[PDFAtom alloc] initWithString:s] autorelease];
			}
		case '[':	// NSArray of elements
			{
				NSMutableArray *a=[NSMutableArray arrayWithCapacity:10];
				id obj;
				while((white() != ']'))
					{
					ungetch();	// back up
					obj=[self _parseObject];
					if(!obj)
						return nil;	// invalid
					[a addObject:obj];
					}
#if 0
				NSLog(@"Array: %@", a);
#endif
				return a;
			}
		}
	if(c == '+' || c == '-' || c == '.' || isdigit(c))
		{ // collect number(s) and push them on the stack
		char bfr[30];
		char *cp=bfr;
		double dbl;
		BOOL isDbl=(c == '.');
		long i;
		id obj;
		unsigned spos;
		unsigned gen;
		*cp++=c;
		while((c=getch(), (c == '.' || isdigit(c))) && cp < &bfr[sizeof(bfr)/sizeof(bfr[0])-1])
			{
			if(c == '.')
				isDbl=YES;
			*cp++=c;	// store
			}
		*cp=0;
#if 0
		NSLog(@"number: %s", bfr);
#endif
		spos=(--_pos);	// first non-digit character
		if(!isDbl && sscanf(bfr, "%ld", &i) == 1)
			obj=[NSNumber numberWithInt:i];	// appears to be integer
		else if(sscanf(bfr, "%lf", &dbl) == 1)
			obj=[NSNumber numberWithDouble:dbl];
		else
			return nil;	// error
		if(isDbl)
			return obj;	// first part for "d d R" can't be a double
		c=white();
		if(!isdigit(c))
			{ // not a second number
			ungetch();
			return obj;
			}
#if 0
		NSLog(@"could be '%s n R' or '%s n obj'", bfr, bfr);
#endif
		gen=(c-'0');	// first digit of generation
		while((c=getch(), isdigit(c)))
			gen=10*gen+(c-'0');	// collect digits
#if 0
		NSLog(@" (c=%02x:%c)", c, c);
#endif
		ungetch();
		if([self keyword:"R"])
			{ // d d R
			return [[[PDFReference alloc] initWithNumber:[obj unsignedIntValue] andGeneration:gen forDocument:_doc] autorelease];
			}
		if([self keyword:"obj"])
			{ // is obj definition
//			unsigned num=[obj unsignedIntValue];	// object number
			obj=[self _parseObject];	// parse object
			if(!obj)
				return nil;	// was not able to parse
			// check that it is not a recursive indirect def! -- why not?
			// check that it is not a keyword
			if(![self keyword:"endobj"])
				{
				NSLog(@"missing 'endobj'");
					// we could simply ignore an error here...
				return nil;
				}
			// look up/store in crossref table (if not yet!) so that the table is (re)built by forward reading objects
			return obj;
			}
#if 0
		NSLog(@"back up (c=%02x:%c)", c, c);
#endif
		_pos=spos;	// back up
		return obj;	// return first number
		}
	if(!delim(c))
		{ // must be a PDF keyword
		char bfr[30];
		char *cp=bfr;
		*cp++=c;
		while((c=getch(), !delim(c)) && cp < &bfr[sizeof(bfr)/sizeof(bfr[0])-1])
			*cp++=c;	// store
		ungetch();	// go back to first non-matching character
		*cp=0;
#if 0
		NSLog(@"_parseObject: keyword %s", bfr);
#endif
		if(strcmp(bfr, "null") == 0)
			return [NSNull null];
		if(strcmp(bfr, "true") == 0)
			return [NSNumber numberWithBool:YES];
		if(strcmp(bfr, "false") == 0)
			return [NSNumber numberWithBool:NO];
#if 0
		NSLog(@"other keyword: %s", bfr);
#endif
		return [[[PDFKeyword alloc] initWithString:[NSString stringWithCString:bfr]] autorelease];
		}
	NSLog(@"unrecognized character: %02x", (unsigned) c);
	[self _pdfLog];
	return nil;
}

- (id) _parseXrefAndTrailer;
{ // read xref ... trailer ... %% EOF block going back to /Prev xref tables
	NSDictionary *trailer, *firstTrailer=nil;
	while(_pos != 0)
		{ // read all sections
		if(![[self _parseObject] isPDFKeyword:@"xref"])
			{ // should be "xref" keyword
#if 1
			NSLog(@"missing xref keyword");
			[self _pdfLog];
#endif
			return nil;
			}
		do
			{
				if(![self _parseXrefSection])
					{
#if 1
					NSLog(@"invalid xref");
					[self _pdfLog];
#endif
					return nil;
					}
			} while (![self keyword:"trailer"]);	// parse multiple xref sections
#if 0
		NSLog(@"_catalog=%@", _catalog);
#endif
		trailer=[[self _parseObject] self];	// the trailer dictionary should follow - fetch even if indirect
		if(!trailer || ![trailer isKindOfClass:[NSDictionary class]])
			{
#if 1
			NSLog(@"missing or invalid trailer dictionary");
			[self _pdfLog];
#endif
			return nil;
			}
		if(!firstTrailer)
			firstTrailer=trailer;	// is the last one in the file but the first one that we read
		_pos=[[trailer objectForKey:@"Prev"] unsignedIntValue];	// position of potentially existing previous header
		}
	return firstTrailer;
}

- (BOOL) _parseXrefSection;
{ // parse a single Xref section
	id first, entries;
	unsigned firstNum;
	unsigned i, cnt;
	NSMutableDictionary *catalog;
	first=[self _parseObject];	// first number
	if(!first || ![first isKindOfClass:[NSNumber class]])
		return NO;
	if(!isdigit(white()))
		{ // xref stream?
		NSLog(@"xref stream");
		return NO;
		}
	ungetch();
	entries=[self _parseObject];	// number of entries
#if 0
	NSLog(@"%@ entries", entries);
#endif
	if(!entries || ![first isKindOfClass:[NSNumber class]])
		return NO;
	firstNum=[first unsignedIntValue];
	cnt=[entries unsignedIntValue];
	catalog=[_doc _catalog];	// get reference
	for(i=0; i<cnt; i++)
		{ // there follow n records/lines with 20 bytes each: 10 digits obj.num and 5 digits generation + 1 character
		unsigned position, generation;
		BOOL f;
		PDFCrossReference *ref;
		id key;
#if 0
		NSLog(@"%u-st of %u entries", i+1, cnt);
#endif
		// here we know that this should be unsigned numbers!
		position=[self _parseUnsignedInt];
		generation=[self _parseUnsignedInt];
		key=[PDFReference keyForNumber:firstNum+i andGeneration:generation];
		if([catalog objectForKey:key])
			continue;	// keep the first (i.e. latest) definition only
		switch(white())
			{
			case 'n':	f=NO; break;
			case 'f':	f=YES; break;
			default:
				return NO;	// invalid character
			}
		ref=[[[PDFCrossReference alloc] initWithData:_source pos:position number:firstNum+i generation:generation isFree:f] autorelease];
#if 0
		NSLog(@"xref=%@ [%@]", ref, [PDFReference keyForNumber:firstNum+i andGeneration:generation]);
#endif
		[catalog setObject:ref forKey:key];	// store in catalog
		}
	return YES;
}

@end