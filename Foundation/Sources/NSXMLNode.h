/*
    NSXMLNode.h
    Foundation

    Created by H. Nikolaus Schaller on 28.03.08.
    Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/NSObject.h>

@class NSXMLElement;
@class NSXMLDocument;

enum 
{
	NSXMLInvalidKind = 0,
	NSXMLDocumentKind,
	NSXMLElementKind,
	NSXMLAttributeKind,
	NSXMLNamespaceKind,
	NSXMLProcessingInstructionKind,
	NSXMLCommentKind,
	NSXMLTextKind,
	NSXMLDTDKind,
	NSXMLEntityDeclarationKind,
	NSXMLAttributeDeclarationKind,
	NSXMLElementDeclarationKind,
	NSXMLNotationDeclarationKind
};

typedef NSUInteger NSXMLNodeKind;

@interface NSXMLNode : NSObject <NSCopying>
{

}

+ (id) attributeWithName:(NSString *) name stringValue:(NSString *) value;
+ (id) attributeWithName:(NSString *) name URI:(NSString *) uri stringValue:(NSString *) value;
+ (id) commentWithStringValue:(NSString *) value;
+ (id) document;
+ (id) documentWithRootElement:(NSXMLElement *) ele;
+ (id) DTDNodeWithXMLString:(NSString *) str;
+ (id) elementWithName:(NSString *) name;
+ (id) elementWithName:(NSString *) name URI:(NSString *) uri;
+ (id) elementWithName:(NSString *) name stringValue:(NSString *) value;
+ (id) elementWithName:(NSString *) name children:(NSArray *) nodes attributes:(NSArray *) attrs;
+ (NSString *) localNameForName:(NSString *) name;
+ (id) namespaceWithName:(NSString *) name stringValue:(NSString *) value;
+ (NSXMLNode *) predefinedNamespaceForPrefix:(NSString *) prefix;
+ (NSString *) prefixForName:(NSString *) prefix;
+ (id) processingInstructionWithName:(NSString *) name stringValue:(NSString *) value;
+ (id) textWithStringValue:(NSString *) value;

- (id) initWithKind:(NSXMLNodeKind) kind;
- (id) initWithKind:(NSXMLNodeKind) kind options:(NSUInteger) opts;
- (NSXMLNodeKind) kind;
- (void) setName:(NSString *) name;
- (NSString *) name;
- (void) setObjectValue:(id) value;
- (id) objectValue;
- (void) setStringValue:(NSString *) str;
- (void) setStringValue:(NSString *) str resolvingEntities:(BOOL) flag;
- (NSString *) stringValue;
- (NSUInteger) index;
- (NSUInteger) level;
- (NSXMLDocument *) rootDocument;
- (NSXMLNode *) parent;
- (NSUInteger) childCount;
- (NSArray *) children;
- (NSXMLNode *) childAtIndex:(NSUInteger) idx;
- (NSXMLNode *) previousSibling;
- (NSXMLNode *) nextSibling;
- (NSXMLNode *) previousNode;
- (NSXMLNode *) nextNode;
- (void) detach;
- (NSString *) XPath;
- (NSString *) localName;
- (NSString *) prefix;
- (void) setURI:(NSString *) uri;
- (NSString *) URI;
- (NSString *) description;
- (NSString *) XMLString;
- (NSString *) XMLStringWithOptions:(NSUInteger) opts;
- (NSString *) canonicalXMLStringPreservingComments:(BOOL) flag;
- (NSArray *) nodesForXPath:(NSString *) path error:(NSError **) err;
- (NSArray *) objectsForXQuery:(NSString *) query constants:(NSDictionary *) consts error:(NSError **) err;
- (NSArray *) objectsForXQuery:(NSString *) query error:(NSError **) err;

@end
