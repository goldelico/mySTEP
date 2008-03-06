//
//  PDFDocument.m
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#include <string.h>
#import "PDFKitPrivate.h"

// aligned with the Info dictionary of the trailer
NSString *PDFDocumentTitleAttribute=@"Title";
NSString *PDFDocumentAuthorAttribute=@"Author";
NSString *PDFDocumentSubjectAttribute=@"Subject";
NSString *PDFDocumentCreatorAttribute=@"Creator";
NSString *PDFDocumentProducerAttribute=@"Producer";
NSString *PDFDocumentCreationDateAttribute=@"CreationDate";
NSString *PDFDocumentModificationDateAttribute=@"ModDate";
NSString *PDFDocumentKeywordsAttribute=@"Keywords";

NSString *PDFDocumentDidBeginFindNotification=@"PDFDocumentDidBeginFindNotification";
NSString *PDFDocumentDidEndFindNotification=@"PDFDocumentDidEndFindNotification";
NSString *PDFDocumentDidBeginPageFindNotification=@"PDFDocumentDidBeginPageFindNotification";
NSString *PDFDocumentDidEndPageFindNotification=@"PDFDocumentDidEndPageFindNotification";
NSString *PDFDocumentDidFindMatchNotification=@"PDFDocumentDidFindMatchNotification";
NSString *PDFDocumentDidUnlockNotification=@"PDFDocumentDidUnlockNotification";

#ifdef __mySTEP__
NSString *kCGPDFContextOwnerPassword=@"PDFContextOwnerPassword";
NSString *kCGPDFContextUserPassword=@"PDFContextUserPassword";
NSString *kCGPDFContextAllowsCopying=@"PDFContextAllowsCopying";
NSString *kCGPDFContextAllowsPrinting=@"PDFContextAllowsPrinting";
#endif

@implementation PDFDocument

// document attributes

- (BOOL) allowsCopying;
{
	NSDictionary *enc=[[_trailer objectForKey:@"Encrypt"] self];
	if(!enc)
		return YES;	// not encrypted
	return ([[enc objectForKey:@"P"] intValue] & (1<<5)) != 0;
}

- (BOOL) allowsPrinting;
{
	NSDictionary *enc=[[_trailer objectForKey:@"Encrypt"] self];
	if(!enc)
		return YES;	// not encrypted
	return ([[enc objectForKey:@"P"] intValue] & (1<<3)) != 0;
}

- (BOOL) isEncrypted; { return [_trailer objectForKey:@"Encrypt"] != nil; }
- (BOOL) isFinding; { NIMP; return NO; }
- (BOOL) isLocked; { return _isLocked; }
- (int) majorVersion; { return major; }
- (int) minorVersion; { return minor; }

- (NSDictionary *) documentAttributes; { return [[_trailer objectForKey:@"Info"] self]; }
- (void) setDocumentAttributes:(NSDictionary *) dict;
{
	[_trailer setObject:dict forKey:@"Info"];
	[self _touch];
}

- (NSData *) _dataRepresentationWithOptions:(NSDictionary *) opts;
{
	if(!_touched)
		return _raw;
	// generate new PDF-1.3 or 1.4 file from document tree
	// may be incremental to existing raw document
	return nil;
}

- (NSData *) dataRepresentation; { return [self _dataRepresentationWithOptions:nil]; }

- (NSMutableDictionary *) _root; { return _root; }
- (NSMutableDictionary *) _trailer; { return _trailer; }

- (NSURL *) documentURL; { return _url; }

- (id) initWithURL:(NSURL *) url;
{
	// check for local file and use mappedFile:
	NSData *data;
	if([url isFileURL])
		data=[NSData dataWithContentsOfMappedFile:[url path]];
	else
		data=[NSData dataWithContentsOfURL:url];
	if(!data)
		{ // file contents not available
#if 1
		NSLog(@"could not fetch data from %@", url);
#endif
		[self release];
		return nil;
		}
	_url=[url retain];
	return [self initWithData:data];
}

- (id) initWithData:(NSData *) data;
{
	self=[super init];
	if(self)
		{
		_raw=[data retain];	// save
		_parser=[[PDFParser alloc] initWithData:data];	// and define parser
		[_parser _setPDFDocument:self];
		if(![self _parsePDF])
			{ // was not able to parse or repair
			[self release];
			return nil;
			}
#if 1
		NSLog(@"trailer %@", _trailer);
		NSLog(@"root %@", _root);
#endif
		_isLocked=YES;
		[self setPassword:@""];	// try to unlock
		}
	return self;
}

- (BOOL) _parsePDF;
{ // return the trailer dictionary
	id vers;
	char bfr[51];
	char *c;
	char *sx;
	int len;
	if(!_raw || (len=[_raw length]) < 14)
		return NO;	// no data
	[_raw getBytes:&bfr length:14];
	bfr[14]=0;
	if(sscanf(bfr, "%%PDF-%u.%u", &major, &minor) != 2)
		return NO;	// not a PDF
#if 1
	NSLog(@"version=%u.%u", major, minor);
#endif
	if(major != 1 || minor > 6)
		return NO;	// currently undefined or can't process
	if(!_catalog)
		_catalog=[[NSMutableDictionary alloc] initWithCapacity:100];
	if(len > 50 /* && [url isFileURL] */)
		{ // we have random access
#if 0
		NSLog(@"last 50 bytes: %@", [_raw subdataWithRange:NSMakeRange(len-50, 50)]);
#endif
		[_raw getBytes:bfr range:NSMakeRange(len-50, 50)];	// get last 50 bytes
		bfr[50]=0;
		for(c=bfr; *c; c++)
			{
			unsigned long p;
			if(strncmp(c, "startxref", 9) != 0)
				continue;
			sx=c;	// remember
			c+=9;
			while(*c == '\n' || *c == '\r')
				c++;
			if(sscanf(c, "%lu", &p) == 1)
				{
				while(*c == '\n' || *c == '\r')
					c++;
				if(strncmp(c, "%%EOF", 5) != 0)
					{ // ok!
					[_parser setParseLocation:p]; // found!
					}
				}
			}
		}
#if 0	// test stream reading mode
	[_parser setParseLocation:0];
#endif
	if([_parser parseLocation] == 0)
		{ // crossref damaged, not existent (older PDF format), or not random access
#if 1
		NSLog(@"crossref damaged or not existent (older PDF format)");
#endif
		[_parser _parseObject];	// parse first object
		// FIXME: read all objects directly and create Xref
		return NO;
		}
#if 0
	NSLog(@"xref=%@", xref);
#endif
	_trailer=[[_parser _parseXrefAndTrailer] retain];
	if(!_trailer)
		return NO;
	_root=[[[_trailer objectForKey:@"Root"] self] retain];	// fetch root object
	if(!_root)
		{
#if 1
		NSLog(@"missing or invalid root dictionary");
#endif
		return NO;	// has no root object
		}
	vers=[[_root objectForKey:@"Version"] self];
#if 0
	NSLog(@"vers=%@", vers);
#endif
	if([vers isPDFAtom])
		{ // override version (encoded as e.g. "/Version/1.6")
		if(sscanf([[vers value] cString], "%u.%u", &major, &minor) != 2)
			return NO;	// did not properly parse
		}
	return YES;
}

- (NSMutableDictionary *) _catalog; { return _catalog; }

- (PDFCrossReference *) _catalogEntryForObject:(unsigned) object generation:(unsigned) gen;
{ // dereference indirect object
	PDFCrossReference *xref;
	id obj;
#if 0
	NSLog(@"dereference '%u %u R' [%@]", object, gen, [PDFReference keyForNumber:object andGeneration:gen]);
#endif
	xref=[_catalog objectForKey:[PDFReference keyForNumber:object andGeneration:gen]];
	if(!xref)
		{
#if 1
		NSLog(@"not in catalog: '%u %u R'", object, gen);
#endif
		}
	if(![xref object])
		{ // cross reference needs to load from file
		unsigned pos=[xref position];
		if(pos == 0)
			{
#if 1
			NSLog(@"undefined scan position for '%u %u R'", object, gen);
#endif
			return nil;	// no location defined
			}
		// could also set up its private parser...
		[_parser setParseLocation:pos];
		obj=[_parser _parseObject];
#if 0
		NSLog(@"deref'd obj=%@", obj);
#endif
		if(obj)
			[xref setObject:obj];	// save in cache
		}
	return xref;	// return cross reference and not object!
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: %u pages", NSStringFromClass([self class]), [self pageCount]];
}

- (void) dealloc;
{
	[self setDelegate:nil];
	[_url release];
	[_raw release];
	[_parser release];
	[_catalog release];
	[_trailer release];
	[_root release];
	[super dealloc];
}

- (void) _touch;
{ // any change
	_touched=YES;
}

// delegate management

- (id) delegate; { return _delegate; }
- (void) setDelegate:(id) delegate;
{
	if(_delegate)
		{
		// unregister notifications
		}
	[_delegate autorelease];
	_delegate=[delegate retain];
	if(_delegate)
		{
		// register notifications
		}
}

// finding

- (void) beginFindString:(NSString *) string withOptions:(int) options; { NIMP; }
- (void) cancelFindString; { NIMP; }

- (PDFSelection *) findString:(NSString *) string
				fromSelection:(PDFSelection *) selection
				  withOptions:(int) options;
{
	NIMP;
	return nil;
}

- (NSArray *) findString:(NSString *) string withOptions:(int) options; { NIMP; return nil; }
- (NSAttributedString *) attributedString;
{ // this might take a while to read all content streams of all pages
	// go through all pages and glue attributedString together
	// set document attributes
	return nil;
}
- (NSString *) string; { return [[self attributedString] string]; }

	// page management

- (unsigned) indexForPage:(PDFPage *) page;
{ // find in page tree
	NSDictionary *p=[page _page];	// this is already dereferenced
	NSDictionary *parent;
	unsigned idx=0;
	while((parent=[p objectForKey:@"Parent"]))
		{
		NSEnumerator *e;
		id kid;
		parent=[parent self];	// dereference
		e=[[[parent objectForKey:@"Kids"] self] objectEnumerator];
		while((kid=[[e nextObject] self]))
			{ // get the cached catalog object
			if([kid isKindOfClass:[PDFPage class]])
				{ // cached wrapper
				if(kid == page)
					break;	// found!
				idx++;
				}
			else if(kid == p)	// check for both because we might be called before we are cached
				break;	// dereferenced object found!
			else if([[kid objectForKey:@"Type"] isEqualToString:@"Pages"])
				idx+=[[kid objectForKey:@"Count"] unsignedIntValue];	// count number of leaves that are skipped
			else
				idx++;	// just count leaf
			}
		if(kid == nil)
			return NSNotFound;	// error
		p=parent;	// go up one level
		}
	return idx;
}

- (void) exchangePageAtIndex:(unsigned) idx1 withPageAtIndex:(unsigned) idx2;
{
	NSDictionary *pages=[[_root objectForKey:@"Pages"] self];
	unsigned pg1;	// relative index in parent page tree node
	PDFPage *page1=[pages _objectAtIndexInPageTree:idx1 ofDocument:self parentIndex:&pg1];
	unsigned pg2;
	PDFPage *page2=[pages _objectAtIndexInPageTree:idx2 ofDocument:self parentIndex:&pg2];
#if 1
	NSLog(@"page1[%u]=%@", pg1, page1);
	NSLog(@"page2[%u]=%@", pg2, page2);
#endif
	if(page1 && page2)
		{
		NSDictionary *parent1=[[page1 _page] objectForKey:@"Parent"];
		NSDictionary *parent2=[[page2 _page] objectForKey:@"Parent"];
		// exchange records
		// exchange in labels (if they exist)
		[self _touch];
		}
	else
		NSLog(@"PDFDocument -exchangePageAtIndex: page %u or %u not found", idx1, idx2);
}

- (void) insertPage:(PDFPage *) page atIndex:(unsigned) idx;
{
	PDFDocument *pageDocument=[page document];
	unsigned pageIndex=[pageDocument indexForPage:page];	// location in other document
	PDFPage *insertBeforePage;
	NSDictionary *parent;
	[page retain];	// don't release
	if(pageIndex != NSNotFound)
		[pageDocument removePageAtIndex:pageIndex];
	if(idx == [self pageCount])
		{ // append
		}
	else
		{
		insertBeforePage=[self pageAtIndex:idx];		// page to insert before (if found)
		if(!insertBeforePage)
			return;	// index out of range
		parent=[[insertBeforePage _page] objectForKey:@"Parent"];
		}
	// insert into /Kids just before where we find otherPage
	// increment /Count for parent and all nodes above
	[page release];
	[self _touch];
}

- (void) removePageAtIndex:(unsigned) idx;
{
	NSDictionary *pages=[[_root objectForKey:@"Pages"] self];
	unsigned pg;	// relative index in parent page tree node
	PDFPage *page=[pages _objectAtIndexInPageTree:idx ofDocument:self parentIndex:&pg];
	if(page)
		{
		NSDictionary *parent=[[page _page] objectForKey:@"Parent"];
		// [[[parent objectForKey:@"Kids"] self] removeObjectAtIndex:pg];
		// decrement /Count for parent and all nodes above up to root
		// remove in label (if it exists)
		[self _touch];
		}
	else
		NSLog(@"PDFDocument -removePageAtIndex: page %u not found", idx);
}

- (PDFPage *) pageAtIndex:(unsigned) idx;
{ // return page accessor object
	return [[[_root objectForKey:@"Pages"] self] _objectAtIndexInPageTree:idx ofDocument:self parentIndex:NULL];
}

- (unsigned) pageCount;
{ // first page tree node knows total number of pages
	return [[[[_root objectForKey:@"Pages"] self] objectForKey:@"Count"] unsignedIntValue];
}

	// outline and selections

- (PDFOutline *) outlineItemForSelection:(PDFSelection *) selection; { NIMP; return nil; }
- (PDFOutline *) outlineRoot; { NIMP; return nil; }
- (PDFSelection *) selectionForEntireDocument; { NIMP; return nil; }
- (PDFSelection *) selectionFromPage:(PDFPage *) first
					atCharacterIndex:(unsigned) start
							  toPage:(PDFPage *) last
					atCharacterIndex:(unsigned) end;
{
	NIMP;
	return nil;
}
- (PDFSelection *) selectionFromPage:(PDFPage *) first
							 atPoint:(NSPoint)
						start toPage:(PDFPage *) last
							 atPoint:(NSPoint) end;
{ 
	NIMP;
	return nil;
}

	// handling password

- (BOOL) setPassword:(NSString *) passwd
{
	if(_isLocked)
		{
		if(![self unlockWithPassword:passwd])
			return NO;
		_isLocked=NO;
		}
	else
		{
		// check if password matches, then lock
		// or define a lock if there was none
		_isLocked=YES;
		}
	return YES;
}

- (BOOL) unlockWithPassword:(NSString *) password;
{
	if([self isEncrypted])
		{
		NSLog(@"document is encrypted!");
		// check password
		// if no match
		return NO;
		// send PDFDocumentDidUnlockNotification
		}
	return YES;
}

	// writing

- (BOOL) writeToFile:(NSString *) path; { return [self writeToFile:path
													   withOptions:nil]; }
- (BOOL) writeToFile:(NSString *) path withOptions:(NSDictionary *)
	opts; { return [self writeToURL:[NSURL fileURLWithPath:path]
											   withOptions:opts]; }
- (BOOL) writeToURL:(NSURL *) url; { return [self writeToURL:url
												 withOptions:nil]; }
- (BOOL) writeToURL:(NSURL *) url withOptions:(NSDictionary *) opts;
{
	NSData *data=[self _dataRepresentationWithOptions:opts];
	if(data)
		return [data writeToURL:url atomically:YES];
	return NO;
}

@end