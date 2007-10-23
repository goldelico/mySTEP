/*
  NSAlert.h
  mySTEP

  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
  Copyright (c) 2005 DSITRI. 

  Author:	Fabian Spillner
  Date:		16. October 2007  
 
  This file is part of the mySTEP Library and is provided
  under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSAlert
#define _mySTEP_H_NSAlert

#import <Foundation/Foundation.h>
#import <AppKit/NSImage.h>

typedef enum _NSAlertStyle
{
	NSWarningAlertStyle,
	NSInformationalAlertStyle,
	NSCriticalAlertStyle
} NSAlertStyle;

enum
{
	NSAlertFirstButtonReturn,
	NSAlertSecondButtonReturn,
	NSAlertThirdButtonReturn
};

@interface NSAlert : NSObject
{
	NSAlertStyle _alertStyle;
	NSArray *_buttons;
	id _delegate;
	NSString *_helpAnchor;
	NSImage *_icon;
	NSString *_informativeText;
	NSString *_messageText;
	id _window;
	BOOL _showsHelp;
}

+ (NSAlert *) alertWithError:(NSError *) err;
+ (NSAlert *) alertWithMessageText:(NSString *) message defaultButton:(NSString *) defaultTitle alternateButton:(NSString *) altTitle otherButton:(NSString *) otherTitle informativeTextWithFormat:(NSString *) textWithFormat, ...;

- (NSButton *) addButtonWithTitle:(NSString *) title;
- (NSAlertStyle) alertStyle;
- (void) beginSheetModalForWindow:(NSWindow *) window modalDelegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
- (void) alertDidEnd:(NSAlert *) alert returnCode:(int) ret contextInfo:(void *) context;
- (NSArray *) buttons;
- (id) delegate;
- (NSString *) helpAnchor;
- (NSImage *) icon;
- (NSString *) informativeText;
- (NSString *) messageText;
- (int) runModal;
- (void) setAlertStyle:(NSAlertStyle) alertStyle;
- (void) setDelegate:(id) delegate;
- (void) setHelpAnchor:(NSString *) helpAnchor;
- (void) setIcon:(NSImage *) icon;
- (void) setInformativeText:(NSString *) text;
- (void) setMessageText:(NSString *) message;
- (void) setShowsHelp:(BOOL) flag;
- (BOOL) showsHelp;
- (id) window;

@end

@interface NSObject (NSAlertDelegate)
- (BOOL) alertShowHelp:(NSAlert *) anAlert;
@end

#endif /* _mySTEP_H_NSAlert */
