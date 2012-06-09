//
//  NSXMLDTD.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>


@implementation NSXMLDTD

+ (NSXMLDTDNode *) predefinedEntityDeclarationForName:(NSString *) name;
{
	NSXMLDTDNode *node=[[NSXMLDTDNode alloc] initWithKind:NSXMLEntityDeclarationKind options:0];
	[node setNotationName:name];
	[node setDTDKind:NSXMLEntityPredefined];
	return [node autorelease];
}

- (id) initWithContentsOfURL:(NSURL *) url options:(NSUInteger) optsMask error:(NSError **) err;
{
	// this blocks until url has been loaded - should we postpone loading until we try to access this DTD?
	return [self initWithData:[NSData dataWithContentsOfURL:url] options:optsMask error:err];
}

- (id) initWithData:(NSData *) data options:(NSUInteger) optsMask error:(NSError **) err;
{
	if((self=[self initWithKind:NSXMLDTDKind options:0]))
			{
	/* parse DTD from data
	 * i.e. generate subnodes of type
	 * XMLDTDNode
	 * comments
	 * + processing instructions
	 */
			}
	return self;
}

- (void) dealloc
{
	[_publicID release];
	[_systemID release];
	[super dealloc];
}

- (void) setPublicID:(NSString *) pubId; { ASSIGN(_publicID, pubId); }
- (NSString *) publicID; { return _publicID; }
- (void) setSystemID:(NSString *) sysId; { ASSIGN(_systemID, sysId); }
- (NSString *) systemID; { return _systemID; }

- (NSXMLDTDNode *) entityDeclarationForName:(NSString *) enityName;
{
	// search in children
	return NIMP;
}

- (NSXMLDTDNode *) notationDeclarationForName:(NSString *) notationName;
{
	// search in children
	return NIMP;
}

- (NSXMLDTDNode *) elementDeclarationForName:(NSString *) elementName;
{
	// search in children
	return NIMP;
}

- (NSXMLDTDNode *) attributeDeclarationForName:(NSString *) attributeName elementName:(NSString *) eleName;
{
	// search in children
	return NIMP;
}

/* should check for valid subnodes
- (void) insertChild:(NSXMLNode *) node atIndex:(NSUInteger) idx; { if(!_children) _children=[[NSMutableArray alloc] initWithCapacity:5]; [_children insertObject:node atIndex:idx]; }
- (void) insertChildren:(NSArray *) nodes atIndex:(NSUInteger) idx; { if(!_children) _children=[[NSMutableArray alloc] initWithCapacity:[nodes count]+3]; [_children insertObjects:nodes atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx, [nodes count])]]; }
- (void) removeChildAtIndex:(NSUInteger) idx; { [_children removeObjectAtIndex:idx]; }
- (void) setChildren:(NSArray *) nodes; { ASSIGN(_children, nodes); }
- (void) addChild:(NSXMLNode *) node; { [self insertChild:node atIndex:[_children count]]; }
- (void) replaceChildAtIndex:(NSUInteger) idx withNode:(NSXMLNode *) node; { [_children replaceObjectAtIndex:idx withObject:node]; }
*/

@end
