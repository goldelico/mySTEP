/* 
   NSPrinter.m

   NSPrinter, NSPrintInfo, NSPrintPanel, NSPageLayout, NSPrintOperation

   Printing classes.

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Authors:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: June 1997 - January 1998
   
   Author:	H. N. Schaller <hns@computer.org>
   Date: Jan 2006		_NSPDFGraphicsContext added

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import <AppKit/NSNibLoading.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSPrinter.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPrintPanel.h>
#import <AppKit/NSPageLayout.h>
#import <AppKit/NSPrintOperation.h>
#import <AppKit/NSProgressIndicator.h>
#import <AppKit/NSTextField.h>

#import "NSBackendPrivate.h"
#import "NSAppKitPrivate.h"


//*****************************************************************************
//
// 		NSPrinter 
//
//*****************************************************************************

@implementation NSPrinter

+ (NSPrinter *) printerWithName:(NSString *) name 
												 domain:(NSString *) domain 
						 includeUnavailable:(BOOL) flag;
{
	return [[[self alloc] _initWithName:name host:@"localhost" type:@"PDF" note:@""] autorelease];
}

+ (NSPrinter *) printerWithName:(NSString *)name
{
	return [[[self alloc] _initWithName:name host:@"localhost" type:@"PDF" note:@""] autorelease];
}

+ (NSPrinter *) printerWithType:(NSString *)type
{
	return [[[self alloc] _initWithName:@"default" host:@"localhost" type:type note:@""] autorelease];
}

+ (NSArray *) printerNames
{
	// read from AppKit-Info.plist?
	return [NSArray arrayWithObject:@"default"];
}

+ (NSArray *) printerTypes
{
	return [NSArray arrayWithObject:@"PDF"];
}

- (id) _initWithName:(NSString *) name host:(NSString *) host type:(NSString *) type note:(NSString *) note;
{
	if((self=[super init]))
		{
		printerHost=[host retain];
		printerName=[name retain];
		printerNote=[note retain];
		printerType=[type retain];
		}
	return self;
}

- (void) dealloc
{
	[printerHost release];
	[printerName release];
	[printerNote release];
	[printerType release];
	[printerDomain release];
	[super dealloc];
}

//
// Printer Attributes 
//

- (NSString *) host						{ return printerHost; }
- (NSString *) name						{ return printerName; }
- (NSString *) note						{ return printerNote; }
- (NSString *) type						{ return printerType; }
- (NSString *) domain;				{ return printerDomain; }

- (BOOL) acceptsBinary
{
	return NO;    
}

- (NSRect) imageRectForPaper:(NSString *)paperName
{
	return NSMakeRect(0,0,0,0);    
}

- (NSSize) pageSizeForPaper:(NSString *)paperName
{
	return NSMakeSize(0,0);    
}

- (BOOL) isColor
{
	return YES;    
}

- (BOOL) isFontAvailable:(NSString *)fontName
{
	return NO;    
}

- (NSInteger) languageLevel
{
	return 0;
}

- (BOOL) isOutputStackInReverseOrder
{
	return NO;    
}

- (BOOL) booleanForKey:(NSString *)key inTable:(NSString *)table
{
	return NO;    
}

- (NSDictionary *) deviceDescription
{
//	NSSize resolution, size;	// infinite for a PDF printer
	static NSDictionary *_device;
	if(!_device)
		{
		_device=[[NSMutableDictionary alloc] initWithObjectsAndKeys:
			@"DeviceRGBColorSpace", NSDeviceColorSpaceName,
			@"YES", NSDeviceIsPrinter,
			@"NO", NSDeviceIsScreen,
//			[NSValue valueWithSize:resolution], NSDeviceResolution,
//			[NSValue valueWithSize:size], NSDeviceSize,
			nil];
		}
	return _device;
}

- (float) floatForKey:(NSString *)key inTable:(NSString *)table
{
	return 0;  
}

- (int) intForKey:(NSString *)key inTable:(NSString *)table;
{
	return 0;   
}

- (NSRect) rectForKey:(NSString *)key inTable:(NSString *)table
{
	return NSMakeRect(0,0,0,0);    
}

- (NSSize) sizeForKey:(NSString *)key inTable:(NSString *)table
{
	return NSMakeSize(0,0);    
}

- (NSString *) stringForKey:(NSString *)key inTable:(NSString *)table
{
	return nil;
}

- (NSArray *) stringListForKey:(NSString *)key inTable:(NSString *)table
{
	return nil;
}

- (NSPrinterTableStatus) statusForTable:(NSString *)table
{
	return NSPrinterTableError;
}

- (BOOL) isKey:(NSString *)key inTable:(NSString *)table
{
	return NO;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder:(NSCoder *) aCoder
{
	//  [super encodeWithCoder:aCoder];
	
	[aCoder encodeObject:printerHost];
	[aCoder encodeObject:printerName];
	[aCoder encodeObject:printerNote];
	[aCoder encodeObject:printerType];
	
	[aCoder encodeValueOfObjCType:"i" at:&cacheAcceptsBinary];
	[aCoder encodeValueOfObjCType:"i" at:&cacheOutputOrder];
	[aCoder encodeValueOfObjCType:@encode(BOOL) at:&isRealPrinter];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	if([aDecoder allowsKeyedCoding])
		return self;
	
	printerHost = [[aDecoder decodeObject] retain];
	printerName = [[aDecoder decodeObject] retain];
	printerNote = [[aDecoder decodeObject] retain];
	printerType = [[aDecoder decodeObject] retain];
	
	[aDecoder decodeValueOfObjCType:"i" at:&cacheAcceptsBinary];
	[aDecoder decodeValueOfObjCType:"i" at:&cacheOutputOrder];
	[aDecoder decodeValueOfObjCType:@encode(BOOL) at:&isRealPrinter];
	
	return self;
}

@end /* NSPrinter */

//*****************************************************************************
//
// 		NSPrintInfo 
//
//*****************************************************************************

// Class variables

static NSPrintInfo *sharedPrintInfoObject = nil;

@implementation NSPrintInfo

+ (void) setSharedPrintInfo:(NSPrintInfo *)printInfo
{
	NSAssert(printInfo, @"nil printInfo");
	ASSIGN(sharedPrintInfoObject, printInfo);
}

+ (NSPrintInfo *)sharedPrintInfo
{
	if(!sharedPrintInfoObject)
		{
		NSDictionary *info=[[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"NSPrintInfoDefault"];
		sharedPrintInfoObject=[[self alloc] initWithDictionary:info];	// create a default object
		}
	return sharedPrintInfoObject;
}

//
// Managing the Printing Rectangle 
//

+ (NSSize)sizeForPaperName:(NSString *)name
{
	return [[self defaultPrinter] pageSizeForPaper:name];
}

+ (NSPrinter *)defaultPrinter
{
	return nil;
}

+ (void)setDefaultPrinter:(NSPrinter *)printer
{
}

- (id) initWithDictionary:(NSDictionary *)aDict
{
	if((self=[super init]))
		{
			info=[aDict mutableCopy];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) z
{
	return [[[self class] alloc] initWithDictionary:info];	// return a (mutable) copy
}

- (void) dealloc;
{
	[info release];
	[super dealloc];
}

//
// Managing the Printing Rectangle 
//
- (CGFloat) bottomMargin
{
	NSNumber *val=[info objectForKey:NSPrintLeftMargin];
	return val?[val floatValue]:0.0;
}

- (CGFloat) leftMargin
{
 	NSNumber *val=[info objectForKey:NSPrintLeftMargin];
	return val?[val floatValue]:0.0;
}

- (NSPrintingOrientation) orientation
{
 	return [[info objectForKey:NSPrintOrientation] intValue];
}

- (NSString *) paperName
{
	return [info objectForKey:NSPrintPaperName];
}

- (NSSize) paperSize
{
 	NSNumber *val=[info objectForKey:NSPrintPaperSize];
	return val?[val sizeValue]:NSZeroSize;
}

- (CGFloat) rightMargin
{
 	NSNumber *val=[info objectForKey:NSPrintRightMargin];
	return val?[val floatValue]:0.0;
}

- (void) setBottomMargin:(CGFloat)value
{
	[info setObject:[NSNumber numberWithFloat:value] forKey:NSPrintLeftMargin];
}

- (void) setLeftMargin:(CGFloat)value
{
	[info setObject:[NSNumber numberWithFloat:value] forKey:NSPrintLeftMargin];
}

- (void) setOrientation:(NSPrintingOrientation)mode
{
	[info setObject:[NSNumber numberWithInt:mode] forKey:NSPrintOrientation];
}

- (void) setPaperName:(NSString *)name
{
	[info setObject:name forKey:NSPrintPaperName];
}

- (void) setPaperSize:(NSSize)size
{
	[info setObject:[NSValue valueWithSize:size] forKey:NSPrintPaperSize];
}

- (void) setRightMargin:(CGFloat)value
{
	[info setObject:[NSNumber numberWithFloat:value] forKey:NSPrintRightMargin];
}

- (void) setTopMargin:(CGFloat)value
{
	[info setObject:[NSNumber numberWithFloat:value] forKey:NSPrintTopMargin];
}

- (CGFloat) topMargin
{
  return [(NSNumber *)[info objectForKey:NSPrintTopMargin] floatValue];
}

//
// Pagination 
//
- (NSPrintingPaginationMode) horizontalPagination
{
  return [(NSNumber *)[info objectForKey:NSPrintHorizontalPagination] intValue];
}

- (void) setHorizontalPagination:(NSPrintingPaginationMode)mode
{
	[info setObject:[NSNumber numberWithInt:mode] forKey:NSPrintHorizontalPagination];
}

- (void) setVerticalPagination:(NSPrintingPaginationMode)mode
{
	[info setObject:[NSNumber numberWithInt:mode] forKey:NSPrintVerticalPagination];
}

- (NSPrintingPaginationMode) verticalPagination
{
  return [(NSNumber *)[info objectForKey:NSPrintVerticalPagination] intValue];
}

//
// Positioning the Image on the Page 
//
- (BOOL) isHorizontallyCentered
{
  return [(NSNumber *)[info objectForKey:NSPrintHorizontallyCentered] boolValue];
}

- (BOOL) isVerticallyCentered
{
  return [(NSNumber *)[info objectForKey:NSPrintVerticallyCentered] boolValue];
}

- (void) setHorizontallyCentered:(BOOL)flag
{
	[info setObject:[NSNumber numberWithBool:flag] forKey:NSPrintHorizontallyCentered];
}

- (void) setVerticallyCentered:(BOOL)flag
{
	[info setObject:[NSNumber numberWithBool:flag] forKey:NSPrintVerticallyCentered];
}

//
// Specifying the Printer 
//
- (NSPrinter *) printer
{
  return [info objectForKey:NSPrintPrinter];
}

- (void)setPrinter:(NSPrinter *) aPrinter
{
  [info setObject:aPrinter forKey:NSPrintPrinter];
}

//
// Controlling Printing
//

- (NSString *) jobDisposition
{
  return [info objectForKey:NSPrintJobDisposition];
}

- (void) setJobDisposition:(NSString *)disposition
{
  [info setObject:disposition forKey:NSPrintJobDisposition];
}

- (void) setUpPrintOperationDefaultValues
{
	return;
}

- (NSMutableDictionary *) dictionary			{ return info; }

- (id) initWithCoder:(NSCoder *) aDecoder								// NSCoding protocol
{
	if([aDecoder allowsKeyedCoding])
		{
		return self;
		}
	info = [[aDecoder decodePropertyList] retain];
	return self;
}

- (void) encodeWithCoder:(NSCoder *) aCoder
{
	[aCoder encodePropertyList:info];
}

@end /* NSPrintInfo */

//*****************************************************************************
//
// 		NSPrintPanel 
//
//*****************************************************************************

@implementation NSPrintPanel

+ (NSPrintPanel *) printPanel;	{ return [[[self alloc] init] autorelease]; }

- (NSView *)accessoryView					{ return _accessoryView; }
- (NSString *)jobStyleHint					{ return _jobStyleHint; }

- (void)setAccessoryView:(NSView *)aView	{ ASSIGN(_accessoryView, aView); }
- (void)setJobStyleHint:(NSString *)hint	{ ASSIGN(_jobStyleHint, hint); }

- (id) init;
{
	if((self=[super init]))
		{
		}
	return self;
}

- (void) dealloc;
{
	[_accessoryView release];
	[_jobStyleHint release];
	[super dealloc];
}

- (void) _printPanelDidEnd:(NSPrintPanel *) panel returnCode:(int) code contextInfo:(void *) context;
{
	_returnValue=code;
}

- (NSInteger) runModal;
{
	return [self runModalWithPrintInfo:[[NSPrintOperation currentOperation] printInfo]];
}

- (NSInteger) runModalWithPrintInfo:(NSPrintInfo *) info; 
{
	[self beginSheetWithPrintInfo:info
				   modalForWindow:nil
						 delegate:self
			 didEndSelector:@selector(_printPanelDidEnd:returnCode:contextInfo:)
					  contextInfo:NULL];	// runs modal
	[self finalWritePrintInfo];
	return _returnValue;
}

- (void) beginSheetWithPrintInfo:(NSPrintInfo *) info modalForWindow:(NSWindow *) window delegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
{
	NSInteger r;
	NSPanel *panel;
	[self updateFromPrintInfo];
	
	panel=NIMP;		// create a sheet or popup window
	
	if(window)
			{
				; // create a sheet
				[NSApp beginSheet:panel modalForWindow:window modalDelegate:delegate didEndSelector:sel contextInfo:context];
				// run modal loop
			}
	else
			{
				void (*didend)(id, SEL, NSPrintPanel *, NSInteger, void *);
				; // create a popup
				r=[NSApp runModalForWindow:panel];
				didend = (void (*)(id, SEL, NSPrintPanel *, NSInteger, void *))[delegate methodForSelector:sel];
				(*didend)(self, sel, self, r, context); 
			}
}

- (void)pickedButton:(id)sender
{
}

- (void)pickedAllPages:(id)sender
{
}

- (void)pickedLayoutList:(id)sender
{
}

- (void)updateFromPrintInfo	
{
}

- (void)finalWritePrintInfo	
{
}

@end /* NSPrintPanel */

//*****************************************************************************
//
// 		NSPageLayout
//
//*****************************************************************************

@implementation NSPageLayout		// PageLayout panel queries the user for
									// paper type and orientation info
+ (NSPageLayout *) pageLayout				{ return nil; }
- (NSInteger) runModal							{ return 0; }

- (NSInteger) runModalWithPrintInfo:(NSPrintInfo *)pInfo
{
	return 0;
}

//
// Customizing the Panel 
//
- (NSView *)accessoryView					{ return nil; }
- (void)setAccessoryView:(NSView *)aView	{}

//
// Updating the Panel's Display 
//
- (void)convertOldFactor:(CGFloat *)old
			   newFactor:(CGFloat *)new		{}
- (void)pickedButton:(id)sender				{}
- (void)pickedOrientation:(id)sender		{}
- (void)pickedPaperSize:(id)sender			{}
- (void)pickedUnits:(id)sender				{}

//
// Communicating with the NSPrintInfo Object 
//
- (NSPrintInfo *)printInfo					{ return nil; }
- (void)readPrintInfo						{}
- (void)writePrintInfo						{}

- (id) initWithCoder:(NSCoder *) aDecoder								// NSCoding protocol
{
	if([aDecoder allowsKeyedCoding])
		return self;
	return self;
}

- (void)encodeWithCoder:(NSCoder *) aCoder				{ return; }

@end /* NSPageLayout */


/*
 * _NSPDFGraphicsContext - by H. N. Schaller <hns@computer.org>
*/

@interface _NSPDFReference : NSObject
{
	id _object;
	NSUInteger _index;
	NSUInteger _position;
}
+ (_NSPDFReference *) referenceWithObject:(id) object;
@end

@implementation _NSPDFReference
+ (_NSPDFReference *) referenceWithObject:(id) object;
{
	_NSPDFReference *r=[[self new] autorelease];
	if(r)
		r->_object=object;
	return r;
}
@end

@interface _NSPDFGraphicsContext : NSGraphicsContext
{
@public
	NSOutputStream *_pdf;	// stream to write to
	NSMutableArray *_objects;	// objects (incl. streams)
	NSMutableArray *_references;	// objects (incl. streams)
	NSMutableArray *_fonts;		// fonts
	NSMutableArray *_xobjects;	// images
	NSMutableDictionary *_parent;	// page tree entry
	NSMutableArray *_pages;			// page catalogs
	NSMutableDictionary *_catalog;	// catalog entry
	NSAffineTransform *_ctm;
	NSBezierPath *_currentPath;	// to compare attributes
	NSColor *_currentFillColor;	// ??? do we need to save that ???
	NSColor *_currentStrokeColor;
}

@end

@interface NSObject (_NSPDFGraphicsContext)
- (void) appendToStream:(NSOutputStream *) stream;
@end

@interface NSOutputStream (_NSPDFGraphicsContext)
- (void) appendString:(NSString *) string;
- (void) appendFormat:(NSString *) format, ...;
@end

@implementation _NSPDFReference (_NSPDFGraphicsContext)

- (void) appendToStream:(NSOutputStream *) stream;
{
	_NSPDFGraphicsContext *ctx=(_NSPDFGraphicsContext *) [NSGraphicsContext currentContext];
	if(_position == 0)
		{ // not yet encoded
		_index=[ctx->_objects count];
		[ctx->_objects addObject:self];
		_position=0;	// FIXME: current writing position
		// output 'obj %u'
	//	[object _PDFstringRepresenation];	// where to write?
		}
	[stream appendFormat:@" R %u %u", _index, _position];
}

@end

@implementation NSArray (_NSPDFGraphicsContext)
- (void) appendToStream:(NSOutputStream *) stream;
{
	NSEnumerator *e=[self objectEnumerator];
	id o;
	[stream appendString:@" [ "];
	while((o=[e nextObject]))
		[o appendToStream:stream];
	[stream appendString:@" ]"];
}
@end

@implementation NSDictionary (_NSPDFGraphicsContext)
- (void) appendToStream:(NSOutputStream *) stream;
{
	NSEnumerator *e=[self keyEnumerator];
	id key;
	[stream appendString:@" << "];
	while((key=[e nextObject]))
		{
		[key appendToStream:stream];
		[[self objectForKey:key] appendToStream:stream];
		}
	[stream appendString:@" >> "];
}
@end

@implementation NSOutputStream (_NSPDFGraphicsContext)

// should be able to handle additional attributes

- (void) appendToStream:(NSOutputStream *) stream;
{
	NSData *data=[self propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
	NSDictionary *a=[NSDictionary dictionaryWithObjectsAndKeys:
						@"Stream", @"Type",
						[NSNumber numberWithInteger:[data length]], @"Length",
						nil];
	[a appendToStream:stream];	// append dictionary
	[stream appendFormat:@"stream\n"];
	// handle encoding/compression etc.
	// append data
	[stream appendFormat:@"endstream\n"];
}

- (void) appendString:(NSString *) string;
{
	const char *cstr=[string UTF8String];
	[self write:(unsigned char *)cstr maxLength:strlen(cstr)];
#if 1
	NSLog(@"PDF: %@", string);
#endif
}

- (void) appendFormat:(NSString *) format, ...;
{
	va_list ap;
	NSString *str;
	va_start(ap, format);
	str=[[NSString alloc] initWithFormat:format arguments:ap];
	[self appendString:str];
	[str release];
	va_end(ap);
}

@end

@implementation NSString (_NSPDFGraphicsContext)
- (void) appendToStream:(NSOutputStream *) stream;
{
	[stream appendFormat:@" /%@", self];
}
@end

@implementation NSNumber (_NSPDFGraphicsContext)
- (void) appendToStream:(NSOutputStream *) stream;
{
	[stream appendFormat:@" %@", [self description]];
}
@end

@implementation _NSPDFGraphicsContext

// NSGraphicsContext

- (BOOL) isDrawingToScreen; { return NO; }

- (NSDictionary *) attributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		NSGraphicsContextPDFFormat, NSGraphicsContextRepresentationFormatAttributeName,
		nil];
}

// shouldn't that be initWithAttributes?

- (id) initWithAtributes:(NSDictionary *) attribs;
{
	if((self=[super init]))
		{
		_pdf=[[attribs objectForKey:@"PDFOutputStream"] retain];
		[_pdf open];
		[_pdf appendString:@"%%PDF-1.3\n"];
		_objects=[[NSMutableArray arrayWithCapacity:20] retain];
		_references=[[NSMutableArray arrayWithCapacity:20] retain];
		_fonts=[[NSMutableArray arrayWithCapacity:20] retain];
		_xobjects=[[NSMutableArray arrayWithCapacity:20] retain];
		_pages=[[NSMutableArray arrayWithCapacity:20] retain];
		_parent=[[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Pages", @"Type",
			// -, @"Parent",	// we are the root tree node
			_pages, @"Kids",
			[NSNumber numberWithInt:0], @"Count",
			nil] retain];
		_catalog=[[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Catalog", @"Type",
			_parent, @"Pages",
			nil] retain];
		}
	return self;
}

- (void) dealloc;
{
	// can we save some steps if we are the last owner of _pfd?
	NSUInteger pos=[[_pdf propertyForKey:NSStreamFileCurrentOffsetKey] unsignedIntValue];
	[_pdf appendString:@"\nxref\n"];
	// write _references table
	[_pdf appendString:@"\ntrailer\n"];
	[[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInteger:[_references count]], @"Size",
		// optional, @"Prev",
		_catalog, @"Root",
		// optional, @"Encrypt",
		// optional, @"Info",
		// optional, @"ID",
		nil] appendToStream:_pdf];	// write trailer dictionary
	[_pdf appendFormat:@"\nstartxref\n%u\n%%EOF\n", pos];
	[_pdf close];
	[_pdf release];	// must have been retained somewhere else to persist beyond this operation!
	[_objects release];
	[_references release];
	[_fonts release];
	[_xobjects release];
	[_ctm release];
	[_pages release];
	[_catalog release];
	[super dealloc];
}

- (void) saveGraphicsState;
{
	[_pdf appendString:@" q"];
}

- (void) restoreGraphicsState;
{
	[_pdf appendString:@" Q"];
}

- (void) flushGraphics; { return; }

// NSColor

- (void) _setFillColor:(NSColor *) clr;
{
	ASSIGN(_currentFillColor, clr);	// we might need that if we change only one component????
	[_pdf appendString:@" ***set fill color'''"];
}

- (void) _setStrokeColor:(NSColor *) clr;
{
	ASSIGN(_currentStrokeColor, clr);
	[_pdf appendString:@" ***set stroke color***"];
}

- (void) _setColor:(NSColor *) clr;
{ // set both
	[self _setFillColor:clr];
	[self _setStrokeColor:clr];
}

- (void) _setCursor:(NSCursor *) cursor; { return; }	// ignore

// NSBezierPath

- (void) _bezierPath:(NSBezierPath *) path;
{
	NSPoint points[3];
	NSPoint current={ -999.4, -3.141592 };	// highly improbable - and 'good' code will start with a move element
	NSUInteger i, count=[path elementCount];
	for(i=0; i<count; i++)
		{
		switch([path elementAtIndex:i associatedPoints:points])
			{
			case NSMoveToBezierPathElement:
				[_pdf appendFormat:@" %f %f m", points[0].x, points[0].y];
				current=points[0];
				break;
			case NSLineToBezierPathElement:
				[_pdf appendFormat:@" %f %f l", points[0].x, points[0].y];
				current=points[0];
				break;
			case NSCurveToBezierPathElement:
				if(NSEqualPoints(points[0], current))
					[_pdf appendFormat:@" %f %f %f %f v", points[1].x, points[1].y, points[2].x, points[2].y];
				else if(NSEqualPoints(points[1], points[2]))
					[_pdf appendFormat:@" %f %f %f %f y", points[0].x, points[0].y, points[2].x, points[2].y];
				else   
					[_pdf appendFormat:@" %f %f %f %f %f %f c", points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y];
				current=points[2];
				break;
			case NSClosePathBezierPathElement:
				[_pdf appendFormat:@" h"];
				current=NSMakePoint(-999.4, -3.141592);	// restore something "random"
				break;
			}
		}
}

- (void) _stroke:(NSBezierPath *) path;
{
	[self _bezierPath:path];
	[_pdf appendString:@" S"];
}

- (void) _fill:(NSBezierPath *) path;
{
	[self _bezierPath:path];
	[_pdf appendString:[path windingRule]==NSNonZeroWindingRule?@" f":@" f*"];
}

- (void) _addClip:(NSBezierPath *) path reset:(BOOL) flag;
{
	// PDF can't do that!
	// we should allow this to be called only once per saveGraphicsState
	[self _bezierPath:path];
	[_pdf appendString:[path windingRule]==NSNonZeroWindingRule?@" W n":@" W* n"];
}

// NSAffineTransform

- (void) _setCTM:(NSAffineTransform *) at;
{
	NSAffineTransformStruct ts;
	ASSIGN(_ctm, at);
	ts=[_ctm transformStruct];
	[_pdf appendFormat:@" %f %f %f %f %f %f cm", ts.m11, ts.m12, ts.m21, ts.m22, ts.tX, ts.tY];
}

- (void) _concatCTM:(NSAffineTransform *) atm;
{
	NSAffineTransformStruct ts;
	[_ctm appendTransform:atm];
	ts=[_ctm transformStruct];
	[_pdf appendFormat:@" %f %f %f %f %f %f cm", ts.m11, ts.m12, ts.m21, ts.m22, ts.tX, ts.tY];
}

- (void) _setFraction:(CGFloat) fraction;
{ // compositing fraction
	return;	// we can't do that in PDF
}

- (BOOL) _draw:(NSImageRep *) rep;
{ // draw using current CTM, current compositingOp & fraction etc.
	NSUInteger idx=[_xobjects indexOfObject:rep];
	if(idx == NSNotFound)
		{
		idx=[_xobjects count];
		[_xobjects addObject:rep];
		// store image in a separate stream as [(NSBitmapImageRep *) rep TIFFRepresentation]; using some good compression
		}
	[_pdf appendFormat:@" /Im%u Do", idx];	// select bitmap to draw
	return YES;
}

- (void) _copyBits:(void *) srcGstate fromRect:(NSRect) srcRect toPoint:(NSPoint) destPoint;
{
	NIMP;	// not available in printing context
}

// NSFont

- (void) _setFont:(NSFont *) font;
{
	NSUInteger idx=[_fonts indexOfObject:font];
	if(idx == NSNotFound)
		{ // not yet found
		idx=[_fonts count];
		[_fonts addObject:font];
		// close current content stream
		// store font
		// open a new content stream
		}
	[_pdf appendFormat:@" /F%u Tf %f TL", idx, [font leading]];	// select text font and set leading
}

- (void) _beginText;
{
	[_pdf appendFormat:@" BT"];
}

- (void) _setTextPosition:(NSPoint) pos;
{
	[_pdf appendFormat:@" %f %f Td", pos.x, pos.y];
}

- (void) _newLine;
{
	// how to set TL?
	[_pdf appendFormat:@" T*"];
}

- (void) _drawGlyphs:(NSGlyph *)glyphs count:(NSUInteger)cnt;	// (string) Tj
{
	[_pdf appendString:@" ("];
	// convert glyphs to bytes according to encoding of this font (incl. multibyte)
	// prefix ( and ) and \ by \ (strsubst)
	// reault may have all byte codes 0x00 .. 0xff
	// i.e. the _pdf object should be an NSMutableData and not an NSString?
	// or we append character fragments
//	[_pdf appendFormat:@"%C", glyphs];
	// [_pdf write:(unsigned char *)cstr maxLength:strlen(cstr)];
	[_pdf appendString:@") Tj"];
}

- (void) _setBaseline:(CGFloat) shift
{
	[_pdf appendFormat:@" %f Ts", shift];
}

- (void) _endText;
{
	[_pdf appendFormat:@" ET"];
}

- (void) _beginPage:(NSString *) title;
{
	NSMutableDictionary *page=[NSMutableDictionary dictionaryWithObjectsAndKeys:
		@"Page", @"Type",
		_parent, @"Parent",
		// define boxes here
		_pdf, @"Contexts",	// content stream for this page
		nil];
	[_pages addObject:page];	// add node to page tree
	[_parent setObject:[NSNumber numberWithUnsignedInteger:[_pages count]] forKey:@"Count"];	// update page tree node
}

- (void) _endPage;
{
	// end page stream and link with page
}

@end

//*****************************************************************************
//
// 		NSPrintOperation
//
//*****************************************************************************

@implementation NSPrintOperation

+ (NSPrintOperation *)printOperationWithView:(NSView *)aView
{
	return [self printOperationWithView:aView printInfo:[NSPrintInfo sharedPrintInfo]];
}

+ (NSPrintOperation *)printOperationWithView:(NSView *)aView
								   printInfo:(NSPrintInfo *)aPrintInfo
{
	NSPrintOperation *po=[[[self alloc] _initWithView:aView insideRect:[aView bounds] toData:nil toPath:nil printInfo:aPrintInfo] autorelease];
	[po setShowsPrintPanel:YES];
	[po setShowsProgressPanel:YES];
	return po;
}

+ (NSPrintOperation *) PDFOperationWithView:(NSView *)aView
								 insideRect:(NSRect)rect
									 toData:(NSMutableData *)data;
{
	return [self PDFOperationWithView:aView insideRect:rect toData:data printInfo:[NSPrintInfo sharedPrintInfo]];
}

+ (NSPrintOperation *) PDFOperationWithView:(NSView *)aView
								 insideRect:(NSRect)rect
									 toData:(NSMutableData *)data
								  printInfo:(NSPrintInfo *)aPrintInfo;
{
	return [[[self alloc] _initWithView:aView insideRect:rect toData:data toPath:nil printInfo:aPrintInfo] autorelease];
}

+ (NSPrintOperation *) PDFOperationWithView:(NSView *)aView
								 insideRect:(NSRect)rect
									 toPath:(NSString *)path
								  printInfo:(NSPrintInfo *)aPrintInfo;
{
	return [[[self alloc] _initWithView:aView insideRect:rect toData:nil toPath:path printInfo:aPrintInfo] autorelease];
}

// CHECKME: shouldn't we have one current operation per thread?

static NSPrintOperation *_currentOperation;

+ (NSPrintOperation *) currentOperation						{ return _currentOperation; }
+ (void)setCurrentOperation:(NSPrintOperation *) operation	{ ASSIGN(_currentOperation, operation); }

- (id) _initWithView:(NSView *)aView
		  insideRect:(NSRect)rect
			  toData:(NSMutableData *)data
			  toPath:(NSString *)path
		   printInfo:(NSPrintInfo *)aPrintInfo
{
	if((self=[super init]))
		{
		_printInfo=[aPrintInfo copy];	// make a copy
		_view=[aView retain];
		_insideRect=rect;
		_data=[data retain];
		_path=[path retain];
		_printPanel=[NSPrintPanel new];
		}
	return self;
}

- (void) dealloc;
{
	[self destroyContext];
	[_path release];
	[_data release];
	[_accessoryView release];
	[_printInfo release];
	[_printPanel release];
	[_view release];
	[_jobStyleHint release];
	[super dealloc];
}

- (NSGraphicsContext *) createContext
{
	NSDictionary *attributes=nil;	// FIXME: define context attributes - either file or NSMutableData
	[self destroyContext];	// if any other is already defined
	_context=[[_NSPDFGraphicsContext graphicsContextWithAttributes:attributes] retain];	// create context
	return _context;
}

- (NSGraphicsContext *) context	{ return _context; }

- (void) destroyContext
{
	[_context release];
	_context=nil;
}

- (NSInteger) currentPage		{ return _currentPage; }

- (void) cleanUpOperation
{
	// remove us as the current operation
}

- (BOOL) deliverResult
{
/* FIXME:
	get a reference to the _pdf NSStream from context - before it is deallocated!
	NSOutputStream *_pdf=[[self context] attributes];
	[_pdf propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
	*/
	// store in file if _path is defined
	// store in data if _data is defined
	// else save in print queue
	return YES;
}

- (BOOL) isCopyingOperation;						{ NIMP; return NO; }

- (NSView *) accessoryView;							{ return _accessoryView; }
- (BOOL) canSpawnSeparateThread;					{ return _canSpawnSeparateThread; }
- (NSString *) jobStyleHint;						{ return _jobStyleHint; }
- (NSPrintingPageOrder) pageOrder;					{ return _pageOrder; }
- (NSPrintInfo *) printInfo;						{ return _printInfo; }
- (BOOL) showPanels;								{ return _showPanels; }
- (BOOL) showsPrintPanel;							{ return _showPrintPanel; }
- (BOOL) showsProgressPanel;						{ return _showProgressPanel; }
- (NSView *) view;									{ return _view; }
- (NSPrintPanel *) printPanel;						{ return _printPanel; }

- (void) setAccessoryView:(NSView *)aView;			{ ASSIGN(_accessoryView, aView); }
- (void) setCanSpawnSeparateThread:(BOOL)flag;		{ _canSpawnSeparateThread=flag; }
- (void) setJobStyleHint:(NSString *)hint;			{ ASSIGN(_jobStyleHint, hint); }
- (void) setPageOrder:(NSPrintingPageOrder)order;	{ _pageOrder=order; }
- (void) setPrintInfo:(NSPrintInfo *)aPrintInfo;	{ ASSIGN(_printInfo, aPrintInfo); }
- (void) setPrintPanel:(NSPrintPanel *)panel;		{ ASSIGN(_printPanel, panel); }
- (void) setShowsPrintPanel:(BOOL)flag;				{ _showPrintPanel=flag; }
- (void) setShowPanels:(BOOL)flag;					{ DEPRECATED; _showPanels=flag; }
- (void) setShowsProgressPanel:(BOOL)flag;			{ _showProgressPanel=flag; }

- (void) _notify:(NSPrintOperation *) po success:(BOOL) success context:(void *) contextInfo;
{
	_success=success;
}

- (BOOL) runOperation
{
	BOOL f=_canSpawnSeparateThread;
	_canSpawnSeparateThread=NO;
	[self runOperationModalForWindow:nil delegate:self didRunSelector:@selector(_notify:success:context:) contextInfo:nil];
	_canSpawnSeparateThread=f;
	return _success;
}

- (IBAction) cancel:(id) sender;
{
#if 1
	NSLog(@"printing cancelled");
#endif
	_cancelled=YES;
}

- (void) runOperationModalForWindow:(NSWindow *)docWindow
													 delegate:(id)delegate
										 didRunSelector:(SEL)didRunSelector
												contextInfo:(void *)contextInfo;
{
	BOOL r=YES;
#if 1
	NSLog(@"run PrintOperation for %@", _view);
#endif
	if([[self class] currentOperation])
		; // FIXME: raise exception - already a print operation in progress
	[[self class] setCurrentOperation:self];
	if(_showPanels || _showPrintPanel)
		{
#if 1
		NSLog(@"show print panel");
#endif
		[_printPanel setAccessoryView:_accessoryView];
		[_printPanel setJobStyleHint:_jobStyleHint];
		if(!docWindow)
			r=([_printPanel runModal] == NSOKButton);	// is ok
		else
				[_printPanel beginSheetWithPrintInfo:_printInfo
															modalForWindow:docWindow
																		delegate:delegate
															didEndSelector:didRunSelector
																 contextInfo:contextInfo];
		// FIXME: how does redirection to a file or mail work???
		}
	if(r)
		{ // wasn't cancelled explicitly
		NSRange pages;
		BOOL paginated=[_view knowsPageRange:&pages];
		if(!paginated)
			pages=NSMakeRange(1, 1);	// single page
		// intersect with the range specified in the print operation
		if(_showPanels || _showProgressPanel)
			{
#if 1
			NSLog(@"load progress panel");
#endif
			if([NSBundle loadNibNamed:@"PrintProgressPanel" owner:self])
				{
#if 1
				NSLog(@"did load progress panel");
#endif
				[_progressIndicator setMinValue:1.0];
				[_progressIndicator setMaxValue:pages.length];
				}
			}
		if(_canSpawnSeparateThread)
			;
		if([self createContext])
			{
			[_view beginDocument];
			_currentPage=_pageOrder != NSDescendingPageOrder?1:pages.length;	// first/last
			_cancelled=NO;
			while(!_cancelled && _currentPage > 0 && _currentPage <= pages.length)
				{ // print page(s) of _view
				NSRect pageRect=paginated?[_view rectForPage:_currentPage]:_insideRect;
				// give loop a chance to run once and handle needsDisplay events!!!
#if 1
				NSLog(@"Print Page %d of %lu", _currentPage, (unsigned long)pages.length);
#endif
				if(_progressIndicator)
					{
					[_progressIndicator setDoubleValue:(double) _currentPage];
					[_progressIndicator display];
					[_progessMessage setStringValue:[NSString stringWithFormat:@"Page %d of %d", _currentPage, pages.length]];
					[_progessMessage display];
#if 1
					sleep(5);
#endif
					}
				// set up everything in context so that we write into a new Page stream
				[_view beginPageInRect:pageRect atPlacement:[_view locationOfPrintRect:pageRect]];	// this locks focus and sets the CTM so that the pageRectangle is placed properly on the page
				[_view drawPageBorderWithSize:_insideRect.size];
				[[_view pageHeader] drawAtPoint:NSMakePoint(10.0, 2000.0)];
				// set clipping rect to pageRect
#if 1
				NSLog(@"Print int rect %@", NSStringFromRect(pageRect));
#endif
				[_view drawRect:pageRect];
				[[_view pageFooter] drawAtPoint:NSMakePoint(10.0, 10.0)];
				[_view endPage];	// unlocks focus
				if(_pageOrder != NSDescendingPageOrder)
					_currentPage++;	// next
				else
					_currentPage--;	// previous
				}
			[_view endDocument];	// unlocks focus
			[self destroyContext];
			if([self deliverResult])
				[self cleanUpOperation];
			}
		[_progressPanel close];
		}
		// FIXME: may run in different thread
	// FIXME: selector has a different signature:
	// [delegate <didRunSelector>:self success:_cancelled?NSPrntCancelled:NSPrintSuccess contextInfo:contextInfo];
	if(didRunSelector)
		[delegate performSelector:didRunSelector withObject:(id)contextInfo];
	[[self class] setCurrentOperation:nil];
}

@end /* NSPrintOperation */
