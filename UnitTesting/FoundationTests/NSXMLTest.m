//
//  NSXMLTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 09.06.19.
//
//

#import <XCTest/XCTest.h>

@interface NSXMLTest : XCTestCase
{
	NSXMLDocument *doc;
	NSString *str;
	NSMutableDictionary *result;
}

@end

@implementation NSXMLTest

- (void) setUp
{
	result=[[NSMutableDictionary alloc] initWithCapacity:10];
	[super setUp];
	str=@"<?xml version=\"1.0\" encoding=\"UTF8\"?><SMARTPLUG id=\"letux\"><CMD id=\"get\"><Device.System.Power.State/></CMD></SMARTPLUG>";
	doc=[[NSXMLDocument alloc] initWithXMLString:str options:0 error:NULL];
}

- (void) tearDown
{
	[doc release];
	[super tearDown];
}

- (void) test1
{ // setup did not fail
	XCTAssertNotNil(doc);
	XCTAssertNotNil([doc rootElement]);

}

- (void) test10
{ // general properties of NSXMLDocument
	XCTAssertEqualObjects([doc version], @"1.0");
	XCTAssertEqualObjects([doc characterEncoding], @"UTF8");
	XCTAssertTrue([doc rootDocument] == doc);
	XCTAssertTrue([doc childCount] == 1);
	XCTAssertTrue([doc rootElement] == [doc childAtIndex:0]);
}

- (void) test20
{ // tree hierarchy first level
	NSXMLNode *n=[doc rootElement];
	XCTAssertEqualObjects([n name], @"SMARTPLUG");
	XCTAssertTrue([n parent] == doc);

}

- (void) test21
{ // tree hierarchy second level
	NSXMLNode *n=[doc rootElement], *n2;
	n2=[n childAtIndex:0];
	XCTAssertEqualObjects([n2 name], @"CMD");
	XCTAssertTrue([n2 parent] == n);
}

- (void) test30
{
	NSXMLElement *n=[doc rootElement];
	NSXMLElement *e=[NSXMLElement elementWithName:@"test" stringValue:@"value"];
	[n addChild:e];
	// test rig broken on mySTEP...	XCTAssertThrows([n addChild:e]);	// trying to add a second time
}

// demonstrate adding/deleting children - should raise exception if child already has a parent
// demonstrate moving nodes from one subtree to the other

- (void) test40
{ // expansion into string
	NSString *wants=@"<?xml version=\"1.0\" encoding=\"UTF8\" standalone=\"yes\"?><SMARTPLUG id=\"letux\"><CMD id=\"get\"><Device.System.Power.State></Device.System.Power.State></CMD></SMARTPLUG>";
	XCTAssertEqualObjects([doc XMLString], wants);	// default of standalone if not given in <?xml?> is "yes"
	// try encoding with options
}

- (void) test41
{ // without <?xml>
	NSString *s=@"<SMARTPLUG id=\"letux\"><CMD id=\"get\"><Device.System.Power.State/></CMD></SMARTPLUG>";
	NSXMLDocument *d=[[[NSXMLDocument alloc] initWithXMLString:s options:0 error:NULL] autorelease];
	NSString *wants=@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><SMARTPLUG id=\"letux\"><CMD id=\"get\"><Device.System.Power.State></Device.System.Power.State></CMD></SMARTPLUG>";
	XCTAssertEqualObjects([d XMLString], wants);
	/* this differs between Cocoa and mySTEP
	 * Cocoa leaves it upper case while mySTEP treats this as a html document and converts all tags to lower case
	 */
}

- (void) test42
{ // with html
	NSString *s=@"<head><title>test</title></head><body>OK</body>";
	NSXMLDocument *d;
	NSString *wants;
	d=[[[NSXMLDocument alloc] initWithXMLString:s options:0 error:NULL] autorelease];
	XCTAssertNil(d);	// not parsed
	d=[[[NSXMLDocument alloc] initWithXMLString:s options:NSXMLDocumentTidyHTML error:NULL] autorelease];
	wants=@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\"><head><title>test</title></head><body>OK</body></html>";
#if 0
	NSLog(@"%@", [[d XMLString] dataUsingEncoding:NSUTF8StringEncoding]);
	NSLog(@"%@", [wants dataUsingEncoding:NSUTF8StringEncoding]);
#endif
	XCTAssertEqualObjects([d XMLString], wants);
	s=@"<h1>OK</h1>";	// very simple html without <html> tag
	d=[[[NSXMLDocument alloc] initWithXMLString:s options:NSXMLDocumentTidyHTML error:NULL] autorelease];
	wants=@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><h1>OK</h1>";
	XCTAssertEqualObjects([d XMLString], wants);
}

- (void) test43
{ // manual init - find out when and which xml header is printed
	NSXMLDocument *d=[[[NSXMLDocument alloc] init] autorelease];
	XCTAssertTrue([d documentContentKind] == NSXMLDocumentXMLKind);	// 0
	XCTAssertNil([d version]);
	XCTAssertNil([d characterEncoding]);
	XCTAssertFalse([d isStandalone]);
	XCTAssertEqualObjects([d XMLString], @"");	// but not printed!
	[d setCharacterEncoding:@"UTF9"];	// unless we modify the object
	XCTAssertEqualObjects([d XMLString], @"<?xml version=\"1.0\" encoding=\"UTF9\" standalone=\"no\"?>");	// default of  [NSXMLDocument init] is standalone "no"
	XCTAssertNil([d version]);	// version="1.0" is just a default for printing
	[d setCharacterEncoding:nil];	// back to default
	XCTAssertEqualObjects([d XMLString], @"");
	[d setVersion:@"1.1"];	// unless we modify the object
	XCTAssertEqualObjects([d XMLString], @"<?xml version=\"1.1\" standalone=\"no\"?>");	// encoding can be omitted
	[d setStandalone:YES];
	XCTAssertTrue([d isStandalone]);
	XCTAssertEqualObjects([d XMLString], @"<?xml version=\"1.1\" standalone=\"yes\"?>");	// standalone is always present
	[d setVersion:nil];	// back to default
	XCTAssertEqualObjects([d XMLString], @"<?xml version=\"1.0\" standalone=\"yes\"?>");	// standalone is always present
	[d setStandalone:NO];
	XCTAssertEqualObjects([d XMLString], @"");	// no xml header if there is neither version, nor encoding nor standalone
	[d setRootElement:[NSXMLElement elementWithName:@"test"]];
	XCTAssertEqualObjects([d XMLString], @"<test></test>");	// body is printed even if no <?xml> header
	XCTAssertEqualObjects([d XMLStringWithOptions:0], @"<test></test>");	// try different formatting options
	/* summary: <?xml...> comes if either version, encoding or standalone is set
	   version defaults to "1.0", encoding may be omitted, standalone is always present
	   rootElement is generated even if there is no <?xml?> header
	   DTD is not yet tested, but likely that it is also generated
	   are there other contents of <?xml?>
	 */
}

- (void) test44
{ // manual init - find out when and which xml header is printed
	NSXMLDocument *d=[[[NSXMLDocument alloc] init] autorelease];
	/*
	 NSXMLNodeIsCDATA												= (1 << 0),
	 NSXMLDocumentTidyHTML											= (1 << 9),
	 NSXMLDocumentTidyXML											= (1 << 10),
	 NSXMLDocumentValidate											= (1 << 13),
	 NSXMLDocumentXInclude											= (1 << 16),
	 NSXMLNodePrettyPrint											= (1 << 17),
	 NSXMLDocumentIncludeContentTypeDeclaration						= (1 << 18),
	 NSXMLNodePreserveNamespaceOrder									= (1 << 20),
	 NSXMLNodePreserveAttributeOrder									= (1 << 21),
	 NSXMLNodePreserveEntities										= (1 << 22),
	 NSXMLNodePreservePrefixes										= (1 << 23),
	 NSXMLNodePreserveCDATA											= (1 << 24),
	 NSXMLNodePreserveWhitespace										= (1 << 25),
	 NSXMLNodePreserveDTD											= (1 << 26),
	 NSXMLNodePreserveCharacterReferences							= (1 << 27),
	 NSXMLNodePreserveEmptyElements									=	(NSXMLNodeExpandEmptyElement | NSXMLNodeCompactEmptyElement),
	 NSXMLNodePreserveQuotes											=	(NSXMLNodeUseSingleQuotes | NSXMLNodeUseDoubleQuotes),
	 NSXMLNodePreserveAll	= ( NSXMLNodePreserveNamespaceOrder |
	 */

	[d setRootElement:[NSXMLElement elementWithName:@"test"]];
	XCTAssertEqualObjects([d XMLString], @"<test></test>");	// body is printed without <?xml> header
	XCTAssertEqualObjects([d XMLStringWithOptions:0], @"<test></test>");	// try different formatting options
	XCTAssertEqualObjects([d XMLStringWithOptions:NSXMLNodeExpandEmptyElement], @"<test></test>");	// is the default
	XCTAssertEqualObjects([d XMLStringWithOptions:NSXMLNodeCompactEmptyElement], @"<test/>");
	[[d rootElement] addAttribute:[NSXMLElement attributeWithName:@"attrib" stringValue:@"value"]];
	XCTAssertEqualObjects([d XMLString], @"<test attrib=\"value\"></test>");
	XCTAssertEqualObjects([d XMLStringWithOptions:NSXMLNodeUseSingleQuotes], @"<test attrib=\'value\'></test>");
	XCTAssertEqualObjects([d XMLStringWithOptions:NSXMLNodeUseDoubleQuotes], @"<test attrib=\"value\"></test>");	// is the default
	XCTAssertEqualObjects([d XMLStringWithOptions:NSXMLNodePrettyPrint], @"\n<test attrib=\"value\"></test>");
}

/* other tests
 * demonstrate if NSXMLElement can (not) be initialized to different kind
 * demonstrate how attributeWithName is initialized and what happens if it is called for NSXMLElement?
 * demonstrate what the options for initWithKind:options: do and how they relate to XMLStringWithOptions
 */

- (void) parser:(NSXMLParser *) parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data;
{
	[result setObject:target forKey:@"target"];
	[result setObject:data forKey:@"data"];
}

-(void) test200
{ // should go into a separate NSXMLParserTest
	NSXMLParser *p=[[[NSXMLParser alloc] initWithData:[@"<?xml something ?>" dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
	[p setDelegate:self];
	[p parse];
#if 0	// <?xml should not call foundProcessingInstructionWithTarget because it is not a procesing instruction - see https://en.wikipedia.org/wiki/Processing_Instruction
	XCTAssertEqualObjects([result objectForKey:@"target"], @"xml");
	XCTAssertEqualObjects([result objectForKey:@"data"], @"echo '");
#endif
	p=[[[NSXMLParser alloc] initWithData:[@"<?php echo '?>'; ?>" dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
	[p setDelegate:self];
	[p parse];
#if 0	// Cocoa ends at the first ?> because processing instructions may not contain ?> - see https://en.wikipedia.org/wiki/Processing_Instruction
	XCTAssertEqualObjects([result objectForKey:@"target"], @"php");
	XCTAssertEqualObjects([result objectForKey:@"data"], @"echo '");
#endif
	p=[[[NSXMLParser alloc] initWithData:[@"<?php    echo 'hello';   ?>" dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
	[p setDelegate:self];
	[p parse];
	XCTAssertEqualObjects([result objectForKey:@"target"], @"php");
	XCTAssertEqualObjects([result objectForKey:@"data"], @"echo 'hello';   ");
}

@end
