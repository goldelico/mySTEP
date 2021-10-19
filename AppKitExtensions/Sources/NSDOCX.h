//
//  NSDOCX.h
//  AppKitExtensions
//
//  Created by H. Nikolaus Schaller on 09.03.21.
//
//

#import <AppKit/AppKit.h>

NSString *NSDocumentTypeDocumentAttribute=@"DocumentType";
NSString *NSOfficeOpenXMLTextDocumentType;	// ECMA Office Open XML text document format.

@interface NSAttributedString (DOCX)

- (id) initWithDocFormat:(NSData *) data documentAttributes:(NSDictionary **) dict;
- (NSData *) dataFromRange:(NSRange) range documentAttributes:(NSDictionary *) dict error:(NSError **) error;

@end
