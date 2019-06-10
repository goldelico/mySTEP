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
}

@end

@implementation NSXMLTest

- (void) setUp
{
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
	NSXMLNode *n=[doc rootElement];
	XCTAssertTrue([n rootDocument] == doc);

}

// test attributes
// test adding/deleting children

- (void) test100
{ // expansion into string
	NSString *wants=@"<?xml version=\"1.0\" encoding=\"UTF8\" standalone=\"yes\"?><SMARTPLUG id=\"letux\"><CMD id=\"get\"><Device.System.Power.State></Device.System.Power.State></CMD></SMARTPLUG>";
	XCTAssertEqualObjects([doc XMLString], wants);
	// try encoding with options
}

- (void) test101
{ // without <?xml>
	NSString *s=@"<SMARTPLUG id=\"letux\"><CMD id=\"get\"><Device.System.Power.State/></CMD></SMARTPLUG>";
	NSXMLDocument *d=[[[NSXMLDocument alloc] initWithXMLString:s options:0 error:NULL] autorelease];
	NSString *wants=@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><SMARTPLUG id=\"letux\"><CMD id=\"get\"><Device.System.Power.State></Device.System.Power.State></CMD></SMARTPLUG>";
	XCTAssertEqualObjects([d XMLString], wants);
}

- (void) test102
{ // manual init - find out when and which xml header is printed
	NSXMLDocument *d=[[[NSXMLDocument alloc] init] autorelease];
	XCTAssertTrue([d documentContentKind] == NSXMLDocumentXMLKind);	// 0
	XCTAssertNil([d version]);
	XCTAssertNil([d characterEncoding]);
	XCTAssertFalse([d isStandalone]);
	XCTAssertEqualObjects([d XMLString], @"");	// but not printed!
	[d setCharacterEncoding:@"UTF9"];	// unless we modify the object
	XCTAssertEqualObjects([d XMLString], @"<?xml version=\"1.0\" encoding=\"UTF9\" standalone=\"no\"?>");
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
	/* summary: <?xml...> comes if either version, encoding or standalone is set
	   version defaults to "1.0", encoding may be omitted, standalone is always present
	   rootElement is generated even if there is no <?xml?> header
	   DTD is not yet tested, but likely that it is also generated
	   are there other contents of <?xml?>
	 */
}

// try differnt formats

@end
