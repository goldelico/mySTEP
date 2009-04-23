//
//  PDFKitPrivate.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <PDFKit/PDFKit.h>

/*#import "PDFDestination.h"
#import "PDFDocument.h"
#import "PDFOutline.h"
#import <PDFKit/PDFView.h>
*/

#undef NIMP
#define NIMP (NSLog(@"%@ not implemented for %@", NSStringFromSelector(_cmd), self))

// private headers

@interface NSObject (PDFKit) 
- (BOOL) isPDFAtom; 
- (BOOL) isPDFIndirect; 
- (BOOL) isPDFKeyword;
- (BOOL) isPDFKeyword:(NSString *) keyword; 
// - (id) self;        // fetch real object if it is an indirect object 
- (NSData *) _PDFDataRepresentation;	// encode as PDF object
@end

@interface NSDictionary (PDFKit)
- (id) _objectAtIndexInNameTree:(NSString *) str;
- (id) _objectAtIndexInNumberTree:(int) num;
- (id) _objectAtIndexInPageTree:(unsigned) num ofDocument:(PDFDocument *) doc parentIndex:(unsigned *) idx;
- (unsigned) _treeCount;	// count number of entries in page/number/name tree
@end

@interface PDFAtom : NSObject
{
	NSString *_string;
}
- (id) initWithString:(NSString *) str;
- (NSString *) value;
- (BOOL) isEqualToString:(NSString *) str;
@end

@interface PDFKeyword : PDFAtom
@end

@interface PDFCrossReference : NSObject 
{ // represents a single entry in the xref section
	NSData *_data;			// where the data source is (may refer to an object stream)
	unsigned _position;		// or object number for list of free objects
	unsigned short _generation;
	id _object;				// cached object
	BOOL _isFree;
} 
- (id) initWithData:(NSData *) data pos:(unsigned) pos number:(unsigned) num generation:(unsigned) gen isFree:(BOOL) flag;
- (NSData *) data;				// source data
- (unsigned) position;			// position in data
- (id) object;					// cached object (or nil)
- (void) setObject:(id) obj;	// cache object
@end

@interface PDFReference : NSObject 
{ // represents "%u %u R"
	PDFDocument *data;   // not retained! 
	unsigned ref1; 
	unsigned ref2;
	PDFCrossReference *ref;	// link after we have dereferenced for the first time
} 
+ (id) keyForNumber:(unsigned) r1 andGeneration:(unsigned) r2;
- (id) initWithNumber:(unsigned) r1 andGeneration:(unsigned) r2 forDocument:(PDFDocument *) doc;  // create reference 
- (void) setObject:(id) obj;	// change object we reference
@end

@interface PDFStream : NSObject
{ // represents "stream"
	PDFStream *_previous;	// for a filter chain
	NSDictionary *_dict;	// description
	PDFDocument *_doc;		// not retained!
	NSData *_source;		// source data
	NSData *_result;		// decoded data
	unsigned _start;		// start of stream position
	unsigned _len;
}
- (id) initWithPrevious:(PDFStream *) prev dictionary:(NSDictionary *) dict parameters:(NSDictionary *) params;
- (id) initWithDoc:(PDFDocument *) doc raw:(NSData *) raw dictionary:(NSDictionary *) dict atPos:(unsigned) pos;
- (id) objectForKey:(NSString *) key;
- (unsigned) length;
- (unsigned) decodedLength;				// a hint only (0 if not available)
- (NSData *) decode;					// decode/fetch stream
- (NSData *) data;						// cached decoded/fetched stream contents
@end

@interface PDFDocument (Private)
- (void) _touch;
- (NSMutableDictionary *) _root;
- (NSMutableDictionary *) _trailer;
- (BOOL) _parsePDF;
// get indirect objects catalog
- (NSMutableDictionary *) _catalog;
- (PDFCrossReference *) _catalogEntryForObject:(unsigned) key generation:(unsigned) generation;	// dereference indirect object 
@end

@interface PDFParser : NSObject
{
	PDFDocument *_doc;					// may be needed to reference PDF version or trailer (Encrypt)
	NSData *_source;					// data source
	const unsigned char *_bytes;		// raw bytes pointer
	unsigned _pos;						// current scanning position
	unsigned _end;						// end of data
	unsigned _xrefpos;					// location of the last "xref" keyword in the file
}

+ (PDFParser *) parserWithData:(NSData *) src;
- (id) initWithData:(NSData *) src;
- (void) setParseLocation:(unsigned) pos;
- (unsigned) parseLocation;	// current location
- (id) _parseObject;
- (id) _parseXrefAndTrailer;
- (BOOL) _parseXrefSection;
- (void) _setPDFDocument:(PDFDocument *) doc;

@end

@interface PDFPage (Private)
- (NSMutableDictionary *) _page;	// the page object
- (void) _touch;
- (id) _initWithDocument:(PDFDocument *) document andPageDictionary:(NSMutableDictionary *) page;
- (id) _inheritedPageAttribute:(NSString *) str;
- (NSArray *) _content;	// the content stream(s) - not yet dereferenced
@end
