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

+ (id) attributeWithName:(NSString *) name stringValue:(NSString *) value; { NSXMLNode *n=[[[self alloc] initWithKind:NSXMLAttributeKind] autorelease]; [n setStringValue:value]; return n; }
+ (id) attributeWithName:(NSString *) name URI:(NSString *) uri stringValue:(NSString *) value;  { NSXMLNode *n=[[[self alloc] initWithKind:NSXMLAttributeKind] autorelease]; [n setURI:uri]; [n setStringValue:value]; return n; }
+ (id) commentWithStringValue:(NSString *) value; { NSXMLNode *n=[[[self alloc] initWithKind:NSXMLCommentKind] autorelease]; [n setStringValue:value]; return n; }
+ (id) DTDNodeWithXMLString:(NSString *) str; { return [[[NSXMLDTDNode alloc] initWithXMLString:str] autorelease]; }
+ (id) document; { return [[[NSXMLDocument alloc] initWithKind:NSXMLDocumentKind] autorelease]; }
+ (id) documentWithRootElement:(NSXMLElement *) ele; { return [[[NSXMLDocument alloc] initWithRootElement:ele] autorelease]; }
+ (id) elementWithName:(NSString *) name; { return [[[NSXMLElement alloc] initWithName:name] autorelease]; }
+ (id) elementWithName:(NSString *) name URI:(NSString *) uri; { return [[[NSXMLElement alloc] initWithName:name URI:uri] autorelease]; }
+ (id) elementWithName:(NSString *) name stringValue:(NSString *) value; { return [[[NSXMLElement alloc] initWithName:name stringValue:value] autorelease]; }
+ (id) namespaceWithName:(NSString *) name stringValue:(NSString *) value; { NSXMLNode *n=[[[self alloc] initWithKind:NSXMLNamespaceKind] autorelease]; [n setStringValue:value]; return n; }
+ (id) processingInstructionWithName:(NSString *) name stringValue:(NSString *) value; { NSXMLNode *n=[self predefinedNamespaceForPrefix:@"xmlns"]; [n setStringValue:value]; return n; }
+ (id) textWithStringValue:(NSString *) value; { NSXMLNode *n=[[[self alloc] initWithKind:NSXMLTextKind] autorelease]; [n setStringValue:value]; return n; }
+ (NSString *) localNameForName:(NSString *) name; { NSArray *c=[name componentsSeparatedByString:@":"]; if([c count] > 1) return [c objectAtIndex:1]; return @""; }
+ (NSXMLNode *) predefinedNamespaceForPrefix:(NSString *) prefix; { /* FIXME: check prefix */NSXMLNode *n=[[[self alloc] initWithKind:NSXMLProcessingInstructionKind] autorelease]; [n setName:prefix]; return n; }
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

- (id) copyWithZone:(NSZone *) zone
{
	return nil;
}

- (void) dealloc;
{
	[_name release];
	[_objectValue release];
	// _rootDocument;	// weak pointer
	[self detach];
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
- (NSString *) stringValue; { return _objectValue; }
- (NSXMLDocument *) rootDocument; { return _rootDocument; }
- (NSXMLNode *) parent; { return _parent; }
- (NSUInteger) childCount; { return [_children count]; }
- (NSArray *) children; { return _children; }
- (NSString *) URI; { return _URI; }

- (NSUInteger) level; { NSUInteger level=0; while(_parent) level++, self=_parent; return level; }
- (NSUInteger) index; { return [[_parent children] indexOfObjectIdenticalTo:self]; }
- (NSXMLNode *) childAtIndex:(NSUInteger) idx; { return [_children objectAtIndex:idx]; }
- (NSXMLNode *) previousSibling; { NSUInteger idx=[self index]; return idx > 0?[_parent childAtIndex:idx-1]:nil; }
- (NSXMLNode *) nextSibling; { NSUInteger idx=[self index]; return idx < [[_parent children] count]-1?[_parent childAtIndex:[self index]+1]:nil; }
- (NSXMLNode *) previousNode; { /* if we have children, take last child; take previousSibling - if nil, go up one level and find last node by walking down */ return NIMP; }
- (NSXMLNode *) nextNode; { /* if we have children, take first child; take nextSibling - if nil, go up one level and find first node by walking down */ return NIMP; }
- (NSString *) localName; { return _localName; }

// formatters

- (NSString *) _descriptionTag;
{
	if(_name)
		return [NSString stringWithFormat:@"<%@ %@ %d>%@\n", _name, NSStringFromClass([self class]), _kind, _objectValue?_objectValue:@""];
	return [NSString stringWithFormat:@"<%@ %d>%@\n", NSStringFromClass([self class]), _kind, _objectValue?_objectValue:@""];
}

- (NSString *) _descriptionWithLevel:(int) n;
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSString *indent=[@"" stringByPaddingToLength:2*n withString:@" " startingAtIndex:0];
	NSString *s=[indent stringByAppendingString:[self _descriptionTag]];
	NSEnumerator *e=[_children objectEnumerator];
	NSXMLNode *child;
	while((child=[e nextObject]))
		s=[s stringByAppendingString:[child	_descriptionWithLevel:n+1]];
	if(_name)
		s=[s stringByAppendingFormat:@"%@</%@>\n", indent, _name];
	[s retain];
	[arp release];
	return [s autorelease];
}

- (NSString *) description;
{
	return [self _descriptionWithLevel:0];
}

- (NSString *) XMLString; { return [self XMLStringWithOptions:0]; }

- (NSString *) XMLStringWithOptions:(NSUInteger) opts;
{
	switch(_kind)
		{
			default:
			case NSXMLInvalidKind:
				break;
			case NSXMLDocumentKind:
				return [NSString stringWithFormat:@"<?xml UTF-8>\n%@\n%@", [[(NSXMLDocument *) self DTD] XMLStringWithOptions:opts], [[(NSXMLDocument *) self rootElement] XMLStringWithOptions:opts]];
			case NSXMLElementKind:
				if([_children count])
					return [NSString stringWithFormat:@"<%@ %@>%@</%@>", _name, [(NSXMLElement *) self attributes], [self children], _name];
				return [NSString stringWithFormat:@"<%@/>"];
			case NSXMLAttributeKind:
				// escape quotes and entities
				if(_URI)
					return [NSString stringWithFormat:@"%@:%@='%@'", _URI, _name, _objectValue];
				return [NSString stringWithFormat:@"%@='%@'", _name, _objectValue];
			case NSXMLNamespaceKind:
				return [NSString stringWithFormat:@"xmlns:%@", _objectValue];
			case NSXMLProcessingInstructionKind:
				break;
			case NSXMLCommentKind:
				// escape -- in comments
				return [NSString stringWithFormat:@"<!--%@-->", _objectValue];
			case NSXMLTextKind:
				return _objectValue;
			case NSXMLDTDKind:
				return _objectValue;
			case NSXMLEntityDeclarationKind:
			case NSXMLAttributeDeclarationKind:
			case NSXMLElementDeclarationKind:
			case NSXMLNotationDeclarationKind:
				break;
		}
	return @"???";
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
	if(!_children)
		_children=[[NSMutableArray alloc] initWithCapacity:5];
	[_children insertObject:node atIndex:idx];
	[node _setParent:self];
}

- (void) insertChildren:(NSArray *) nodes atIndex:(NSUInteger) idx;
{
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

// XML parsing

- (void) parser:(NSXMLParser *) parser foundCharacters:(NSString *) string
{
	// we may want to add individual text nodes depending on parse options!
	if(!_objectValue)
		_objectValue = [[NSMutableString alloc] initWithCapacity:50];
	[_objectValue appendString:string];    
}

- (void) parser:(NSXMLParser *) parser foundIgnorableWhitespace:(NSString *) string
{
	// we may want to add individual text nodes or completely ignore - depending on parse options!
	if(!_objectValue)
		_objectValue = [[NSMutableString alloc] initWithCapacity:50];
	[_objectValue appendString:string];    
}

- (void) parser:(NSXMLParser *) parser foundCDATA:(NSData *) data
{
	NSXMLNode *n=[[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
	[n setObjectValue:data];
	[self addChild:n];
	[n release];
}

- (void) parser:(NSXMLParser *) parser foundComment:(NSString *) comment
{
	[self addChild:[NSXMLNode commentWithStringValue:comment]];
}

- (void) parser:(NSXMLParser *) parser didStartElement:(NSString *) elementName namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *) attributeDict
{
	NSXMLElement *subNode=[NSXMLElement elementWithName:elementName URI:namespaceURI];
	// what shall we do with the qualified name?
	[subNode setAttributesAsDictionary:attributeDict];
#if 1
	NSLog(@"didStartElement: %@ <%@ %@>", _objectValue, elementName, attributeDict);
	NSLog(@"subNode=%@", subNode);
#endif
	if(_objectValue)
			{ // add any text coming before this subelement
				[self addChild:[NSXMLNode textWithStringValue:_objectValue]];
				[_objectValue release];  
				_objectValue=nil;
			}
	[self addChild:subNode];
	[parser setDelegate:subNode];
}

- (void) parser:(NSXMLParser *) parser didEndElement:(NSString *) elementName namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *) qName
{
#if 1
	NSLog(@"didEndElement: %@ </%@>", _objectValue, elementName);
#endif
	if(_objectValue)
			{ // add any text coming after this subelement
				[self addChild:[NSXMLNode textWithStringValue:_objectValue]];
				[_objectValue release];  
				_objectValue=nil;
			}
	[parser setDelegate:[self parent]];
}

@end
