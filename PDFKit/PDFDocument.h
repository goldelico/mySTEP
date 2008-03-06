//
//  PDFDocument.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDFPage;
@class PDFSelection;
@class PDFOutline;

extern NSString *PDFDocumentTitleAttribute;
extern NSString *PDFDocumentAuthorAttribute;
extern NSString *PDFDocumentSubjectAttribute;
extern NSString *PDFDocumentCreatorAttribute;
extern NSString *PDFDocumentProducerAttribute;
extern NSString *PDFDocumentCreationDateAttribute;
extern NSString *PDFDocumentModificationDateAttribute;
extern NSString *PDFDocumentKeywordsAttribute;

extern NSString *PDFDocumentDidBeginFindNotification;
extern NSString *PDFDocumentDidEndFindNotification;
extern NSString *PDFDocumentDidBeginPageFindNotification;
extern NSString *PDFDocumentDidEndPageFindNotification;
extern NSString *PDFDocumentDidFindMatchNotification;
extern NSString *PDFDocumentDidUnlockNotification;

#ifdef __mySTEP__
extern NSString *kCGPDFContextOwnerPassword;
extern NSString *kCGPDFContextUserPassword;
extern NSString *kCGPDFContextAllowsCopying;
extern NSString *kCGPDFContextAllowsPrinting;
#endif

@interface PDFDocument : NSObject
{
	NSURL *_url;						// if created from URL
	NSMutableData *_raw;				// raw document (retained)
	id _delegate;
	id _findTask;
	id _parser;							// parser
	// parsed data
	NSMutableDictionary *_catalog;		// object catalog indexed by (objnum, generation)
	NSMutableDictionary *_trailer;		// trailer catalog
	NSMutableDictionary *_root;			// root object catalog
	unsigned int major, minor;			// PDF version
	// document status
	BOOL _touched;						// has been modified (needs to generate new file as the dataRepresentation)
	BOOL _isLocked;
}

- (BOOL) allowsCopying;
- (BOOL) allowsPrinting;
- (void) beginFindString:(NSString *) string withOptions:(int) options;
- (void) cancelFindString;
- (NSData *) dataRepresentation;
- (id) delegate;
- (NSDictionary *) documentAttributes;
- (NSURL *) documentURL;
- (void) exchangePageAtIndex:(unsigned) index1 withPageAtIndex:(unsigned) index2;
- (PDFSelection *) findString:(NSString *) string
				fromSelection:(PDFSelection *) selection
				  withOptions:(int) options;
- (NSArray *) findString:(NSString *) string withOptions:(int) options;
- (unsigned) indexForPage:(PDFPage *) page;
- (id) initWithData:(NSData *) data;
- (id) initWithURL:(NSURL *) url;
- (void) insertPage:(PDFPage *) page atIndex:(unsigned) index;
- (BOOL) isEncrypted;
- (BOOL) isFinding;
- (BOOL) isLocked;
- (int) majorVersion;
- (int) minorVersion;
- (PDFOutline *) outlineItemForSelection:(PDFSelection *) selection;
- (PDFOutline *) outlineRoot;
- (PDFPage *) pageAtIndex:(unsigned) index;
- (unsigned) pageCount;
- (void) removePageAtIndex:(unsigned) index;
- (PDFSelection *) selectionForEntireDocument;
- (PDFSelection *) selectionFromPage:(PDFPage *) first
					atCharacterIndex:(unsigned) start
							  toPage:(PDFPage *) last
					atCharacterIndex:(unsigned) end;
- (PDFSelection *) selectionFromPage:(PDFPage *) first
							 atPoint:(NSPoint)
						start toPage:(PDFPage *) last
							 atPoint:(NSPoint) end;
- (void) setDelegate:(id) delegate;
- (void) setDocumentAttributes:(NSDictionary *) dict;
- (BOOL) setPassword:(NSString *) password;
- (NSString *) string;
- (BOOL) unlockWithPassword:(NSString *) password;
- (BOOL) writeToFile:(NSString *) path;
- (BOOL) writeToFile:(NSString *) path withOptions:(NSDictionary *) opts;
- (BOOL) writeToURL:(NSURL *) url;
- (BOOL) writeToURL:(NSURL *) url withOptions:(NSDictionary *) opts;

@end

@interface PDFDocument (PrivateExtension)
- (NSAttributedString *) attributedString; // enables to convert PDF to RTF - this might take a while to read all content streams of all pages
@end

@interface NSObject (PDFDocumentDelegate)

- (void) didMatchString:(PDFSelection *) selection;

// delegate becomes registered for these notifications - if supported

- (void) documentDidBeginDocumentFind:(NSNotification *) n;
- (void) documentDidBeginPageFind:(NSNotification *) n;
- (void) documentDidEndDocumentFind:(NSNotification *) n;
- (void) documentDidEndPageFind:(NSNotification *) n;
- (void) documentDidFindMatch:(NSNotification *) n;
- (void) documentDidUnlock:(NSNotification *) n;

@end
