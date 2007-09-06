/* 
   NSSpeechSynthesizer.h
 
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

extern NSString *NSVoiceIdentifier;
extern NSString *NSVoiceName;
extern NSString *NSVoiceAge;
extern NSString *NSVoiceGender;
extern NSString *NSVoiceDemoText;
extern NSString *NSVoiceLanguage;

extern NSString *NSVoiceGenderNeuter;
extern NSString *NSVoiceGenderMale;
extern NSString *NSVoiceGenderFemale;

@interface NSSpeechSynthesizer : NSObject  <NSCoding>
{
	NSDistantObject *_server;
	id _delegate;
}

+ (NSDictionary *) attributesForVoice:(NSString *) voice;
+ (NSArray *) availableVoices;
+ (NSString *) defaultVoice;
+ (BOOL) isAnyApplicationSpeaking;

- (id) delegate;
- (id) initWithVoice:(NSString *) voice;
- (BOOL) isSpeaking;
- (void) setDelegate:(id) delegate;
- (void) setUsesFeedbackWindow:(BOOL) flag;
- (BOOL) setVoice:(NSString *) voice;
- (BOOL) startSpeakingString:(NSString *) text;
- (BOOL) startSpeakingString:(NSString *) text toURL:(NSURL *) url;
- (void) stopSpeaking;
- (BOOL) usesFeedbackWindow;
- (NSString *) voice;

@end


@interface NSObject (NSSpeechSynthesizerDelegate)
- (void) speechSynthesizer:(NSSpeechSynthesizer *) sender didFinishSpeaking:(BOOL) flag;
- (void) speechSynthesizer:(NSSpeechSynthesizer *) sender willSpeakPhoneme:(short) code;
- (void) speechSynthesizer:(NSSpeechSynthesizer *) sender willSpeakWord:(NSRange) word ofString:(NSString *) text;
@end

#endif /* _mySTEP_H_NSSpeechSynthesizer */
