/*
    NSSpellServer.h
    mySTEP
  
    Created by Dr. H. Nikolaus Schaller on Wed Dec 28 2005.
    Copyright (c) 2005 DSITRI.
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5

    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@interface NSSpellServer : NSObject
{
	id	_delegate;
}

- (id) delegate;
- (BOOL) isWordInUserDictionaries:(NSString *) word caseSensitive:(BOOL) flag;
- (BOOL) registerLanguage:(NSString *) language byVendor:(NSString *) vendor;
- (void) run;
- (void) setDelegate:(id) delegate;

@end

@interface NSObject (NSSpellServerDelegate)

- (NSRange) spellServer:(NSSpellServer *) sender 
   checkGrammarInString:(NSString *) string 
			   language:(NSString *) language 
				details:(NSArray **) details;
- (void) spellServer:(NSSpellServer *) sender 
	   didForgetWord:(NSString *) word 
		  inLanguage:(NSString *) language;
- (void) spellServer:(NSSpellServer *) sender 
		didLearnWord:(NSString *) word 
		  inLanguage:(NSString *) language;
- (NSRange) spellServer:(NSSpellServer *) sender findMisspelledWordInString:(NSString *) stringToCheck
			   language:(NSString *) language
			  wordCount:(int *) wordCount
			  countOnly:(BOOL) countOnly;
- (NSArray *) spellServer:(NSSpellServer *) sender suggestCompletionsForPartialWordRange:(NSRange) range
				 inString:(NSString *) string
				 language:(NSString *) language;
- (NSArray *) spellServer:(NSSpellServer *) sender 
	suggestGuessesForWord:(NSString *) word 
			   inLanguage:(NSString *) language;

@end

extern NSString *NSGrammarRange;
extern NSString *NSGrammarUserDescription;
extern NSString *NSGrammarCorrections;
