/* 
   NSSpellChecker.m

   Description...

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <AppKit/NSSpellChecker.h>


@implementation NSSpellChecker

+ (NSSpellChecker *) sharedSpellChecker
{
	return nil;
}

+ (BOOL) sharedSpellCheckerExists
{
	return NO;
}

+ (NSInteger) uniqueSpellDocumentTag
{
  return 0;
}

- (NSView *) accessoryView
{
  return nil;
}

- (void) setAccessoryView:(NSView *)aView
{}

- (NSPanel *) spellingPanel
{
  return nil;
}

//
// Checking Spelling 
//
- (NSInteger)countWordsInString:(NSString *)aString
		 		 language:(NSString *)language
{
  return 0;
}

- (NSRange)checkSpellingOfString:(NSString *)stringToCheck
		      startingAt:(NSInteger)startingOffset
{
  NSRange r;

  return r;
}

- (NSRange)checkSpellingOfString:(NSString *)stringToCheck
		     		  startingAt:(NSInteger)startingOffset
					  language:(NSString *)language
		      		  wrap:(BOOL)wrapFlag
					  inSpellDocumentWithTag:(NSInteger)tag
		      		  wordCount:(NSInteger *)wordCount
{
NSRange r;

	return r;
}

- (NSString *)language						
{ 
	return nil; 
}

- (BOOL)setLanguage:(NSString *)aLanguage
{
  return NO;
}

- (void)closeSpellDocumentWithTag:(NSInteger)tag
{
}

- (void)ignoreWord:(NSString *)wordToIgnore
		inSpellDocumentWithTag:(NSInteger)tag
{
}

- (NSArray *)ignoredWordsInSpellDocumentWithTag:(NSInteger)tag
{
  return nil;
}

- (void)setIgnoredWords:(NSArray *)someWords
		inSpellDocumentWithTag:(NSInteger)tag
{
}

- (void)setWordFieldStringValue:(NSString *)aString
{
}

- (void)updateSpellingPanelWithMisspelledWord:(NSString *)word
{
}

@end
