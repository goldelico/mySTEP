/* 
   NSSpellChecker.h

   Class which is interface to spell-checking service

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date:    1996
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	12. December 2007 - aligned with 10.5   
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSSpellChecker
#define _mySTEP_H_NSSpellChecker

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSString;
@class NSArray;
@class NSDictionary;
@class NSView;
@class NSPanel;

@interface NSSpellChecker : NSObject
{
}

+ (NSSpellChecker *) sharedSpellChecker;
+ (BOOL) sharedSpellCheckerExists;
+ (NSInteger) uniqueSpellDocumentTag;

- (NSView *) accessoryView;
- (NSArray *) availableLanguages;
- (NSRange) checkGrammarOfString:(NSString *) str 
					  startingAt:(NSInteger) start 
						language:(NSString *) lang 
							wrap:(BOOL) flag 
		  inSpellDocumentWithTag:(NSInteger) tag 
						 details:(NSArray **) details;
- (NSRange) checkSpellingOfString:(NSString *) stringToCheck
					   startingAt:(NSInteger) startingOffset;
- (NSRange) checkSpellingOfString:(NSString *) stringToCheck
					   startingAt:(NSInteger) startingOffset
					     language:(NSString *) language
							 wrap:(BOOL) wrapFlag
		   inSpellDocumentWithTag:(NSInteger) tag
						wordCount:(NSInteger *) wordCount;
- (void) closeSpellDocumentWithTag:(NSInteger) tag;
- (NSArray *) completionsForPartialWordRange:(NSRange) wordRange 
									inString:(NSString *) str 
									language:(NSString *) lang 
					  inSpellDocumentWithTag:(NSInteger) tag;
- (NSInteger) countWordsInString:(NSString *) aString language:(NSString *) language;
- (NSArray *) guessesForWord:(NSString *) str;
- (BOOL) hasLearnedWord:(NSString *) str;
- (NSArray *) ignoredWordsInSpellDocumentWithTag:(NSInteger) tag;
- (void) ignoreWord:(NSString *) wordToIgnore inSpellDocumentWithTag:(NSInteger) tag;
- (NSString *) language;
- (void) setAccessoryView:(NSView *) aView;
- (void) setIgnoredWords:(NSArray *) someWords inSpellDocumentWithTag:(NSInteger) tag;
- (BOOL) setLanguage:(NSString *) aLanguage;
- (void) setWordFieldStringValue:(NSString *) aString;
- (NSPanel *) spellingPanel;
- (void) unlearnWord:(NSString *) str; 
- (void) updateSpellingPanelWithGrammarString:(NSString *) str 
									   detail:(NSDictionary *) dict;
- (void) updateSpellingPanelWithMisspelledWord:(NSString *) str;

@end

#endif /* _mySTEP_H_NSSpellChecker */
