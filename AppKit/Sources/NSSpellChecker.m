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

+ (int) uniqueSpellDocumentTag
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
- (int)countWordsInString:(NSString *)aString
		 		 language:(NSString *)language
{
  return 0;
}

- (NSRange)checkSpellingOfString:(NSString *)stringToCheck
		      startingAt:(int)startingOffset
{
  NSRange r;

  return r;
}

- (NSRange)checkSpellingOfString:(NSString *)stringToCheck
		     		  startingAt:(int)startingOffset
					  language:(NSString *)language
		      		  wrap:(BOOL)wrapFlag
					  inSpellDocumentWithTag:(int)tag
		      		  wordCount:(int *)wordCount
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

- (void)closeSpellDocumentWithTag:(int)tag
{
}

- (void)ignoreWord:(NSString *)wordToIgnore
		inSpellDocumentWithTag:(int)tag
{
}

- (NSArray *)ignoredWordsInSpellDocumentWithTag:(int)tag
{
  return nil;
}

- (void)setIgnoredWords:(NSArray *)someWords
		inSpellDocumentWithTag:(int)tag
{
}

- (void)setWordFieldStringValue:(NSString *)aString
{
}

- (void)updateSpellingPanelWithMisspelledWord:(NSString *)word
{
}

@end
