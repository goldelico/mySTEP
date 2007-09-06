/* 
   NSSpellChecker.h

   Class which is interface to spell-checking service

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date:    1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSSpellChecker
#define _mySTEP_H_NSSpellChecker

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSString;
@class NSArray;
@class NSView;
@class NSPanel;

@interface NSSpellChecker : NSObject
{
}

+ (NSSpellChecker *) sharedSpellChecker;
+ (BOOL) sharedSpellCheckerExists;

- (NSView *) accessoryView;								// Manage Spell Panel
- (void) setAccessoryView:(NSView *)aView;
- (NSPanel *) spellingPanel;
														// Checking Spelling 
- (int) countWordsInString:(NSString *)aString language:(NSString *)language;
- (NSRange) checkSpellingOfString:(NSString *)stringToCheck
					   startingAt:(int)startingOffset;
- (NSRange) checkSpellingOfString:(NSString *)stringToCheck
					   startingAt:(int)startingOffset
					   language:(NSString *)language
					   wrap:(BOOL)wrapFlag
					   inSpellDocumentWithTag:(int)tag
					   wordCount:(int *)wordCount;

- (NSString *) language;								// Language 
- (BOOL) setLanguage:(NSString *)aLanguage;

+ (int) uniqueSpellDocumentTag;							// Manage Spell Check
- (void) closeSpellDocumentWithTag:(int)tag;
- (void) ignoreWord:(NSString *)wordToIgnore
		 inSpellDocumentWithTag:(int)tag;
- (NSArray *) ignoredWordsInSpellDocumentWithTag:(int)tag;
- (void) setIgnoredWords:(NSArray *)someWords
		 inSpellDocumentWithTag:(int)tag;
- (void) setWordFieldStringValue:(NSString *)aString;
- (void) updateSpellingPanelWithMisspelledWord:(NSString *)word;

@end

#endif /* _mySTEP_H_NSSpellChecker */
