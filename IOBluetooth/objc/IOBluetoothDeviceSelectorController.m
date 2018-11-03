//
//  IOBluetoothDeviceSelectorController.m
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <IOBluetoothUI/IOBluetoothUI.h>


@implementation IOBluetoothDeviceSelectorController

+ (IOBluetoothDeviceSelectorController *) deviceSelector;
{
	return [[self new] autorelease];
}

+ (IOBluetoothDeviceSelectorController *) withDeviceSelectorControllerRef:(IOBluetoothDeviceSelectorControllerRef) ref;
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

- (IOBluetoothServiceBrowserControllerOptions) getOptions; { return _options; }

- (NSString *) getCancel;
{

}

- (NSString *) getDescriptionText;
{

}

- (IOBluetoothDeviceSelectorControllerRef) getDeviceSelectorControllerRef;
{

}

- (NSString *) getHeader;
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

- (void) setCancel:(NSString *) prompt;
{

}

- (void) setDescriptionText:(NSString *) prompt;
{

}

- (void) setHeader:(NSString *) prompt;
{

}

- (void) setOptions:(IOBluetoothServiceBrowserControllerOptions) options;
{
	_options=options;
}

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
