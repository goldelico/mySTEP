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
	return [self initWithData:data options:optsMask	error:err];
}

// implement NSXMLParser delegate methods...

- (id) initWithData:(NSData *) data options:(NSUInteger) optsMask error:(NSError **) err;
{
	if((self=[self initWithRootElement:nil]))
			{
				NSXMLParser *parser;
	// try to parse XML
	// set encoding if defined
	// etc.
				parser=[[NSXMLParser alloc] initWithData:data];
#if 1
				NSLog(@"parser=%@", parser);
#endif
				[parser setDelegate:self];
				[parser setShouldProcessNamespaces:YES];
				[parser setShouldReportNamespacePrefixes:YES];
				[parser setShouldResolveExternalEntities:YES];
				if(![parser parse])
						{
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

- (id) initWithXMLString:(NSString *) str options:(NSUInteger) optsMask error:(NSError **) err;
{
	// FIXME - we must set the encoding to UTF-8 *before* we try to parse!
	// i.e. should we check the <?xml tag that it contains UTF-8 or add that if it is missing/different?
	return [self initWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:optsMask error:err];
}

- (NSString *) _descriptionTag;
{
	return [super _descriptionTag];
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
	// check for a root node
	return nil;
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

- (NSData *) XMLData; { return [self XMLDataWithOptions:0]; }

- (NSData *) XMLDataWithOptions:(NSUInteger) opts;
{
	NSString *str=nil;
	switch(_documentContentKind)
		{
			case NSXMLDocumentTextKind:
				// collect all nodes into text string
				break;
			case NSXMLDocumentXMLKind:
			case NSXMLDocumentXHTMLKind:
			case NSXMLDocumentHTMLKind:
				// how can we pass down opts&NSXMLDocumentIncludeContentTypeDeclaration and documentKind?
				// documentKind can be requested from any node by going through the parents until we find self
				str=[[self rootElement] XMLStringWithOptions:opts];
		}
	// handle characterEncoding
	return [str dataUsingEncoding:NSUTF8StringEncoding];
}

@end
