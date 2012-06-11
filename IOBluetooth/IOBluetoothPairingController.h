//
//  IOBluetoothPairingController.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>

typedef enum _IOBluetoothServiceBrowserControllerOptions { 
    kIOBluetoothServiceBrowserControllerOptionsNone = 0L,
    kIOBluetoothServiceBrowserControllerOptionsAutoStartInquiry = ( 1L << 0 ),
    kIOBluetoothServiceBrowserControllerOptionsDisconnectWhenDone = ( 1L << 1 ) 
} IOBluetoothServiceBrowserControllerOptions;

@class IOBluetoothPairingController;
typedef IOBluetoothPairingController *IOBluetoothPairingControllerRef;

typedef NSObject IOBluetoothDeviceSearchAttributes;

@interface IOBluetoothPairingController : NSWindowController
{
	IBOutlet NSTextField *description;
	IBOutlet NSTextField *prompt;
}

+ (IOBluetoothPairingController *) pairingController; 
+ (IOBluetoothPairingController *) withPairingControllerRef:(IOBluetoothPairingControllerRef) pairingControllerRef; 

- (void) addAllowedUUID:(IOBluetoothSDPUUID *) allowedUUID; 
- (void) addAllowedUUIDArray:(NSArray *) allowedUUIDArray; 
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
