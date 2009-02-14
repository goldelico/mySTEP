//
//  NSXMLDTDNode.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>


@implementation NSXMLDTDNode

- (id) initWithXMLString:(NSString *) xmlStr;
{
	// parse DTD XML
	if((self=[self initWithKind:NSXMLEntityDeclarationKind options:0]))
			{
				// FIXME;
			}
	return self;
}

- (void) dealloc
{
	[_publicID release];
	[_systemID release];
	[_notationName release];
	[super dealloc];
}

- (NSString *) _descriptionTag;
{
	return [super _descriptionTag];
}

- (void) setDTDKind:(NSXMLDTDNodeKind) kind; { _DTDKind=kind; }
- (NSXMLDTDNodeKind) DTDKind; { return _DTDKind; }
- (BOOL) isExternal; { return [_systemID length] != 0; }
- (void) setPublicID:(NSString *) pubId; { ASSIGN(_publicID, pubId); }
- (NSString *) publicID; { return _publicID; }
- (void) setSystemID:(NSString *) sysId; { ASSIGN(_systemID, sysId); }
- (NSString *) systemID; { return _systemID; }
- (void) setNotationName:(NSString *) name; { ASSIGN(_notationName, name); }
- (NSString *) notationName; { return _notationName; }

@end
