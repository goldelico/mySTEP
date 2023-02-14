/*
  NSAlert.h
  mySTEP

  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
  Copyright (c) 2005 DSITRI. 

  Author:	Fabian Spillner
  Date:		16. October 2007  

  Author:	Fabian Spillner <fabian.spillner@gmail.com>
  Date:		05. November 2007 - aligned with 10.5  
 
  This file is part of the mySTEP Library and is provided
  under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSAlert
#define _mySTEP_H_NSAlert

#import <Foundation/Foundation.h>

@class NSImage, NSTextField, NSImageView, NSButton, NSPanel;

enum
{
	NSWarningAlertStyle,
	NSInformationalAlertStyle,
	NSCriticalAlertStyle
};

typedef NSUInteger NSAlertStyle;

enum
{
	NSAlertFirstButtonReturn,
	NSAlertSecondButtonReturn,
	NSAlertThirdButtonReturn
};

typedef NSInteger NSModalResponse;

@interface NSAlert : NSObject
{
	IBOutlet NSTextField *_title;
	IBOutlet NSTextField *_msg;
	IBOutlet NSImageView *_icon;
	IBOutlet NSButton *_defaultButton;
	IBOutlet NSButton *_alternateButton;
	IBOutlet NSButton *_otherButton;
	IBOutlet NSPanel *_window;
	NSAlertStyle _alertStyle;
	id _delegate;
	NSString *_helpAnchor;
	NSString *_informativeText;
	BOOL _showsHelp;	
}

+ (NSAlert *) alertWithError:(NSError *) err;
+ (NSAlert *) alertWithMessageText:(NSString *) message 
					 defaultButton:(NSString *) defaultTitle 
				   alternateButton:(NSString *) altTitle 
					   otherButton:(NSString *) otherTitle 
		 informativeTextWithFormat:(NSString *) textWithFormat, ...;

- (NSView *) accessoryView;
- (NSButton *) addButtonWithTitle:(NSString *) title;
- (NSAlertStyle) alertStyle;
- (void) beginSheetModalForWindow:(NSWindow *) window modalDelegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
- (void) alertDidEnd:(NSAlert *) alert returnCode:(int) ret contextInfo:(void *) context;
- (NSArray *) buttons;
- (id) delegate;
- (NSString *) helpAnchor;
- (NSImage *) icon;
- (NSString *) informativeText;
- (void) layout;
- (NSString *) messageText;
- (NSModalResponse) runModal;
- (void) setAccessoryView:(NSView *) view;
- (void) setAlertStyle:(NSAlertStyle) alertStyle;
- (void) setDelegate:(id) delegate;
- (void) setHelpAnchor:(NSString *) helpAnchor;
- (void) setIcon:(NSImage *) icon;
- (void) setInformativeText:(NSString *) text;
- (void) setMessageText:(NSString *) message;
- (void) setShowsHelp:(BOOL) flag;
- (void) setShowsSuppressionButton:(BOOL) flag;
- (BOOL) showsHelp;
- (BOOL) showsSuppressionButton;
- (NSButton *) suppressionButton;
- (id) window;

@end

@interface NSObject (NSAlertDelegate)
- (BOOL) alertShowHelp:(NSAlert *) anAlert;
@end

#endif /* _mySTEP_H_NSAlert */
