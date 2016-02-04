/* simplewebkit
   NSXMLParser.h

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author: Dr. H. Nikolaus Schaller

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#ifndef mySTEP_NSXMLPARSER_H
#define mySTEP_NSXMLPARSER_H

#import "Foundation/Foundation.h"

#ifndef __WebKit__	// may be #included in WebKit sources where this is already declared

extern NSString *const NSXMLParserErrorDomain;

typedef enum _NSXMLParserError
{
	NSXMLParserInternalError=1,
	NSXMLParserOutOfMemoryError,
	NSXMLParserDocumentStartError,
	NSXMLParserEmptyDocumentError,
	NSXMLParserPrematureDocumentEndError,
	NSXMLParserInvalidHexCharacterRefError,
	NSXMLParserInvalidDecimalCharacterRefError,
	NSXMLParserInvalidCharacterRefError,
	NSXMLParserInvalidCharacterError,
	NSXMLParserCharacterRefAtEOFError,
	NSXMLParserCharacterRefInPrologError,
	NSXMLParserCharacterRefInEpilogError,
	NSXMLParserCharacterRefInDTDError,
	NSXMLParserEntityRefAtEOFError,
	NSXMLParserEntityRefInPrologError,
	NSXMLParserEntityRefInEpilogError,
	NSXMLParserEntityRefInDTDError,
	NSXMLParserParsedEntityRefAtEOFError,
	NSXMLParserParsedEntityRefInPrologError,
	NSXMLParserParsedEntityRefInEpilogError,
	NSXMLParserParsedEntityRefInInternalSubsetError,
	NSXMLParserEntityReferenceWithoutNameError,
	NSXMLParserEntityReferenceMissingSemiError,
	NSXMLParserParsedEntityRefNoNameError,
	NSXMLParserParsedEntityRefMissingSemiError,
	NSXMLParserUndeclaredEntityError,
	NSXMLParserUnparsedEntityError,
	NSXMLParserEntityIsExternalError,
	NSXMLParserEntityIsParameterError,
	NSXMLParserUnknownEncodingError,
	NSXMLParserEncodingNotSupportedError,
	NSXMLParserStringNotStartedError,
	NSXMLParserStringNotClosedError,
	NSXMLParserNamespaceDeclarationError,
	NSXMLParserEntityNotStartedError,
	NSXMLParserEntityNotFinishedError,
	NSXMLParserLessThanSymbolInAttributeError,
	NSXMLParserAttributeNotStartedError,
	NSXMLParserAttributeNotFinishedError,
	NSXMLParserAttributeHasNoValueError,
	NSXMLParserAttributeRedefinedError,
	NSXMLParserLiteralNotStartedError,
	NSXMLParserLiteralNotFinishedError,
	NSXMLParserCommentNotFinishedError,
	NSXMLParserProcessingInstructionNotStartedError,
	NSXMLParserProcessingInstructionNotFinishedError,
	NSXMLParserNotationNotStartedError,
	NSXMLParserNotationNotFinishedError,
	NSXMLParserAttributeListNotStartedError,
	NSXMLParserAttributeListNotFinishedError,
	NSXMLParserMixedContentDeclNotStartedError,
	NSXMLParserMixedContentDeclNotFinishedError,
	NSXMLParserElementContentDeclNotStartedError,
	NSXMLParserElementContentDeclNotFinishedError,
	NSXMLParserXMLDeclNotStartedError,
	NSXMLParserXMLDeclNotFinishedError,
	NSXMLParserConditionalSectionNotStartedError,
	NSXMLParserConditionalSectionNotFinishedError,
	NSXMLParserExternalSubsetNotFinishedError,
	NSXMLParserDOCTYPEDeclNotFinishedError,
	NSXMLParserMisplacedCDATAEndStringError,
	NSXMLParserCDATANotFinishedError,
	NSXMLParserMisplacedXMLDeclarationError,
	NSXMLParserSpaceRequiredError,
	NSXMLParserSeparatorRequiredError,
	NSXMLParserNMTOKENRequiredError,
	NSXMLParserNAMERequiredError,
	NSXMLParserPCDATARequiredError,
	NSXMLParserURIRequiredError,
	NSXMLParserPublicIdentifierRequiredError,
	NSXMLParserLTRequiredError,
	NSXMLParserGTRequiredError,
	NSXMLParserLTSlashRequiredError,
	NSXMLParserEqualExpectedError,
	NSXMLParserTagNameMismatchError,
	NSXMLParserUnfinishedTagError,
	NSXMLParserStandaloneValueError,
	NSXMLParserInvalidEncodingNameError,
	NSXMLParserCommentContainsDoubleHyphenError,
	NSXMLParserInvalidEncodingError,
	NSXMLParserExternalStandaloneEntityError,
	NSXMLParserInvalidConditionalSectionError,
	NSXMLParserEntityValueRequiredError,
	NSXMLParserNotWellBalancedError,
	NSXMLParserExtraContentError,
	NSXMLParserInvalidCharacterInEntityError,
	NSXMLParserParsedEntityRefInInternalError,
	NSXMLParserEntityRefLoopError,
	NSXMLParserEntityBoundaryError,
	NSXMLParserInvalidURIError,
	NSXMLParserURIFragmentError,
	NSXMLParserNoDTDError,
	NSXMLParserDelegateAbortedParseError=512
} NSXMLParserError;

#endif

// this is a private extension

typedef enum _NSXMLParserReadMode
{
	_NSXMLParserStandardReadMode,	// decode embedded tags
	_NSXMLParserPlainReadMode,		// read characters (even entities) as they are until we find a closing tag: e.g. <script>...</script>
	_NSXMLParserEntityOnlyReadMode,	// read characters until we find a matching closing tag but still translate entities: e.g. <pre>...</pre>
} _NSXMLParserReadMode;

@interface NSXMLParser : NSObject
{
	id delegate;					// the current delegate (not retained)
	NSMutableArray *tagPath;		// hierarchy of tags
	NSError *error;					// will also abort parsing process
	NSData *data;					// if initialized with initWithData:
	NSURL *url;						// if initialized with initWithContentsOfURL:
	NSData *buffer;					// buffer
	const char *cp;					// pointer into current buffer
	int line;						// current line (counts from 0)
	int column;						// current column (counts from 0)
	NSStringEncoding encoding;		// current read mode
	_NSXMLParserReadMode readMode;
	BOOL isStalled;					// queue up incoming NSData and don't call delegate methods
	BOOL done;						// done with incremental input
	BOOL shouldProcessNamespaces;
	BOOL shouldReportNamespacePrefixes;
	BOOL shouldResolveExternalEntities;
	BOOL acceptHTML;				// be lazy with bad tag nesting and be not case sensitive
}

- (void) abortParsing;
- (int) columnNumber;
- (id) delegate;
- (id) initWithContentsOfURL:(NSURL *) url;
- (id) initWithData:(NSData *) str;
- (int) lineNumber;
- (BOOL) parse;
- (NSError *) parserError;
- (NSString *) publicID;
- (void) setDelegate:(id) del;
- (void) setShouldProcessNamespaces:(BOOL) flag;
- (void) setShouldReportNamespacePrefixes:(BOOL) flag;
- (void) setShouldResolveExternalEntities:(BOOL) flag;
- (BOOL) shouldProcessNamespaces;
- (BOOL) shouldReportNamespacePrefixes;
- (BOOL) shouldResolveExternalEntities;
- (NSString *) systemID;

@end

@interface NSObject (NSXMLParserDelegate)

- (void) parser:(NSXMLParser *) parser didEndElement:(NSString *) tag namespaceURI:(NSString *) URI qualifiedName:(NSString *) name;
- (void) parser:(NSXMLParser *) parser didEndMappingPrefix:(NSString *) prefix;
- (void) parser:(NSXMLParser *) parser didStartElement:(NSString *) tag namespaceURI:(NSString *) URI qualifiedName:(NSString *) name attributes:(NSDictionary *) attributes;
- (void) parser:(NSXMLParser *) parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *) URI;
- (void) parser:(NSXMLParser *) parser foundAttributeDeclarationWithName:(NSString *) name forElement:(NSString *) element type:(NSString *) type defaultValue:(NSString *) val;
- (void) parser:(NSXMLParser *) parser foundCDATA:(NSData *) CDATABlock;
- (void) parser:(NSXMLParser *) parser foundCharacters:(NSString *) string;
- (void) parser:(NSXMLParser *) parser foundComment:(NSString *) comment;
- (void) parser:(NSXMLParser *) parser foundElementDeclarationWithName:(NSString *) element model:(NSString *) model;
- (void) parser:(NSXMLParser *) parser foundExternalEntityDeclarationWithName:(NSString *) entity publicID:(NSString *) pub systemID:(NSString *) sys;
- (void) parser:(NSXMLParser *) parser foundIgnorableWhitespace:(NSString *) whitespaceString;
- (void) parser:(NSXMLParser *) parser foundInternalEntityDeclarationWithName:(NSString *) name value:(NSString *) val;
- (void) parser:(NSXMLParser *) parser foundNotationDeclarationWithName:(NSString *) name publicID:(NSString *) pub systemID:(NSString *) sys;
- (void) parser:(NSXMLParser *) parser foundProcessingInstructionWithTarget:(NSString *) target data:(NSString *) data;
- (void) parser:(NSXMLParser *) parser foundUnparsedEntityDeclarationWithName:(NSString *) name publicID:(NSString *) pub systemID:(NSString *) sys notationName:(NSString *) notation;
- (void) parser:(NSXMLParser *) parser parseErrorOccurred:(NSError *) parseError;
- (NSData *) parser:(NSXMLParser *) parser resolveExternalEntityName:(NSString *) entity systemID:(NSString *) sys;
- (void) parser:(NSXMLParser *) parser validationErrorOccurred:(NSError *) error;
- (void) parserDidEndDocument:(NSXMLParser *) parser;
- (void) parserDidStartDocument:(NSXMLParser *) parser;

@end

#endif
