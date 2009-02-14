/*
    NSXMLDTD.h
    Foundation
 
    Created by H. Nikolaus Schaller on 28.03.08.
    Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/NSXMLNode.h>

enum 
{
	NSXMLEntityGeneralKind = 1,
	NSXMLEntityParsedKind,
	NSXMLEntityUnparsedKind,
	NSXMLEntityParameterKind,
	NSXMLEntityPredefined,
	NSXMLAttributeCDATAKind,
	NSXMLAttributeIDKind,
	NSXMLAttributeIDRefKind,
	NSXMLAttributeIDRefsKind,
	NSXMLAttributeEntityKind,
	NSXMLAttributeEntitiesKind,
	NSXMLAttributeNMTokenKind,
	NSXMLAttributeNMTokensKind,
	NSXMLAttributeEnumerationKind,
	NSXMLAttributeNotationKind,
	NSXMLElementDeclarationUndefinedKind,
	NSXMLElementDeclarationEmptyKind,
	NSXMLElementDeclarationAnyKind,
	NSXMLElementDeclarationMixedKind,
	NSXMLElementDeclarationElementKind
};

typedef NSUInteger NSXMLDTDNodeKind;

@interface NSXMLDTDNode : NSXMLNode
{
	NSString *_publicID;
	NSString *_systemID;
	NSString *_notationName;	
	NSXMLDTDNodeKind _DTDKind;
}

- (id) initWithXMLString:(NSString *) xmlStr;
- (void) setDTDKind:(NSXMLDTDNodeKind) kind;
- (NSXMLDTDNodeKind) DTDKind;
- (BOOL) isExternal;
- (void) setPublicID:(NSString *) pubId;
- (NSString *) publicID;
- (void) setSystemID:(NSString *) sysId;
- (NSString *) systemID;
- (void) setNotationName:(NSString *) name;
- (NSString *) notationName;

@end
