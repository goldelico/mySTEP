//
//  IOBluetoothDeviceSelectorController.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetoothUI/IOBluetoothUIUserLib.h>

@class IOBluetoothDeviceSelectorController;
typedef IOBluetoothDeviceSelectorController *IOBluetoothDeviceSelectorControllerRef;

@interface IOBluetoothDeviceSelectorController : NSWindowController
{
	IBOutlet NSButton *_cancel;
	IBOutlet NSButton *_prompt;
	IBOutlet NSTextField *_description;
	IBOutlet NSTextField *_header;
	IBOutlet NSTextField *_title;
	IOBluetoothServiceBrowserControllerOptions _options;
	const IOBluetoothDeviceSearchAttributes *_searchAttributes;
}

+ (IOBluetoothDeviceSelectorController *) deviceSelector;
+ (IOBluetoothDeviceSelectorController *) withDeviceSelectorControllerRef:(IOBluetoothDeviceSelectorControllerRef) ref;

- (void) addAllowedUUID:(IOBluetoothSDPUUID *) allowedUUID;
- (void) addAllowedUUIDArray:(NSArray *) allowedUUIDArray;
- (IOReturn) beginSheetModalForWindow:(NSWindow *) sheet
						modalDelegate:(id) delegate
					   didEndSelector:(SEL) selector
						  contextInfo:(void *) context;
- (void) clearAllowedUUIDs;
- (IOBluetoothServiceBrowserControllerOptions) getOptions;
- (NSString *) getCancel;
- (NSString *) getDescriptionText;
- (IOBluetoothDeviceSelectorControllerRef) getDeviceSelectorControllerRef;
- (NSString *) getHeader;
- (NSString *) getPrompt;
- (NSArray *) getResults;
- (const IOBluetoothDeviceSearchAttributes *) getSearchAttributes;
- (NSString *) getTitle;
- (int) runModal;
- (void) setCancel:(NSString *) prompt;
- (void) setDescriptionText:(NSString *) prompt;
- (void) setHeader:(NSString *) prompt;
- (void) setOptions:(IOBluetoothServiceBrowserControllerOptions) options;
- (void) setPrompt:(NSString *) prompt;
- (void) setSearchAttributes:(const IOBluetoothDeviceSearchAttributes *) searchAttributes;
- (void) setTitle:(NSString *) windowTitle;

@end
