/* 
   NSTokenField.m

   Text field control and cell classes

   Author:  Nikolaus Schaller <hns@computer.org>
   Date:    December 2004
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>

#import <AppKit/NSTokenField.h>
#import <AppKit/NSTokenFieldCell.h>
#import <AppKit/NSTokenFieldCell.h>
#import <AppKit/NSTextAttachment.h>

@interface NSTokenAttachment : NSTextAttachment

@end

@implementation NSTokenAttachment

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	if((self=[super initWithCoder:coder]))
			{
				// NS.delegate
			}
	return self;
}

@end

@interface NSTokenAttachmentCell : NSTextAttachmentCell <NSCoding>
{
}
@end

@implementation NSTokenAttachmentCell

- (void) dealloc;
{
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	if((self=[super initWithCoder:coder]))
		{
//	_fileWrapper=[[coder decodeObjectForKey:@"NSFileWrapper"] retain];
//	_cell=[[coder decodeObjectForKey:@"NSCell"] retain];
//	NSRepresentedObject
		}
	return self;
}

- (NSSize) cellSize; { return NSMakeSize(50.0, 20.0); }

@end

@implementation NSTokenFieldCell

+ (NSTimeInterval) defaultCompletionDelay; { return 0; }
+ (NSCharacterSet *) defaultTokenizingCharacterSet; { return [NSCharacterSet characterSetWithCharactersInString:@","]; }

- (NSTimeInterval) completionDelay; { return _completionDelay; }
- (id) delegate; { return _delegate; }
- (void) setCompletionDelay:(NSTimeInterval) delay; { _completionDelay=delay; }
- (void) setDelegate:(id) obj; { ASSIGN(_delegate, obj); }
- (void) setTokenizingCharacterSet:(NSCharacterSet *) set; { ASSIGN(_tokenizingCharacterSet, set); }
- (void) setTokenStyle:(NSTokenStyle) style; { _tokenStyle=style; }
- (NSCharacterSet *) tokenizingCharacterSet; { return _tokenizingCharacterSet; }
- (NSTokenStyle) tokenStyle; { return _tokenStyle; }

- (id) initTextCell:(NSString *) str;
{
	if((self=[super initTextCell:str]))
		{
		_completionDelay=[[self class] defaultCompletionDelay];
		_tokenizingCharacterSet=[[[self class] defaultTokenizingCharacterSet] retain];
		}
	return self;
}

- (void) dealloc;
{
	[_delegate release];
	[_tokenizingCharacterSet release];
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	if((self=[super initWithCoder:coder]))
		{
#if 0
		NSLog(@"%@ initWithCoder:%@", self, coder);
#endif
		_delegate=[[coder decodeObjectForKey:@"NSDelegate"] retain];
		_tokenizingCharacterSet=[[coder decodeObjectForKey:@"NSTokenizingCharacterSet"] retain];
		_completionDelay=[coder decodeDoubleForKey:@"NSCompletionDelay"];
		_tokenStyle=[coder decodeIntForKey:@"NSTokenStyle"];
			// NS.representedObjects
#if 0
		NSLog(@"%@ initWithCoder done:%@", self, coder);
#endif
		}
	return self;
}

@end /* NSTokenFieldCell */

@implementation NSTokenField

- (id) initWithCoder:(NSCoder *) coder;
{
	if((self=[super initWithCoder:coder]))
			{
#if 0
				NSLog(@"%@ initWithCoder:%@", self, coder);
#endif
				// NSTokenFieldVersion
#if 0
				NSLog(@"%@ initWithCoder done:%@", self, coder);
#endif
			}
	return self;
}

@end /* NSTokenField */
