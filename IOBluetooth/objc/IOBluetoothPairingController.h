//
//  IOBluetoothPairingController.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetoothUI/IOBluetoothUIUserLib.h>

@class IOBluetoothPairingController;
typedef IOBluetoothPairingController *IOBluetoothPairingControllerRef;

typedef NSObject IOBluetoothDeviceSearchAttributes;

@interface IOBluetoothPairingController : NSWindowController
{
	IBOutlet NSTextField *_description;
	IBOutlet NSTextField *_prompt;
	IBOutlet NSTextField *_title;
	IOBluetoothServiceBrowserControllerOptions _options;
	const IOBluetoothDeviceSearchAttributes *_searchAttributes;
}

+ (IOBluetoothPairingController *) pairingController;
+ (IOBluetoothPairingController *) withPairingControllerRef:(IOBluetoothPairingControllerRef) pairingControllerRef;

- (void) addAllowedUUID:(IOBluetoothSDPUUID *) allowedUUID;
- (void) addAllowedUUIDArray:(NSArray *) allowedUUIDArray;
- (IOReturn) beginSheetModalForWindow:(NSWindow *) sheet
						modalDelegate:(id) delegate
					   didEndSelector:(SEL) selector
						  contextInfo:(void *) context;
- (void) clearAllowedUUIDs;
- (NSString *) getDescriptionText;
- (IOBluetoothServiceBrowserControllerOptions) getOptions;
- (IOBluetoothPairingControllerRef) getPairingControllerRef;
- (NSString *) getPrompt;
- (NSArray *) getResults;
- (const IOBluetoothDeviceSearchAttributes *) getSearchAttributes;
- (NSString *) getTitle;
- (int) runModal;
- (void) runPanelWithAttributes:(IOBluetoothDeviceSearchAttributes *) attributes;
- (void) setDescriptionText:(NSString *) descriptionText;
- (void) setOptions:(IOBluetoothServiceBrowserControllerOptions) options;
- (void) setPrompt:(NSString *) prompt;
- (void) setSearchAttributes:(const IOBluetoothDeviceSearchAttributes *) searchAttributes;
- (void) setTitle:(NSString *) windowTitle;

@end
