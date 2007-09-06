//
//  NSPreferencePane.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <AppKit/AppKit.h>

typedef enum
{
	NSUnselectNow,
	NSUnselectLater,
	NSUnselectCancel
} NSPreferencePaneUnselectReply;

@interface NSPreferencePane : NSObject {
	NSBundle *_bundle;
	NSView *_mainView;
	IBOutlet NSView *_firstKeyView,
		*_initialKeyView,
		*_lastKeyView;
	IBOutlet NSWindow *_window;	// connect to the window
}

- (NSView *) assignMainView;
- (NSBundle *) bundle;
- (void) didSelect;
- (void) didUnselect;
- (NSView *) firstKeyView;
- (NSView *) initialKeyView;
- (id) initWithBundle:(NSBundle *) bundle;
- (NSView *) lastKeyView;
- (NSView *) loadMainView;
- (NSString *) mainNibName;
- (NSView *) mainView;
- (void) mainViewDidLoad;
- (void) replyToShouldUnselect:(BOOL) shouldUnselect;
- (void) setFirstKeyView:(NSView *) view;
- (void) setInitialKeyView:(NSView *) view;
- (void) setLastKeyView:(NSView *) view;
- (void) setMainView:(NSView *) view;
- (NSPreferencePaneUnselectReply) shouldUnselect;
- (void) willSelect;
- (void) willUnselect;

@end

// 	Notifications

extern NSString *NSPreferencePaneDoUnselectNotification;
extern NSString *NSPreferencePaneCancelUnselectNotification;
