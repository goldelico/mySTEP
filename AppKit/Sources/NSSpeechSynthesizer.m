/* 
   NSSpeechSynthesizer.m
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
  
*/ 

#import <AppKit/NSSpeechSynthesizer.h>
#import <Foundation/Foundation.h>
#import "NSAppKitPrivate.h"
#import "NSSystemServer.h"

NSString *NSVoiceIdentifier=@"Identifier";
NSString *NSVoiceName=@"Name";
NSString *NSVoiceAge=@"Age";
NSString *NSVoiceGender=@"Gender";
NSString *NSVoiceDemoText=@"DemoText";
NSString *NSVoiceLanguage=@"Language";

NSString *NSVoiceGenderNeuter=@"GenderNeuter";
NSString *NSVoiceGenderMale=@"GenderMale";
NSString *NSVoiceGenderFemale=@"GenderFemale";

@implementation NSSpeechSynthesizer

+ (NSDictionary *) attributesForVoice:(NSString *) voice; { return nil; }
+ (NSArray *) availableVoices; { return [NSArray arrayWithObject:[self defaultVoice]]; }
+ (NSString *) defaultVoice; { return @"default"; }
+ (BOOL) isAnyApplicationSpeaking; { return NO; }

- (id) delegate; { return _delegate; }

- (id) initWithVoice:(NSString *) voice;
{
	if((self=[super init]))
		{
			_voice=[voice retain];
		}
	return nil;
}

- (void) dealloc
{
	[_voice release];
	[self stopSpeaking];
	[_task release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) z; { return [[NSSpeechSynthesizer alloc] initWithVoice:_voice]; }

- (BOOL) isSpeaking; { return _task != nil; }
- (void) setDelegate:(id) delegate; { _delegate=delegate; }
- (void) setUsesFeedbackWindow:(BOOL) flag; { _usesFeedbackWindow=flag; }
- (BOOL) setVoice:(NSString *) voice; { ASSIGN(_voice, voice); return YES; }

- (BOOL) startSpeakingString:(NSString *) text;
{
	return [self startSpeakingString:text toURL:nil];
}

/*
 * needs:  apt-get install festival festvox-kallpc16k
 */

- (BOOL) startSpeakingString:(NSString *) text toURL:(NSURL *) url;
{
	// should be implemented by a NSTask
	// if url is defined and a file-url call text2wav
	// pass voice
	FILE *f=popen("festival --tts", "w");	// start subprocess
	if(!f)
		/* needs apt-get install flite */
		f=popen("flite -f -", "w");	// -voice 'name'
	if(!f)
		return NO;	// none installed
	fputs([text UTF8String], f);
	pclose(f);
	// split into words and phonemes
	// append to queue and start a new NSTask if needed
	// and call appropriate delegate methods
	[_delegate speechSynthesizer:self didFinishSpeaking:YES];
	return YES;
}

- (void) stopSpeaking; { [_task terminate]; }
- (BOOL) usesFeedbackWindow; { return _usesFeedbackWindow; }
- (NSString *) voice; { return _voice; }

- (void) encodeWithCoder:(NSCoder *)aCoder				// NSCoding protocol
{
//	[super encodeWithCoder:aCoder];
	if([aCoder allowsKeyedCoding])
		{
		}
	else
		{
		}
	NIMP;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if([aDecoder allowsKeyedCoding])
		{
		}
	else
		{
		}
	return NIMP;
}

@end
