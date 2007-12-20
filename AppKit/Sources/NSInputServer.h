/*
  NSInputServer.h
  mySTEP

  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
  Copyright (c) 2005 DSITRI.

  Author:	Fabian Spillner <fabian.spillner@gmail.com>
  Date:		9. November 2007 - aligned with 10.5 
 
  This file is part of the mySTEP Library and is provided
  under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSInputServer
#define _mySTEP_H_NSInputServer

#import "AppKit/NSController.h"

@class NSString;

@interface NSInputServer : NSObject
{
}

- (id) initWithDelegate:(id) delegate name:(NSString *) name; 

@end


@protocol NSInputServerMouseTracker

- (BOOL) mouseDownOnCharacterIndex:(NSUInteger) idx atCoordinate:(NSPoint) pt withModifier:(NSUInteger) modifiers client:(id) sender; 
- (BOOL) mouseDraggedOnCharacterIndex:(NSUInteger) idx atCoordinate:(NSPoint) pt withModifier:(NSUInteger) modifiers client:(id) sender; 
- (void) mouseUpOnCharacterIndex:(NSUInteger) idx atCoordinate:(NSPoint) pt withModifier:(NSUInteger) modifiers client:(id) sender; 

@end


@protocol NSInputServiceProvider

- (void) activeConversationChanged:(id) sender toNewConversation:(NSInteger) newConv; 
- (void) activeConversationWillChange:(id) sender fromOldConversation:(NSInteger) oldConv; 
- (BOOL) canBeDisabled; 
- (void) doCommandBySelector:(SEL) sel client:(id) sender; 
- (void) inputClientBecomeActive:(id) sender; 
- (void) inputClientDisabled:(id) sender; 
- (void) inputClientEnabled:(id) sender; 
- (void) inputClientResignActive:(id) sender; 
- (void) insertText:(id) str client:(id) sender; 
- (void) markedTextAbandoned:(id) sender; 
- (void) markedTextSelectionChanged:(NSRange) range client:(id) sender; 
- (void) terminate:(id) sender; 
- (BOOL) wantsToDelayTextChangeNotifications; 
- (BOOL) wantsToHandleMouseEvents; 
- (BOOL) wantsToInterpretAllKeystrokes; 

@end

#endif /* _mySTEP_H_NSInputServer */
