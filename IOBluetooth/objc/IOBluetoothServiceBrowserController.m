//
//  IOBluetoothServiceBrowserController.m
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <IOBluetoothUI/IOBluetoothUI.h>


@implementation IOBluetoothServiceBrowserController

+ (IOReturn) browseDevices:(IOBluetoothSDPServiceRecord **) result options:(IOBluetoothServiceBrowserControllerOptions) options;
{

}

+ (IOReturn) browseDevicesAsSheetForWindow:(NSWindow *) sheet options:(IOBluetoothServiceBrowserControllerOptions) options window:(NSWindow *) window;
{

}

+ (IOBluetoothServiceBrowserController *) withServiceBrowserControllerRef:(IOBluetoothServiceBrowserControllerRef) ref;
{

}

+ (IOBluetoothServiceBrowserController *) serviceBrowserController:(IOBluetoothServiceBrowserControllerOptions) options;
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

- (IOReturn) discover:(IOBluetoothSDPServiceRecord **) result;
{

}

- (IOReturn) discoverAsSheetForWindow:(NSWindow *) sheet
						   withRecord:(IOBluetoothSDPServiceRecord **) result;
{

}

- (IOReturn) discoverWithDeviceAttributes:(IOBluetoothDeviceSearchAttributes *) attribs
							  serviceList:(NSArray *) services
							serviceRecord:(IOBluetoothSDPServiceRecord **) result;
{

}

- (NSString *) getDescriptionText;
{

}

- (IOBluetoothServiceBrowserControllerOptions) getOptions; { return _options; }

- (IOBluetoothServiceBrowserControllerRef) getServiceBrowserControllerRef;
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

- (void) setDescriptionText:(NSString *) prompt;
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
