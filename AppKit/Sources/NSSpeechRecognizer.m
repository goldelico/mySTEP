/* 
   NSSpeechRecognizer.m

   Interface to the global ASR module

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <AppKit/NSSpeechRecognizer.h>
#import <Foundation/Foundation.h>
#import "NSAppKitPrivate.h"
#import "NSSystemServer.h"

@implementation NSSpeechRecognizer

- (BOOL) blocksOtherRecognizers; { return NO; }
- (NSArray *) commands; { return nil; }
- (id) delegate; { return _delegate; }
- (NSString *) displayedCommandsTitle; { return nil; }

- (id) init;
{
	// should open connection to speech server
	return nil;
}

- (BOOL) listensInForegroundOnly; { return YES; }
- (void) setBlocksOtherRecognizers:(BOOL) flag; { }
- (void) setCommands:(NSArray *) commands; { NSLog(@"ASR commands: %@", commands); }
- (void) setDelegate:(id) delegate; { _delegate=delegate; }
- (void) setDisplayedCommandsTitle:(NSString *) title; { }
- (void) setListensInForegroundOnly:(BOOL) flag; { }
- (void) startListening; { NSLog(@"start listening"); }
- (void) stopListening; { NSLog(@"stop listening"); }

@end
