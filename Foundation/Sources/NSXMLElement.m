//
//  NSXMLElement.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSPrivate.h"

@implementation NSXMLElement

- (id) init; { return [super initWithKind:NSXMLElementKind]; }
- (id) initWithKind:(NSXMLNodeKind) kind; { return NIMP; }	// NSXMLElement can't be of arbitrary kind (?)
- (id) initWithName:(NSString *) name; { if((self=[self init])) [self setName:name]; return self; }
- (id) initWithName:(NSString *) name URI:(NSString *) uri; { if((self=[self initWithName:name])) [self setURI:uri]; return self; }
- (id) initWithName:(NSString *) name stringValue:(NSString *) value; { if((self=[self initWithName:name])) [self addChild:[NSXMLNode textWithStringValue:value]]; return self; }

- (id) initWithXMLString:(NSString *) string error:(NSError **) err;
{ // this calls the XML parser...
	NSXMLParser *parser=[[NSXMLParser alloc] initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
	if(err) *err=nil;
	[parser setDelegate:self];	// the delegate methods are implemented in our NSXMLNode superclass
	if(![parser parse])
		{
		if(err)
			*err=[parser parserError];
		[parser release];
		[self release];
		return nil;
		}
	[parser release];
	return self;
}

- (void) dealloc
{
	[[_attributes allValues] makeObjectsPerformSelector:@selector(_setParent:) withObject:nil];
	[_attributes release];
	[_namespaces release];
	[super dealloc];
}

- (void) _XMLStringWithOptions:(NSUInteger) opts appendingToString:(NSMutableString	*) str;
{
	int documentKind=[[self rootDocument] documentContentKind];	// Text, XML, XHTML, HTML etc.
	NSEnumerator *c=[[self children] objectEnumerator];
	NSXMLNode *child;
	if([[self children] count] == 0 && (opts&NSXMLNodeCompactEmptyElement) && documentKind != NSXMLDocumentTextKind)
		[str appendFormat:@"<%@/>", _name];	// <tag/>
	else
		{
		if(documentKind != NSXMLDocumentTextKind)
			{
			NSEnumerator *e=[[self attributes] objectEnumerator];
			NSXMLNode *attrib;
			[str appendFormat:@"<%@", _name];
			while((attrib=[e nextObject]))
				{
				[str appendString:@" "];
				[attrib _XMLStringWithOptions:opts appendingToString:str];
				}
			[str appendString:@">"];
			}
		while((child=[c nextObject]))
			[child _XMLStringWithOptions:opts appendingToString:str];
		[str appendFormat:@"</%@>", _name];
		if(opts&(NSXMLDocumentTidyHTML|NSXMLDocumentTidyXML))
			[str appendString:@"\n"];
		}
	}

// should we have mutable dicts for children and attributes?

- (NSArray *) elementsForName:(NSString *) name; { return NIMP; }	// search child by name
- (NSArray *) elementsForLocalName:(NSString *) name URI:(NSString *) uri; { return NIMP; }

- (void) addAttribute:(NSXMLNode *) attr;
{
#if 1
	NSLog(@"addAttribute %@", attr);
#endif
	NSAssert([attr kind] == NSXMLAttributeKind, @"addAttribute: NSXMLNode not an attribute");
	NSAssert(![attr parent], @"addAttribute: NSXMLNode already has a parent");
	if([attr isKindOfClass:[NSXMLElement class]])
		NSLog(@"XML attribute should be NSXMLNode and not NSXMLElement");
	// FIXME: check for duplicates and handle NSXMLPreserveAttributeOrder (needs an NSMutableArray to store the attribute order!)
	// this means: addAttribute simply keeps duplicates and the XML parser handles NSXMLPreserveAttributeOrder and duplicates
	// and scanning through attributes
	if(!_attributes)
		_attributes=[[NSMutableDictionary alloc] initWithCapacity:5];	// rarely more than 5
	[_attributes setObject:attr forKey:[attr name]];
	[attr _setParent:self];
}

- (void) removeAttributeForName:(NSString *) name;
{
	[[_attributes objectForKey:name] setParent:nil];
	[_attributes removeObjectForKey:name];
}

- (void) setAttributes:(NSArray *) attrs;
{
	NSEnumerator *e=[attrs objectEnumerator];
	NSXMLNode *node;
	// remove all existing attributes
	while((node=[e nextObject]))
		[self addAttribute:node];	// does not need to check for duplicates!
}

- (void) setAttributesAsDictionary:(NSDictionary *) attrs;
{
	NSEnumerator *e=[attrs keyEnumerator];
	NSString *key;
	// remove all existing attributes
	while((key=[e nextObject]))
		{
		NSXMLNode *attr=[NSXMLNode attributeWithName:key stringValue:[attrs objectForKey:key]];
		[self addAttribute:attr];
		}
}

- (NSArray *) attributes; { return [_attributes allValues]; }
- (NSXMLNode *) attributeForName:(NSString *) name; { return [_attributes objectForKey:name]; }	// search attribute by name
- (NSXMLNode *) attributeForLocalName:(NSString *) name URI:(NSString *) uri; { return NIMP; }
- (void) addNamespace:(NSXMLNode *) ns; { [_namespaces addObject:ns]; }	// FIXME: check for NSXMLNameSpaceKind and duplicates
- (void) removeNamespaceForPrefix:(NSString *) prefix; { NIMP; }
- (void) setNamespaces:(NSArray *) nspaces; { ASSIGN(_namespaces, nspaces); }	// FIXME: mutable copy?
- (NSArray *) namespaces; { return _namespaces; }
- (NSXMLNode *) namespaceForPrefix:(NSString *) prefix; { return NIMP; }
- (NSXMLNode *) resolveNamespaceForName:(NSString *) name; { return NIMP; }
- (NSString *) resolvePrefixForNamespaceURI:(NSString *) nsUri; { return NIMP; }

- (void) normalizeAdjacentTextNodesPreservingCDATA:(BOOL) flag;
{
	NIMP;
}

/* implemented in superclass
 
 - (void) insertChild:(NSXMLNode *) node atIndex:(NSUInteger) idx; {}
 - (void) insertChildren:(NSArray *) nodes atIndex:(NSUInteger) idx; {}
 (void) removeChildAtIndex:(NSUInteger) idx; {}
 - (void) setChildren:(NSArray *) nodes; {}
 - (void) addChild:(NSXMLNode *) node; {}
 - (void) replaceChildAtIndex:(NSUInteger) idx withNode:(NSXMLNode *) node; {}
 */

@end
