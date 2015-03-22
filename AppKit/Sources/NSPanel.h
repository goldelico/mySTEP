/* 
   NSPanel.h

   Panel window subclass

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	14. November 2007 - aligned with 10.5 
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPanel
#define _mySTEP_H_NSPanel

#import <AppKit/NSWindow.h>

@class NSString;

enum {
	NSOKButton	   = 1,
	NSCancelButton = 0
};

enum {
	NSAlertDefaultReturn   = 1,
	NSAlertAlternateReturn = 0,
	NSAlertOtherReturn	   = -1,
	NSAlertErrorReturn	   = -2
};	 

// extended style mask for NSPanel

enum {
    NSUtilityWindowMask			= 0x10,
    NSDocModalWindowMask 		= 0x40,
    NSNonactivatingPanelMask	= 0x80
};

@interface NSPanel : NSWindow  <NSCoding>
{
	BOOL _becomesKeyOnlyIfNeeded;
	BOOL _worksWhenModal;
}

- (BOOL) becomesKeyOnlyIfNeeded;
- (BOOL) isFloatingPanel;
- (void) setBecomesKeyOnlyIfNeeded:(BOOL) flag;
- (void) setFloatingPanel:(BOOL) flag;
- (void) setWorksWhenModal:(BOOL) flag;
- (BOOL) worksWhenModal;

@end

void NSBeginAlertSheet(NSString *title,
					   NSString *defaultButton,
					   NSString *altButton,
					   NSString *otherButton,
					   NSWindow *window,
					   id delegate,
					   SEL endSel,
					   SEL dismissSel,
					   void *context,
					   NSString *message, ...);

void NSBeginCriticalAlertSheet(NSString *title,
							   NSString *defaultButton,
							   NSString *altButton,
							   NSString *otherButton,
							   NSWindow *window,
							   id delegate,
							   SEL endSel,
							   SEL dismissSel,
							   void *context,
							   NSString *message, ...);

void NSBeginInformationalAlertSheet(NSString *title,
									NSString *defaultButton,
									NSString *altButton,
									NSString *otherButton,
									NSWindow *window,
									id delegate,
									SEL endSel,
									SEL dismissSel,
									void *context,
									NSString *msg, ...);

id NSGetAlertPanel(NSString *title,						// Create alert panel
                   NSString *msg,
                   NSString *defaultButton,
                   NSString *alternateButton, 
                   NSString *otherButton, ...);

id NSGetCriticalAlertPanel(NSString *title,						// Create alert panel
                   NSString *msg,
                   NSString *defaultButton,
                   NSString *alternateButton, 
                   NSString *otherButton, ...);

id NSGetInformationalAlertPanel(NSString *title,						// Create alert panel
								NSString *msg,
								NSString *defaultButton,
								NSString *alternateButton, 
								NSString *otherButton, ...);

NSInteger NSRunAlertPanel(NSString *title,					// Create and run an
                    NSString *msg,						// alert panel
                    NSString *defaultButton,
                    NSString *alternateButton,
                    NSString *otherButton, ...);

NSInteger NSRunCriticalAlertPanel(NSString *title,			// Create and run an
                    NSString *msg,						// critical alert panel
                    NSString *defaultButton,
                    NSString *alternateButton,
                    NSString *otherButton, ...);

NSInteger NSRunInformationalAlertPanel(NSString *title,		// Create and run an 
							NSString *msg,				// informational alert panel
							NSString *defaultButton,
							NSString *alternateButton,
							NSString *otherButton, ...);

void NSReleaseAlertPanel(id panel);						// Release alert panel

#endif /* _mySTEP_H_NSPanel */
