/*
 NSXMLElement.h
 Foundation
 
 Created by H. Nikolaus Schaller on 28.03.08.
 Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
 
 Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 */

#import <Foundation/NSXMLNode.h>

@class NSMutableArray;
@class NSMutableDictionary;

@interface NSXMLElement : NSXMLNode
{
	NSMutableDictionary *_attributes;	// map name to attributes (XMLNode)
	NSMutableArray *_namespaces;
}

- (id) initWithName:(NSString *) name;
- (id) initWithName:(NSString *) name URI:(NSString *) uri;
- (id) initWithName:(NSString *) name stringValue:(NSString *) value;
- (id) initWithXMLString:(NSString *) string error:(NSError **) err;
- (NSArray *) elementsForName:(NSString *) name;
- (NSArray *) elementsForLocalName:(NSString *) name URI:(NSString *) uri;
- (void) addAttribute:(NSXMLNode *) attr;
- (void) removeAttributeForName:(NSString *) name;
- (void) setAttributes:(NSArray *) attrs;
- (void) setAttributesAsDictionary:(NSDictionary *) attrs;
- (NSArray *) attributes;
- (NSXMLNode *) attributeForName:(NSString *) name;
- (NSXMLNode *) attributeForLocalName:(NSString *) name URI:(NSString *) uri;
- (void) addNamespace:(NSXMLNode *) ns;
- (void) removeNamespaceForPrefix:(NSString *) prefix;
- (void) setNamespaces:(NSArray *) nspaces;
- (NSArray *) namespaces;
- (NSXMLNode *) namespaceForPrefix:(NSString *) prefix;
- (void) normalizeAdjacentTextNodesPreservingCDATA:(BOOL) flag;
- (NSXMLNode *) resolveNamespaceForName:(NSString *) name;
- (NSString *) resolvePrefixForNamespaceURI:(NSString *) nsUri;

@end

@interface NSXMLElement (NSXMLNode)

- (void) insertChild:(NSXMLNode *) node atIndex:(NSUInteger) idx;
- (void) insertChildren:(NSArray *) nodes atIndex:(NSUInteger) idx;
- (void) removeChildAtIndex:(NSUInteger) idx;
- (void) setChildren:(NSArray *) nodes;
- (void) addChild:(NSXMLNode *) node;
- (void) replaceChildAtIndex:(NSUInteger) idx withNode:(NSXMLNode *) node;

@end
