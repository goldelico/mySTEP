//
//  IOBluetoothPairingController.m
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <IOBluetoothUI/IOBluetoothUI.h>


@implementation IOBluetoothPairingController

+ (IOBluetoothPairingController *) pairingController;
{
	return [[self new] autorelease];
}

+ (IOBluetoothPairingController *) withPairingControllerRef:(IOBluetoothPairingControllerRef) pairingControllerRef;
{

}

- (void) addAllowedUUID:(IOBluetoothSDPUUID *) allowedUUID;
{

}

- (void) addAllowedUUIDArray:(NSArray *) allowedUUIDArray;
{

}

- (IOReturn) beginSheetModalForWindow:(NSWindow *) sheet
						modalDelegate:(id) delegate
					   didEndSelector:(SEL) selector
						  contextInfo:(void *) context;
{

}

- (void) clearAllowedUUIDs;
{

}

- (NSString *) getDescriptionText;
{

}

- (IOBluetoothServiceBrowserControllerOptions) getOptions; { return _options; }

- (IOBluetoothPairingControllerRef) getPairingControllerRef;
{

}

- (NSString *) getPrompt;
{

}

- (NSArray *) getResults;
{

}

- (const IOBluetoothDeviceSearchAttributes *) getSearchAttributes; { return _searchAttributes; }

- (NSString *) getTitle;
{

}

- (int) runModal;
{

}

- (void) runPanelWithAttributes:(IOBluetoothDeviceSearchAttributes *) attributes;
{

}

- (void) setDescriptionText:(NSString *) descriptionText;
{

}

- (void) setOptions:(IOBluetoothServiceBrowserControllerOptions) options; { _options=options; }

- (void) setPrompt:(NSString *) prompt;
{

}

- (void) setSearchAttributes:(const IOBluetoothDeviceSearchAttributes *) searchAttributes;
{
	if(searchAttributes != _searchAttributes)
		{
		[_searchAttributes release];
		_searchAttributes=[searchAttributes retain];
		}
}

- (void) setTitle:(NSString *) windowTitle;
{

}

@end
