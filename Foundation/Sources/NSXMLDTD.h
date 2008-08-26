/*
    NSXMLDTD.h
    Foundation

    Created by H. Nikolaus Schaller on 28.03.08.
    Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/NSXMLNode.h>

@class NSData;
@class NSURL;
@class NSXMLDTDNode;

@interface NSXMLDTD : NSXMLNode
{
	NSString *_publicID;
	NSString *_systemID;
	// declarations...
}

+ (NSXMLDTDNode *) predefinedEntityDeclarationForName:(NSString *) name;

- (id) initWithContentsOfURL:(NSURL *) url options:(NSUInteger) optsMask error:(NSError **) err;
- (id) initWithData:(NSData *) data options:(NSUInteger) optsMask error:(NSError **) err;
- (void) setPublicID:(NSString *) pubId;
- (NSString *) publicID;
- (void) setSystemID:(NSString *) sysId;
- (NSString *) systemID;
- (NSXMLDTDNode *) entityDeclarationForName:(NSString *) enityName;
- (NSXMLDTDNode *) notationDeclarationForName:(NSString *) notationName;
- (NSXMLDTDNode *) elementDeclarationForName:(NSString *) elementName;
- (NSXMLDTDNode *) attributeDeclarationForName:(NSString *) attributeName elementName:(NSString *) eleName;

@end

@interface NSXMLDTD (NSXMLNode)

- (void) insertChild:(NSXMLNode *) node atIndex:(NSUInteger) idx;
- (void) insertChildren:(NSArray *) nodes atIndex:(NSUInteger) idx;
- (void) removeChildAtIndex:(NSUInteger) idx;
- (void) setChildren:(NSArray *) nodes;
- (void) addChild:(NSXMLNode *) node;
- (void) replaceChildAtIndex:(NSUInteger) idx withNode:(NSXMLNode *) node;

@end
