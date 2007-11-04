//
//  IOBluetoothSDPServiceRecord.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef id BluetoothSDPServiceRecordHandle;

@interface IOBluetoothSDPServiceRecord : NSObject {

}

@end

typedef IOBluetoothSDPServiceRecord *IOBluetoothSDPServiceRecordRef;

BOOL IOBluetoothAddServiceDict(NSDictionary *sdpEntries, id serviceRecordRef);
BOOL IOBluetoothObjectRelease(id serviceRecordRef);
BOOL IOBluetoothRemoveServiceWithRecordHandle(id mServerHandle);
