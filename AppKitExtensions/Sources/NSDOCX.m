//
//  NSXIBLoading.m
//  AppKitExtensions
//
//  Created by H. Nikolaus Schaller on 09.03.21.
//
//

#import "NSXIBLoading.h"

NSString *NSDocumentTypeDocumentAttribute=@"DocumentType";
NSString *NSOfficeOpenXMLTextDocumentType=@".docx";	// ECMA Office Open XML text document format
													// denkbar wäre auch .odt (Apple TextEdit kann alle diese Formate im Save... Dialog)

@implementation NSAttributedString (DOCX)

- (id) initWithDocFormat:(NSData *) data documentAttributes:(NSDictionary **) dict;
{
	// for a quick description (not the standard) see: https://www.toptal.com/xml/an-informal-introduction-to-docx
	return nil;
}

- (NSData *) dataFromRange:(NSRange) range documentAttributes:(NSDictionary *) dict error:(NSError **) error;
{
	return nil;
}

@end
