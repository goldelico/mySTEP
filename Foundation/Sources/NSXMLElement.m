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
- (id) initWithName:(NSString *) name URI:(NSString *) uri; { self=[self initWithKind:NSXMLElementKind]; [self setURI:uri]; return self; }
- (id) initWithName:(NSString *) name stringValue:(NSString *) value; { self=[self initWithName:name]; if(self) [self addChild:[NSXMLNode textWithStringValue:value]]; return self; }

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

// FIXME: handle parent pointer!

// implemented in superclass

- (void) insertChild:(NSXMLNode *) node atIndex:(NSUInteger) idx; { if(!_children) _children=[[NSMutableArray alloc] initWithCapacity:5]; [_children insertObject:node atIndex:idx]; }
- (void) insertChildren:(NSArray *) nodes atIndex:(NSUInteger) idx; { if(!_children) _children=[[NSMutableArray alloc] initWithCapacity:[nodes count]+3]; [_children insertObjects:nodes atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx, [nodes count])]]; }
- (void) removeChildAtIndex:(NSUInteger) idx; { [_children removeObjectAtIndex:idx]; }
- (void) setChildren:(NSArray *) nodes; { ASSIGN(_children, nodes); }
- (void) addChild:(NSXMLNode *) node; { [self insertChild:node atIndex:[_children count]]; }
- (void) replaceChildAtIndex:(NSUInteger) idx withNode:(NSXMLNode *) node; { [_children replaceObjectAtIndex:idx withObject:node]; }

/* NIMP
 
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
- (NSXMLNode *) resolveNamespaceForName:(NSString *) name;
- (NSString *) resolvePrefixForNamespaceURI:(NSString *) nsUri;
- (void) normalizeAdjacentTextNodesPreservingCDATA:(BOOL) flag;
*/

@end
