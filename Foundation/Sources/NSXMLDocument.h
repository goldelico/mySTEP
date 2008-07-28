/*
    NSXMLDocument.h
    Foundation

    Created by H. Nikolaus Schaller on 28.03.08.
    Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/NSXMLNode.h>

@class NSData;
@class NSURL;
@class NSXMLDTD;

enum 
{
	NSXMLDocumentXMLKind = 0,
	NSXMLDocumentXHTMLKind = 1,
	NSXMLDocumentHTMLKind = 2,
	NSXMLDocumentTextKind = 3
};

typedef NSUInteger NSXMLDocumentContentKind;

@interface NSXMLDocument : NSXMLNode
{
	NSString *_characterEncoding;
	NSXMLDTD *_DTD;
	NSString *_MIMEType;
	NSXMLElement *_rootElement;
	NSString *_version;
	BOOL _isStandalone;
	NSXMLDocumentContentKind _documentContentKind;
}

+ (Class) replacementClassForClass:(Class) class;

- (void) addChild:(NSXMLNode *) node;
- (NSString *) characterEncoding;
- (NSXMLDocumentContentKind) documentContentKind;
- (NSXMLDTD *) DTD;
- (id) initWithContentsOfURL:(NSURL *) url options:(NSUInteger) optsMask error:(NSError **) err;
- (id) initWithData:(NSData *) data options:(NSUInteger) optsMask error:(NSError **) err;
- (id) initWithRootElement:(NSXMLElement *) rootNode;
- (id) initWithXMLString:(NSString *) str options:(NSUInteger) optsMask error:(NSError **) err;
- (void) insertChild:(NSXMLNode *) node atIndex:(NSUInteger) idx;
- (void) insertChildren:(NSArray *) nodes atIndex:(NSUInteger) idx;
- (BOOL) isStandalone;
- (NSString *) MIMEType;
- (id) objectByApplyingXSLT:(NSData *) data arguments:(NSDictionary *) args error:(NSError **) err;
- (id) objectByApplyingXSLTAtURL:(NSURL *) url arguments:(NSDictionary *) args error:(NSError **) err;
- (id) objectByApplyingXSLTString:(NSString *) str arguments:(NSDictionary *) args error:(NSError **) err;
- (void) removeChildAtIndex:(NSUInteger) idx;
- (void) replaceChildAtIndex:(NSUInteger) idx withNode:(NSXMLNode *) node;
- (NSXMLElement *) rootElement;
- (void) setCharacterEncoding:(NSString *) str;
- (void) setChildren:(NSArray *) nodes;
- (void) setDocumentContentKind:(NSXMLDocumentContentKind) kind;
- (void) setDTD:(NSXMLDTD *) dtd;
- (void) setMIMEType:(NSString *) mime;
- (void) setRootElement:(NSXMLNode *) rootNode;
- (void) setStandalone:(BOOL) flag;
- (void) setURI:(NSString *) uri;
- (void) setVersion:(NSString *) version;
- (NSString *) URI;
- (BOOL) validateAndReturnError:(NSError **) err;
- (NSString *) version;
- (NSData *) XMLData;
- (NSData *) XMLDataWithOptions:(NSUInteger) opts;

@end
