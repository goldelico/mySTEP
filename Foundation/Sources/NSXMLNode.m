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
+ (id) DTDNodeWithXMLString:(NSString *) str; { NSXMLNode *n=[[[self alloc] initWithKind:NSXMLDTDKind] autorelease]; [n setStringValue:str]; return n; }
+ (id) document; { return [[[NSXMLDocument alloc] initWithKind:NSXMLDocumentKind] autorelease]; }
+ (id) documentWithRootElement:(NSXMLElement *) ele; { return [[[NSXMLDocument alloc] initWithRootElement:ele] autorelease]; }
+ (id) elementWithName:(NSString *) name; { return [[[NSXMLElement alloc] initWithName:name] autorelease]; }
+ (id) elementWithName:(NSString *) name URI:(NSString *) uri; { return [[[NSXMLElement alloc] initWithName:name URI:uri] autorelease]; }
+ (id) elementWithName:(NSString *) name stringValue:(NSString *) value; { return [[[NSXMLElement alloc] initWithName:name stringValue:value] autorelease]; }
+ (id) namespaceWithName:(NSString *) name stringValue:(NSString *) value; { NSXMLNode *n=[[[self alloc] initWithKind:NSXMLNamespaceKind] autorelease]; [n setStringValue:value]; return n; }
+ (id) processingInstructionWithName:(NSString *) name stringValue:(NSString *) value; { NSXMLNode *n=[[[self alloc] initWithKind:NSXMLProcessingInstructionKind] autorelease]; [n setStringValue:value]; return n; }
+ (id) textWithStringValue:(NSString *) value; { NSXMLNode *n=[[[self alloc] initWithKind:NSXMLTextKind] autorelease]; [n setStringValue:value]; return n; }

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

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ %@ %d", NSStringFromClass([self class]), _name, _kind];
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

/*
 - (NSString *) XPath; { return NIMP; }
 - (NSArray *) nodesForXPath:(NSString *) path error:(NSError **) err;
 - (NSArray *) objectsForXQuery:(NSString *) query constants:(NSDictionary *) consts error:(NSError **) err;
 - (NSArray *) objectsForXQuery:(NSString *) query error:(NSError **) err;
*/

/* methods implemented here but not in header file */

// FIXME: handle parent pointer!

- (void) insertChild:(NSXMLNode *) node atIndex:(NSUInteger) idx; { if(!_children) _children=[[NSMutableArray alloc] initWithCapacity:5]; [_children insertObject:node atIndex:idx]; }
- (void) insertChildren:(NSArray *) nodes atIndex:(NSUInteger) idx; { if(!_children) _children=[[NSMutableArray alloc] initWithCapacity:[nodes count]+3]; [_children insertObjects:nodes atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx, [nodes count])]]; }
- (void) removeChildAtIndex:(NSUInteger) idx; { [_children removeObjectAtIndex:idx]; }
- (void) setChildren:(NSArray *) nodes; { ASSIGN(_children, nodes); }
- (void) addChild:(NSXMLNode *) node; { [self insertChild:node atIndex:[_children count]]; }
- (void) replaceChildAtIndex:(NSUInteger) idx withNode:(NSXMLNode *) node; { [_children replaceObjectAtIndex:idx withObject:node]; }

@end
