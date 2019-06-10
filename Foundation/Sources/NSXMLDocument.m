//
//  NSXMLDocument.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@implementation NSXMLDocument

+ (Class) replacementClassForClass:(Class) class;
{
	return Nil;
}

- (NSString *) characterEncoding; { return _characterEncoding; }

- (void) dealloc;
{
	[_characterEncoding release];
	[_DTD release];
	[_MIMEType release];
	[_version release];
	[super dealloc];
}

- (NSXMLDocumentContentKind) documentContentKind; { return _documentContentKind; }

- (NSXMLDTD *) DTD; { return _DTD; }

- (id) initWithContentsOfURL:(NSURL *) url options:(NSUInteger) optsMask error:(NSError **) err;
{
	NSData *data=[NSData dataWithContentsOfURL:url options:optsMask error:err];
	if(!data)
		{
		[self release];
		return nil;
		}
	return [self initWithData:data options:optsMask error:err];
}

- (id) initWithXMLString:(NSString *) str options:(NSUInteger) optsMask error:(NSError **) err;
{
	// FIXME - we must set the encoding to UTF-8 *before* we try to parse!
	// i.e. should we check the <?xml tag that it contains UTF-8 or add that if it is missing/different?
	return [self initWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:optsMask error:err];
}

- (id) initWithData:(NSData *) data options:(NSUInteger) optsMask error:(NSError **) err;
{
	if((self=[self initWithRootElement:nil]))
		{
		NSXMLParser *parser;
		parser=[[NSXMLParser alloc] initWithData:data];
#if 1
		NSLog(@"parser=%@", parser);
#endif
		[parser setDelegate:self];	// the delegate methods are implemented in our NSXMLNode superclass
		[parser setShouldProcessNamespaces:YES];
		[parser setShouldReportNamespacePrefixes:YES];
		[parser setShouldResolveExternalEntities:YES];
		if(![parser parse])
			{
#if 1
			NSLog(@"tree=%@", self);
#endif
			if(err)
				*err=[parser parserError];
			[self release]; 
			self=nil;
			}
		[parser release];
		if((optsMask & NSXMLDocumentValidate) && self && ![self validateAndReturnError:err])
			{
			[self release];
			self=nil;
			}
		}
#if 1
	NSLog(@"parsed XML document: %@", self);
#endif
	return self;
}

- (id) initWithRootElement:(NSXMLElement *) rootNode;
{
	// raise [self release], self=nil; if not a valid root node
	if((self=[super initWithKind:NSXMLDocumentKind]))
		{
		if(rootNode)
			[self addChild:rootNode];
		}
	return self;
}

- (BOOL) isStandalone; { return _isStandalone; }

- (NSString *) MIMEType; { return _MIMEType; }

- (id) objectByApplyingXSLT:(NSData *) data arguments:(NSDictionary *) args error:(NSError **) err;
{
	return NIMP;
}

- (id) objectByApplyingXSLTAtURL:(NSURL *) url arguments:(NSDictionary *) args error:(NSError **) err;
{
	return NIMP;
}

- (id) objectByApplyingXSLTString:(NSString *) str arguments:(NSDictionary *) args error:(NSError **) err;
{
	return NIMP;
}

- (NSXMLElement *) rootElement;
{
	return (NSXMLElement *) [self childAtIndex:0];
}

- (void) setCharacterEncoding:(NSString *) str; { ASSIGN(_characterEncoding, str); }

- (void) setDocumentContentKind:(NSXMLDocumentContentKind) kind; { _documentContentKind=kind; }

- (void) setDTD:(NSXMLDTD *) dtd; { ASSIGN(_DTD, dtd); }

- (void) setMIMEType:(NSString *) mime; { ASSIGN(_MIMEType, mime); }

- (void) setRootElement:(NSXMLNode *) rootNode;
{
	// raise exception if not root node
	while([self childCount] > 0)
		[self removeChildAtIndex:0];
	[self addChild:rootNode];
}

- (void) setStandalone:(BOOL) flag; { _isStandalone=flag; }

- (void) setVersion:(NSString *) version; { ASSIGN(_version, version); }

- (BOOL) validateAndReturnError:(NSError **) err;
{
	NIMP;
	// should check DTD
	return YES;
}

- (NSString *) version; { return _version; }

- (void) _XMLStringWithOptions:(NSUInteger) opts appendingToString:(NSMutableString	*) str;
{
	switch([self documentContentKind]) { // Text, XML, XHTML, HTML etc.
		case NSXMLDocumentXMLKind:
			if(_version || _characterEncoding || _isStandalone)
				{
				[str appendString:@"<?xml"];
				if(_version)
					[str appendFormat:@" version=\"%@\"", _version];
				else
					[str appendString:@" version=\"1.0\""];
				if(_characterEncoding)
					[str appendFormat:@" encoding=\"%@\"", _characterEncoding];
				[str appendFormat:@" standalone=\"%@\"", _isStandalone?@"yes":@"no"];
				[str appendString:@"?>"];
				}
			[[self DTD] _XMLStringWithOptions:opts appendingToString:str];
			[[self rootElement] _XMLStringWithOptions:opts appendingToString:str];
			return;
		case NSXMLDocumentXHTMLKind:
			//					[str appendString:@"<?xml UTF-8>\n"];
		case NSXMLDocumentHTMLKind:
			[[self DTD] _XMLStringWithOptions:opts appendingToString:str];
			[str appendString:@"<html>\n"];
			[[self rootElement] _XMLStringWithOptions:opts appendingToString:str];
			[str appendString:@"</html>\n"];
			return;
		case NSXMLDocumentTextKind:
			[[self rootElement] _XMLStringWithOptions:opts appendingToString:str];
	}
	[super _XMLStringWithOptions:opts appendingToString:str];
}

- (NSData *) XMLData; { return [self XMLDataWithOptions:NSXMLNodeOptionsNone]; }

- (NSData *) _XMLDataWithOptions:(NSUInteger) opts format:(NSUInteger) fmt
{
	NSString *str=nil;
	switch(_documentContentKind) {
		case NSXMLDocumentTextKind:
			// collect all nodes into single text string and ignore all tags
			break;
		case NSXMLDocumentXMLKind:
		case NSXMLDocumentXHTMLKind:
		case NSXMLDocumentHTMLKind:
			// how can we pass down opts&NSXMLDocumentIncludeContentTypeDeclaration and documentKind?
			str=[[self rootElement] XMLStringWithOptions:opts];
	}
	// handle characterEncoding - use UTF8 if unknown
	return [str dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *) XMLDataWithOptions:(NSUInteger) opts;
{
	return [self _XMLDataWithOptions:opts format:_documentContentKind];
}

@end
