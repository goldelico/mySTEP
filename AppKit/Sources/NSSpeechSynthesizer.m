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
+ (NSArray *) availableVoices; { return nil; }
+ (NSString *) defaultVoice; { return nil; }
+ (BOOL) isAnyApplicationSpeaking; { return NO; }

- (id) delegate; { return _delegate; }

- (id) initWithVoice:(NSString *) voice;
{
	// should open connection to speech server
	// speech server should link with flite library
	return nil;
}

- (id) copyWithZone:(NSZone *) z; { return [self retain]; }

- (BOOL) isSpeaking; { return NO; }
- (void) setDelegate:(id) delegate; { _delegate=delegate; }
- (void) setUsesFeedbackWindow:(BOOL) flag; { }
- (BOOL) setVoice:(NSString *) voice; { return NO; }

- (BOOL) startSpeakingString:(NSString *) text;
{
	NSLog(@"say: %@", text);
	return YES;
}

- (BOOL) startSpeakingString:(NSString *) text toURL:(NSURL *) url;
{
	NSLog(@"say: %@", text);
	return YES;
}

- (void) stopSpeaking; { }
- (BOOL) usesFeedbackWindow; { return NO; }
- (NSString *) voice; { return nil; }

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