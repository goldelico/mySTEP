//
//  NSXMLElement.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>


@implementation NSXMLElement

- (id) initWithName:(NSString *) name; { return [self initWithName:name URI:nil]; } 
- (id) initWithName:(NSString *) name URI:(NSString *) uri; { if((self=[self initWithKind:NSXMLElementKind])) { [self setName:name]; [self setURI:uri]; } return self; }
- (id) initWithName:(NSString *) name stringValue:(NSString *) value; { if((self=[self initWithName:name])) [self addChild:[NSXMLNode textWithStringValue:value]]; return self; }

- (id) initWithXMLString:(NSString *) string error:(NSError **) err;
{ // this calls the XML parser...
	NSXMLParser *parser=[[NSXMLParser alloc] initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
	if(err) *err=nil;
	[parser setDelegate:self];
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
	[_children release];
	[_namespaces release];
	[super dealloc];
}

- (NSString *) _descriptionTag;
{
	// show attributes
	if(_name)
		return [NSString stringWithFormat:@"<%@ %@ %d>%@\n", _name, NSStringFromClass([self class]), _kind, _objectValue?_objectValue:@""];
	return [NSString stringWithFormat:@"<%@ %d>%@\n", NSStringFromClass([self class]), _kind, _objectValue?_objectValue:@""];
}

// should we have mutable dicts for children and attributes?

- (NSArray *) elementsForName:(NSString *) name; { return NIMP; }	// search child by name
- (NSArray *) elementsForLocalName:(NSString *) name URI:(NSString *) uri; { return NIMP; }
- (void) addAttribute:(NSXMLNode *) attr; { [_attributes setObject:attr forKey:[attr name]]; } // FIXME: check for duplicates and handle NSXMLPreserveAttributeOrder (needs an NSArray to store the attribute order!)
- (void) removeAttributeForName:(NSString *) name; { [_attributes removeObjectForKey:name]; }

- (void) setAttributes:(NSArray *) attrs;
{
	NSEnumerator *e=[attrs objectEnumerator];
	NSXMLNode *node;
	// remove all attributes
	while((node=[e nextObject]))
		[self addAttribute:node];	// does not need to check for duplicates!
}

- (void) setAttributesAsDictionary:(NSDictionary *) attrs;
{
	NSEnumerator *e=[attrs keyEnumerator];
	NSString *key;
	// remove all attributes
	while((key=[e nextObject]))
			{
				NSXMLNode *attr=[[NSXMLNode alloc] initWithKind:NSXMLAttributeKind];
				[attr setName:key];
				[attr setObjectValue:[attrs objectForKey:key]];
				[self addAttribute:attr];
				[attr release];
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
