//
//  IOBluetoothObjectPushUIController.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetoothUI/IOBluetoothUIUserLib.h>

@interface IOBluetoothObjectPushUIController : NSWindowController
{
	IBOutlet NSImageView *_icon;
	IBOutlet NSTextField *_title;
}

- (IOReturn) beginSheetModalForWindow:(NSWindow *) sheet
						modalDelegate:(id) delegate
					   didEndSelector:(SEL) selector
						  contextInfo:(void *) context;
- (IOBluetoothDevice *) getDevice;
- (NSString *) getTitle;
- (IOBluetoothObjectPushUIController *) initObjectPushWithBluetoothDevice:(IOBluetoothDevice *) device
																withFiles:(NSArray *) files
																delegate:(id) delegate;
- (BOOL) isTransferInProgress;
- (void) runModal;
- (void) runPanel;
- (void) setIconImage:(NSImage *) iconImage;
- (void) setTitle:(NSString *) windowTitle;
- (void) stop;

@end
