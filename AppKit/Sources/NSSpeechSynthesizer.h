/* 
   NSSpeechSynthesizer.h
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	05. December 2007 - aligned with 10.5   
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSSpeechSynthesizer
#define _mySTEP_H_NSSpeechSynthesizer

#import <Foundation/NSBundle.h>
#import <Foundation/NSRange.h>
#import <AppKit/AppKitDefines.h>

@class NSString;
@class NSArray;
@class NSDictionary;
@class NSDistantObject;
@class NSURL;

enum {
	NSSpeechImmediateBoundary =  0,
	NSSpeechWordBoundary,
	NSSpeechSentenceBoundary
};
typedef NSUInteger NSSpeechBoundary;

@interface NSSpeechSynthesizer : NSObject  <NSCoding>
{
	NSDistantObject *_server;
	id _delegate;
}

+ (NSDictionary *) attributesForVoice:(NSString *) voice;
+ (NSArray *) availableVoices;
+ (NSString *) defaultVoice;
+ (BOOL) isAnyApplicationSpeaking;

- (void) addSpeechDictionary:(NSDictionary *) speechDict;
- (void) continueSpeaking; 
- (id) delegate;
- (id) initWithVoice:(NSString *) voice;
- (BOOL) isSpeaking;
- (id) objectForProperty:(NSString *) property error:(NSError **) error; 
- (void) pauseSpeakingAtBoundary:(NSSpeechBoundary) speechBoundary; 
- (NSString *) phonemesFromText:(NSString *) text; 
- (float) rate; 
- (void) setDelegate:(id) delegate;
- (BOOL) setObject:(id) obj forProperty:(NSString *) property error:(NSError **) error; 
- (void) setRate:(float) val; 
- (void) setUsesFeedbackWindow:(BOOL) flag;
- (BOOL) setVoice:(NSString *) voice;
- (void) setVolume:(float) vol; 
- (BOOL) startSpeakingString:(NSString *) text;
- (BOOL) startSpeakingString:(NSString *) text toURL:(NSURL *) url;
- (void) stopSpeaking;
- (void) stopSpeakingAtBoundary:(NSSpeechBoundary) speechBoundary; 
- (BOOL) usesFeedbackWindow;
- (NSString *) voice;
- (float) volume;

@end


@interface NSObject (NSSpeechSynthesizerDelegate)
- (void) speechSynthesizer:(NSSpeechSynthesizer *) sender didEncounterErrorAtIndex:(NSUInteger) idx ofString:(NSString *) text message:(NSString *) error;
- (void) speechSynthesizer:(NSSpeechSynthesizer *) sender didEncounterSyncMessage:(NSString *) error;
- (void) speechSynthesizer:(NSSpeechSynthesizer *) sender didFinishSpeaking:(BOOL) flag;
- (void) speechSynthesizer:(NSSpeechSynthesizer *) sender willSpeakPhoneme:(short) code;
- (void) speechSynthesizer:(NSSpeechSynthesizer *) sender willSpeakWord:(NSRange) word ofString:(NSString *) text;

@end

extern NSString *NSVoiceIdentifier;
extern NSString *NSVoiceName;
extern NSString *NSVoiceAge;
extern NSString *NSVoiceGender;
extern NSString *NSVoiceDemoText;
extern NSString *NSVoiceLanguage;
extern NSString *NSVoiceLocaleIdentifier;
extern NSString *NSVoiceSupportedCharacters;
extern NSString *NSVoiceIndividuallySpokenCharacters;

extern NSString *NSVoiceGenderNeuter;
extern NSString *NSVoiceGenderMale;
extern NSString *NSVoiceGenderFemale;

extern NSString *NSSpeechStatusProperty;
extern NSString *NSSpeechErrorsProperty;
extern NSString *NSSpeechInputModeProperty;
extern NSString *NSSpeechCharacterModeProperty;
extern NSString *NSSpeechNumberModeProperty;
extern NSString *NSSpeechNumberModeProperty;
extern NSString *NSSpeechRateProperty;
extern NSString *NSSpeechPitchBaseProperty;
extern NSString *NSSpeechPitchModProperty;
extern NSString *NSSpeechVolumeProperty;
extern NSString *NSSpeechSynthesizerInfoProperty;
extern NSString *NSSpeechRecentSyncProperty;
extern NSString *NSSpeechPhonemeSymbolsProperty;
extern NSString *NSSpeechCurrentVoiceProperty;
extern NSString *NSSpeechCommandDelimiterProperty;
extern NSString *NSSpeechResetProperty;
extern NSString *NSSpeechOutputToFileURLProperty;

extern NSString *NSSpeechModeText;
extern NSString *NSSpeechModePhoneme;

extern NSString *NSSpeechModeNormal;
extern NSString *NSSpeechModeLiteral;

extern NSString *NSSpeechStatusOutputBusy;
extern NSString *NSSpeechStatusOutputPaused;
extern NSString *NSSpeechStatusNumberOfCharactersLeft;
extern NSString *NSSpeechStatusPhonemeCode;

extern NSString *NSSpeechErrorCount;
extern NSString *NSSpeechErrorOldestCode;
extern NSString *NSSpeechErrorOldestCharacterOffset;
extern NSString *NSSpeechErrorNewestCode;
extern NSString *NSSpeechErrorNewestCharacterOffset;

extern NSString *NSSpeechSynthesizerInfoIdentifier;
extern NSString *NSSpeechSynthesizerInfoVersion;

extern NSString *NSSpeechCommandPrefix;
extern NSString *NSSpeechCommandSuffix; 

extern NSString *NSSpeechDictionaryLanguage;
extern NSString *NSSpeechDictionaryModificationDate;
extern NSString *NSSpeechDictionaryPronunciations;
extern NSString *NSSpeechDictionaryAbreviations;
extern NSString *NSSpeechDictionaryEntrySpelling;
extern NSString *NSSpeechDictionaryEntryPhonemes;


#endif /* _mySTEP_H_NSSpeechSynthesizer */
