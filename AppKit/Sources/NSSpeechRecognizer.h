/* 
   NSSpeechRecognizer.h

   Interface to the global ASR module

   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	05. December 2007 - aligned with 10.5    
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSSpeechRecognizer
#define _mySTEP_H_NSSpeechRecognizer

#import <Foundation/NSBundle.h>
#import <AppKit/AppKitDefines.h>

@class NSString;
@class NSArray;
@class NSDistantObject;

@interface NSSpeechRecognizer : NSObject
{
	NSDistantObject *_recognizer;
	id _delegate;
}

- (BOOL) blocksOtherRecognizers;
- (NSArray *) commands;
- (id) delegate;
- (NSString *) displayedCommandsTitle;
- (id) init;
- (BOOL) listensInForegroundOnly;
- (void) setBlocksOtherRecognizers:(BOOL) flag;
- (void) setCommands:(NSArray *) commands;
- (void) setDelegate:(id) delegate;
- (void) setDisplayedCommandsTitle:(NSString *) title;
- (void) setListensInForegroundOnly:(BOOL) flag;
- (void) startListening;
- (void) stopListening;

@end

@interface NSObject (NSSpeechRecognizerDelegate)

- (void) speechRecognizer:(NSSpeechRecognizer *) sender didRecognizeCommand:(id) command;

@end

#endif /* _mySTEP_H_NSSpeechRecognizer */
