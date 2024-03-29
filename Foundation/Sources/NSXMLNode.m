//
//  NSXMLNode.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>


@implementation NSXMLNode

// convenience allocators

/*
 + (NSString *) localNameForName:(NSString *) name;
 + (NSXMLNode *) predefinedNamespaceForPrefix:(NSString *) prefix;
 + (NSString *) prefixForName:(NSString *) prefix;
 */

+ (id) elementWithName:(NSString *) name children:(NSArray *) nodes attributes:(NSArray *) attrs;
{
	NSXMLElement *e=[self elementWithName:name];
	[e insertChildren:nodes atIndex:0];
	[e setAttributes:attrs];
	return e;
}

+ (id) attributeWithName:(NSString *) name stringValue:(NSString *) value; { NSXMLNode *n=[[[NSXMLNode alloc] initWithKind:NSXMLAttributeKind] autorelease]; [n setName:name]; [n setStringValue:value]; return n; }
+ (id) attributeWithName:(NSString *) name URI:(NSString *) uri stringValue:(NSString *) value;  { NSXMLNode *n=[[[NSXMLNode alloc] initWithKind:NSXMLAttributeKind] autorelease]; [n setName:name]; [n setURI:uri]; [n setStringValue:value]; return n; }
+ (id) commentWithStringValue:(NSString *) value; { NSXMLNode *n=[[[NSXMLNode alloc] initWithKind:NSXMLCommentKind] autorelease]; [n setStringValue:value]; return n; }
+ (id) DTDNodeWithXMLString:(NSString *) str; { return [[[NSXMLDTDNode alloc] initWithXMLString:str] autorelease]; }
+ (id) document; { return [[[NSXMLDocument alloc] initWithKind:NSXMLDocumentKind] autorelease]; }
+ (id) documentWithRootElement:(NSXMLElement *) ele; { return [[[NSXMLDocument alloc] initWithRootElement:ele] autorelease]; }
+ (id) elementWithName:(NSString *) name; { return [[[NSXMLElement alloc] initWithName:name] autorelease]; }
+ (id) elementWithName:(NSString *) name URI:(NSString *) uri; { return [[[NSXMLElement alloc] initWithName:name URI:uri] autorelease]; }
+ (id) elementWithName:(NSString *) name stringValue:(NSString *) value; { return [[[NSXMLElement alloc] initWithName:name stringValue:value] autorelease]; }
+ (id) namespaceWithName:(NSString *) name stringValue:(NSString *) value; { NSXMLNode *n=[[[NSXMLNode alloc] initWithKind:NSXMLNamespaceKind] autorelease]; [n setStringValue:value]; return n; }
+ (id) processingInstructionWithName:(NSString *) name stringValue:(NSString *) value; { NSXMLNode *n=[self predefinedNamespaceForPrefix:@"xmlns"]; [n setStringValue:value]; return n; }
+ (id) textWithStringValue:(NSString *) value; { NSXMLNode *n=[[[NSXMLNode alloc] initWithKind:NSXMLTextKind] autorelease]; [n setStringValue:value]; return n; }
+ (NSString *) localNameForName:(NSString *) name; { NSArray *c=[name componentsSeparatedByString:@":"]; if([c count] > 1) return [c objectAtIndex:1]; return @""; }
+ (NSXMLNode *) predefinedNamespaceForPrefix:(NSString *) prefix; { /* FIXME: check prefix */NSXMLNode *n=[[[NSXMLNode alloc] initWithKind:NSXMLProcessingInstructionKind] autorelease]; [n setName:prefix]; return n; }
+ (NSString *) prefixForName:(NSString *) prefix; { NSArray *c=[prefix componentsSeparatedByString:@":"]; if([c count] > 1) return [c objectAtIndex:0]; return @""; }

- (id) initWithKind:(NSXMLNodeKind) kind;
{
	if((self=[super init]))
		_kind=kind;
	return self;
}

- (id) initWithKind:(NSXMLNodeKind) kind options:(NSUInteger) opts;
{
	if((self=[self initWithKind:kind]))
		{
		_options=opts;
		}
	return self;
}

- (NSUInteger) _options;	// Cocoa has no official getter or setter???
{
	return _options;
}

- (id) copyWithZone:(NSZone *) zone
{
	return nil;
}

- (void) dealloc;
{
	[_name release];
	[_objectValue release];
	[_children makeObjectsPerformSelector:@selector(_setParent:) withObject:nil];	// detach our children nodes from us
	[_children release];
	[_localName release];
	[_prefix release];
	[_URI release];
	[super dealloc];
}

// simple getters

- (NSXMLNodeKind) kind; { return _kind; }
- (NSString *) name; { return _name; }
- (NSString *) prefix; { return _prefix; }
- (id) objectValue; { return _objectValue; }

// FIXME: concatenate children and/or apply value transformers!
- (NSString *) stringValue; { return _objectValue; }
- (NSXMLDocument *) rootDocument; { return [_parent rootDocument]; }
- (NSXMLNode *) parent; { return _parent; }
- (NSUInteger) childCount; { return [_children count]; }
- (NSArray *) children; { return _children; }
- (NSString *) URI; { return _URI; }

- (NSUInteger) level; { NSUInteger level=0; while(_parent) { level++; self=_parent; } return level; }
- (NSUInteger) index; { return [[_parent children] indexOfObjectIdenticalTo:self]; }
- (NSXMLNode *) childAtIndex:(NSUInteger) idx; { return [_children objectAtIndex:idx]; }
- (NSXMLNode *) previousSibling; { NSUInteger idx=[self index]; return idx > 0?[_parent childAtIndex:idx-1]:(NSXMLNode *)nil; }
- (NSXMLNode *) nextSibling; { NSUInteger idx=[self index]; return idx < [[_parent children] count]-1?[_parent childAtIndex:[self index]+1]:(NSXMLNode *)nil; }
- (NSXMLNode *) previousNode; { /* if we have children, take last child; take previousSibling - if nil, go up one level and find last node by walking down */ return NIMP; }
- (NSXMLNode *) nextNode; { /* if we have children, take first child; take nextSibling - if nil, go up one level and find first node by walking down */ return NIMP; }
- (NSString *) localName; { return _localName; }

- (NSString *) description; { return [self XMLString]; }

- (NSString *) XMLString; { return [self XMLStringWithOptions:NSXMLNodeOptionsNone]; }

- (void) _XMLStringWithOptions:(NSUInteger) opts appendingToString:(NSMutableString	*) str;
{
	switch(_kind) {
		default:
		case NSXMLInvalidKind:
		case NSXMLDocumentKind:	// handled by overwriting in subclass
		case NSXMLElementKind:	// handled by overwriting in subclass
			break;
		case NSXMLAttributeKind:
			if(_URI)
				[str appendFormat:@"%@:%@=", _URI, _name];
			else
				[str appendFormat:@"%@=", _name];
			// escape quotes and entities
			if(opts&NSXMLNodeUseSingleQuotes)
				[str appendFormat:@"'%@'", _objectValue];
			else
				[str appendFormat:@"\"%@\"", _objectValue];
			break;
		case NSXMLNamespaceKind:
			[str appendFormat:@"xmlns:%@", _objectValue];
			break;
		case NSXMLProcessingInstructionKind: {
			unsigned long documentKind=[[self rootDocument] documentContentKind];	// Text, XML, XHTML, HTML etc.
			if(documentKind != NSXMLDocumentTextKind)
				{
				[str appendFormat:@"<?%@", _name];
				if(_objectValue)
					[str appendString:_objectValue];
				[str appendString:@"?>"];
				if(opts&(NSXMLDocumentTidyHTML|NSXMLDocumentTidyXML))
					[str appendString:@"\n"];
				}
			break;
		}
		case NSXMLCommentKind: {
			unsigned long documentKind=[[self rootDocument] documentContentKind];	// Text, XML, XHTML, HTML etc.
		// FIXME: escape -- in comments
			if(documentKind != NSXMLDocumentTextKind)
				//what if there is --> part of the string???
				[str appendFormat:@"<!--%@-->", _objectValue];
			break;
		}
		case NSXMLTextKind:
			if(_options & NSXMLNodeIsCDATA)
				{
				// write as CDATA
				}
			else
				{ // html escape contents
				[str appendString:_objectValue];
				}
			break;
		case NSXMLDTDKind:
			break;
		case NSXMLEntityDeclarationKind:
		case NSXMLAttributeDeclarationKind:
		case NSXMLElementDeclarationKind:
		case NSXMLNotationDeclarationKind:
			break;
	}
}

- (NSString *) XMLStringWithOptions:(NSUInteger) opts;
{
	NSMutableString *str=[NSMutableString stringWithCapacity:100];
	[self _XMLStringWithOptions:opts appendingToString:str];
	return str;
}

- (NSString *) canonicalXMLStringPreservingComments:(BOOL) flag;
{
	return NIMP;
}

- (void) detach; { if(_parent) [(NSMutableArray *)[_parent children] removeObjectIdenticalTo:self]; _parent=nil; }

- (void) _setParent:(NSXMLNode *) p; { _parent=p; }
- (void) setName:(NSString *) name; { ASSIGN(_name, name); }
- (void) setObjectValue:(id) value; { ASSIGN(_objectValue, value); }
- (void) setStringValue:(NSString *) str; { /* check for string */ ASSIGN(_objectValue, str); }
- (void) setURI:(NSString *) uri; { ASSIGN(_URI, uri); }

- (void) setStringValue:(NSString *) str resolvingEntities:(BOOL) flag;
{
	if(flag)
		NIMP;
	[self setStringValue:str];
}

// XPath

- (NSString *) XPath; { return NIMP; }
- (NSArray *) nodesForXPath:(NSString *) path error:(NSError **) err; { return NIMP; }
- (NSArray *) objectsForXQuery:(NSString *) query constants:(NSDictionary *) consts error:(NSError **) err; { return NIMP; }
- (NSArray *) objectsForXQuery:(NSString *) query error:(NSError **) err; { return NIMP; }

/* abstract methods implemented here but not visible in header file */

- (void) insertChild:(NSXMLNode *) node atIndex:(NSUInteger) idx;
{
	NSAssert(![node parent], @"insertChild:atIndex: NSXMLNode already has a parent");
	if(!_children)
		_children=[[NSMutableArray alloc] initWithCapacity:5];
	[_children insertObject:node atIndex:idx];
	[node _setParent:self];
}

- (void) insertChildren:(NSArray *) nodes atIndex:(NSUInteger) idx;
{
	// for all children	NSAssert(![node parent], @"NSXMLNode already has a parent");
	if(!_children)
		_children=[[NSMutableArray alloc] initWithCapacity:[nodes count]+3];
	[_children insertObjects:nodes atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx, [nodes count])]];
	[nodes makeObjectsPerformSelector:@selector(_setParent:) withObject:self];
}

- (void) removeChildAtIndex:(NSUInteger) idx;
{
	[[_children objectAtIndex:idx] _setParent:nil];
	[_children removeObjectAtIndex:idx];
}

- (void) setChildren:(NSArray *) nodes;
{
	ASSIGN(_children, nodes);
	[nodes makeObjectsPerformSelector:@selector(_setParent:) withObject:self];
}

- (void) addChild:(NSXMLNode *) node;
{
	[self insertChild:node atIndex:[_children count]];
}

- (void) replaceChildAtIndex:(NSUInteger) idx withNode:(NSXMLNode *) node;
{
	[[_children objectAtIndex:idx] _setParent:nil];
	[_children replaceObjectAtIndex:idx withObject:node];
	[node _setParent:self];
}

@end

@implementation NSXMLNode (NSXMLParserDelegate)

- (void) parserDidStartDocument:(NSXMLParser *) parser;
{
#if 0
	NSLog(@"didStartDocument: %@", self);
#endif
	_current=self;
}

- (void) parserDidEndDocument:(NSXMLParser *) parser;
{
#if 0
	NSLog(@"didEndDocument: %@", self);
#endif
}

- (void) parser:(NSXMLParser *) parser parseErrorOccurred:(NSError *) parseError;
{
	NSLog(@"parse Error: %@", parseError);
}

- (void) parser:(NSXMLParser *) parser validationErrorOccurred:(NSError *) parseError;
{
}

- (void) parser:(NSXMLParser *) parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict;
{
	NSXMLElement *element=[[NSXMLElement alloc] initWithName:elementName URI:namespaceURI];
	// what is the qualified name?
#if 0
	NSLog(@"didStartElement: %@ namespace: %@ qualified: %@ attributes: %@", elementName, namespaceURI, qualifiedName, attributeDict);
#endif
	[element setAttributesAsDictionary:attributeDict];
	[_current addChild:element];	// add to parent level
	_current=element;	// handle nesting
}

- (void) parser:(NSXMLParser *) parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName;
{
#if 0
	NSLog(@"didEndElement: %@ namespace: %@ qualified: %@", elementName, namespaceURI, qualifiedName);
#endif
	_current=[_current parent];
}

/*
 - parser:didStartMappingPrefix:toURI:
 - parser:didEndMappingPrefix:
 - parser:resolveExternalEntityName:systemID:
 */

- (void) parser:(NSXMLParser *) parser foundCharacters:(NSString *) characters;
{
	[_current addChild:[NSXMLNode textWithStringValue:characters]];
}

- (void) parser:(NSXMLParser *) parser foundIgnorableWhitespace:(NSString *) characters;
{
	[_current addChild:[NSXMLNode textWithStringValue:characters]];	
}

- (void) parser:(NSXMLParser *) parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data;
{ // e.g. <?xml*> - target=@"xml" - well not <?xml?> because that is not a processing instruction!
#if 0
	NSLog(@"foundProcessingInstructionWithTarget: %@ data: %@", target, data);
#endif
	if([target isEqualToString:@"xml"] && [self isKindOfClass:[NSXMLDocument class]])
		{
		// FIXME: make this more general - and maybe case-insensitive and accept single quutes?!?
#if 0
		NSLog(@"found %@", target);
#endif
		NSRange rng=[data rangeOfString:@"version=\""], rng2;
#if 0
		NSLog(@"rng=%@", NSStringFromRange(rng));
#endif
		if(rng.location != NSNotFound)
			{
			rng2=[data rangeOfString:@"\"" options:0 range:NSMakeRange(NSMaxRange(rng), [data length]-NSMaxRange(rng))];
#if 0
			NSLog(@"rng2=%@", NSStringFromRange(rng2));
#endif
			if(rng2.location != NSNotFound)
				[(NSXMLDocument *) self setVersion:[data substringWithRange:NSMakeRange(NSMaxRange(rng), rng2.location-NSMaxRange(rng))]];
			}
		rng=[data rangeOfString:@"encoding=\""];
#if 0
		NSLog(@"rng=%@", NSStringFromRange(rng));
#endif
		if(rng.location != NSNotFound)
			{
			rng2=[data rangeOfString:@"\"" options:0 range:NSMakeRange(NSMaxRange(rng), [data length]-NSMaxRange(rng))];
#if 0
			NSLog(@"rng2=%@", NSStringFromRange(rng2));
#endif
			if(rng2.location != NSNotFound)
				[(NSXMLDocument *) self setCharacterEncoding:[data substringWithRange:NSMakeRange(NSMaxRange(rng), rng2.location-NSMaxRange(rng))]];
			}
		[(NSXMLDocument *) self setStandalone:YES];
		rng=[data rangeOfString:@"standalone=\"no\""];
#if 0
		NSLog(@"rng=%@", NSStringFromRange(rng));
#endif
		if(rng.location != NSNotFound)
			{ // must explicitly turn off
			[(NSXMLDocument *) self setStandalone:NO];
			}
		return;
		}
	[_current addChild:[NSXMLNode processingInstructionWithName:target stringValue:data]];
}

- (void) parser:(NSXMLParser *) parser foundComment:(NSString *) characters;
{
	[_current addChild:[NSXMLNode commentWithStringValue:characters]];
}

- (void) parser:(NSXMLParser *) parser foundCDATA:(NSData *)CDATABlock;
{
	NSXMLNode *n=[[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
	[n setObjectValue:CDATABlock];
	[_current addChild:n];
	[n release];
}

/*
 - parser:foundAttributeDeclarationWithName:forElement:type:defaultValue:
 - parser:foundElementDeclarationWithName:model:
 - parser:foundExternalEntityDeclarationWithName:publicID:systemID:
 - parser:foundInternalEntityDeclarationWithName:value:
 - parser:foundUnparsedEntityDeclarationWithName:publicID:systemID:notationName:
 - parser:foundNotationDeclarationWithName:publicID:systemID:
 */

@end
