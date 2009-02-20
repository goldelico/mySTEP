/*
    NSXMLNodeOptions.h
    Foundation

    Created by H. Nikolaus Schaller on 09.02.09.
    Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
 
*/

enum _NSXMLNodeOptions
{
	NSXMLNodeOptionsNone													= 0,
	NSXMLNodeIsCDATA															= (1 << 0),
	NSXMLNodeExpandEmptyElement										= (1 << 1),
	NSXMLNodeCompactEmptyElement									= (1 << 2),
	NSXMLNodeUseSingleQuotes											= (1 << 3),
	NSXMLNodeUseDoubleQuotes											= (1 << 4),
	NSXMLDocumentTidyHTML													= (1 << 9),
	NSXMLDocumentTidyXML													= (1 << 10),
	NSXMLDocumentValidate													= (1 << 13),
	NSXMLDocumentXInclude													= (1 << 16),
	NSXMLNodePrettyPrint													= (1 << 17),
	NSXMLDocumentIncludeContentTypeDeclaration		= (1 << 18),
	NSXMLNodePreserveNamespaceOrder								= (1 << 20),
	NSXMLNodePreserveAttributeOrder								= (1 << 21),
	NSXMLNodePreserveEntities											= (1 << 22),
	NSXMLNodePreservePrefixes											= (1 << 23),
	NSXMLNodePreserveCDATA												= (1 << 24),
	NSXMLNodePreserveWhitespace										= (1 << 25),
	NSXMLNodePreserveDTD													= (1 << 26),
	NSXMLNodePreserveCharacterReferences					= (1 << 27),
	NSXMLNodePreserveEmptyElements								=	(NSXMLNodeExpandEmptyElement | NSXMLNodeCompactEmptyElement),
	NSXMLNodePreserveQuotes												=	(NSXMLNodeUseSingleQuotes | NSXMLNodeUseDoubleQuotes),
	NSXMLNodePreserveAll	= ( NSXMLNodePreserveNamespaceOrder |
													 NSXMLNodePreserveAttributeOrder |
													 NSXMLNodePreserveEntities |
													 NSXMLNodePreservePrefixes |
													 NSXMLNodePreserveCDATA |
													 NSXMLNodePreserveEmptyElements |
													 NSXMLNodePreserveQuotes |
													 NSXMLNodePreserveWhitespace |
													 NSXMLNodePreserveDTD |
													 NSXMLNodePreserveCharacterReferences |
													 0xfff00000 )
};
