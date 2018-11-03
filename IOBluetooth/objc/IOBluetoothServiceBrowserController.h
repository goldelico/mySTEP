//
//  IOBluetoothServiceBrowserController.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetoothUI/IOBluetoothUIUserLib.h>

@class IOBluetoothServiceBrowserController;
typedef IOBluetoothServiceBrowserController *IOBluetoothServiceBrowserControllerRef;

@interface IOBluetoothServiceBrowserController : NSWindowController
{
	IBOutlet NSTextField *_description;
	IBOutlet NSTextField *_prompt;
	IBOutlet NSTextField *_title;
	IOBluetoothServiceBrowserControllerOptions _options;
	const IOBluetoothDeviceSearchAttributes *_searchAttributes;
}

+ (IOReturn) browseDevices:(IOBluetoothSDPServiceRecord **) result options:(IOBluetoothServiceBrowserControllerOptions) options;
+ (IOReturn) browseDevicesAsSheetForWindow:(NSWindow *) sheet options: window:(NSWindow *) window;
+ (IOBluetoothServiceBrowserController *) withServiceBrowserControllerRef:(IOBluetoothServiceBrowserControllerRef) ref;
+ (IOBluetoothServiceBrowserController *) serviceBrowserController:(IOBluetoothServiceBrowserControllerOptions) options;

- (void) addAllowedUUID:(IOBluetoothSDPUUID *) allowedUUID;
- (void) addAllowedUUIDArray:(NSArray *) allowedUUIDArray;
- (IOReturn) beginSheetModalForWindow:(NSWindow *) sheet
						modalDelegate:(id) delegate
					   didEndSelector:(SEL) selector
						  contextInfo:(void *) context;
- (void) clearAllowedUUIDs;
- (IOReturn) discover:(IOBluetoothSDPServiceRecord **) result;
- (IOReturn) discoverAsSheetForWindow:(NSWindow *) sheet
						   withRecord:(IOBluetoothSDPServiceRecord **) result;
- (IOReturn) discoverWithDeviceAttributes:(IOBluetoothDeviceSearchAttributes *) attribs
							  serviceList:(NSArray *) services
							serviceRecord:(IOBluetoothSDPServiceRecord **) result;
- (NSString *) getDescriptionText;
- (IOBluetoothServiceBrowserControllerOptions) getOptions;
- (IOBluetoothServiceBrowserControllerRef) getServiceBrowserControllerRef;
- (NSString *) getPrompt;
- (NSArray *) getResults;
- (const IOBluetoothDeviceSearchAttributes *) getSearchAttributes;
- (NSString *) getTitle;
- (int) runModal;
- (void) setDescriptionText:(NSString *) prompt;
- (void) setOptions:(IOBluetoothServiceBrowserControllerOptions) options;
- (void) setPrompt:(NSString *) prompt;
- (void) setSearchAttributes:(const IOBluetoothDeviceSearchAttributes *) searchAttributes;
- (void) setTitle:(NSString *) windowTitle;

@end
